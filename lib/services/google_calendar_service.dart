import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/people/v1.dart' as people;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

const _storageKey = 'gcal_oauth_token';
const _selectedCalendarsKey = 'gcal_selected_calendars';
const _scopes = [
  calendar.CalendarApi.calendarReadonlyScope,
  people.PeopleServiceApi.contactsReadonlyScope,
  people.PeopleServiceApi.directoryReadonlyScope,
];

/// Manages OAuth lifecycle, secure token storage, and authenticated API access.
///
/// Dependencies are injected via the constructor for testability.
class GoogleCalendarService {
  final http.Client Function() httpClientFactory;
  final FlutterSecureStorage secureStorage;
  final auth.ClientId clientId;

  auth.AutoRefreshingAuthClient? _client;
  StreamSubscription<auth.AccessCredentials>? _credentialUpdatesSubscription;

  GoogleCalendarService({
    required this.httpClientFactory,
    required this.secureStorage,
    required this.clientId,
  });

  // -- Secure token storage (T026) --

  Future<void> _saveCredentials(auth.AccessCredentials credentials) async {
    final json = jsonEncode({
      'accessToken': {
        'type': credentials.accessToken.type,
        'data': credentials.accessToken.data,
        'expiry': credentials.accessToken.expiry.toIso8601String(),
      },
      'refreshToken': credentials.refreshToken,
      'scopes': credentials.scopes,
      'idToken': credentials.idToken,
    });
    await secureStorage.write(key: _storageKey, value: json);
  }

  Future<auth.AccessCredentials?> _loadSavedCredentials() async {
    final raw = await secureStorage.read(key: _storageKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final atMap = map['accessToken'] as Map<String, dynamic>;
      return auth.AccessCredentials(
        auth.AccessToken(
          atMap['type'] as String,
          atMap['data'] as String,
          DateTime.parse(atMap['expiry'] as String),
        ),
        map['refreshToken'] as String?,
        (map['scopes'] as List<dynamic>).cast<String>(),
        idToken: map['idToken'] as String?,
      );
    } catch (_) {
      // Corrupted data — clear and return null so user re-authenticates.
      await _clearCredentials();
      return null;
    }
  }

  Future<void> _clearCredentials() async {
    await secureStorage.delete(key: _storageKey);
  }

  // -- Client lifecycle --

  void _listenForCredentialUpdates(auth.AutoRefreshingAuthClient client) {
    _credentialUpdatesSubscription?.cancel();
    _credentialUpdatesSubscription = client.credentialUpdates.listen(
      (credentials) => _saveCredentials(credentials),
    );
  }

  auth.AutoRefreshingAuthClient _createAutoRefreshingClient(
    auth.AccessCredentials credentials,
    http.Client baseClient,
  ) {
    final client = auth.autoRefreshingClient(
      clientId,
      credentials,
      baseClient,
    );
    _client = client;
    _listenForCredentialUpdates(client);
    return client;
  }

  /// Returns the cached authenticated client, or attempts to restore from
  /// secure storage. Returns null if no saved credentials exist.
  Future<http.Client?> getAuthenticatedClient() async {
    if (_client != null) return _client;

    final credentials = await _loadSavedCredentials();
    if (credentials == null) return null;

    final baseClient = httpClientFactory();
    return _createAutoRefreshingClient(credentials, baseClient);
  }

  /// Opens browser for OAuth consent, obtains credentials, persists them,
  /// and returns the authenticated client.
  ///
  /// [promptUserForConsent] is called with the authorization URL — the caller
  /// should open it in a browser (e.g. via url_launcher).
  Future<http.Client?> signIn(
    void Function(String url) promptUserForConsent,
  ) async {
    if (_client != null) return _client;

    final baseClient = httpClientFactory();
    try {
      final credentials = await auth_io.obtainAccessCredentialsViaUserConsent(
        clientId,
        _scopes,
        baseClient,
        promptUserForConsent,
      );

      await _saveCredentials(credentials);
      return _createAutoRefreshingClient(credentials, baseClient);
    } catch (_) {
      baseClient.close();
      rethrow;
    }
  }

  /// Closes the HTTP client, cancels credential update subscription,
  /// and deletes saved credentials.
  Future<void> signOut() async {
    _credentialUpdatesSubscription?.cancel();
    _credentialUpdatesSubscription = null;
    _client?.close();
    _client = null;
    await _clearCredentials();
    await secureStorage.delete(key: _selectedCalendarsKey);
  }

  /// Closes any open HTTP clients. Call from widget dispose().
  void dispose() {
    _credentialUpdatesSubscription?.cancel();
    _credentialUpdatesSubscription = null;
    _client?.close();
    _client = null;
  }

  /// Fetches all calendars visible to the authenticated user.
  /// Returns entries sorted with primary first, then alphabetically.
  Future<List<calendar.CalendarListEntry>> fetchCalendarList(
    http.Client client,
  ) async {
    final calendarApi = calendar.CalendarApi(client);
    final list = await calendarApi.calendarList.list();
    final items = list.items ?? [];
    items.sort((a, b) {
      if (a.primary == true && b.primary != true) return -1;
      if (b.primary == true && a.primary != true) return 1;
      return (a.summaryOverride ?? a.summary ?? '')
          .compareTo(b.summaryOverride ?? b.summary ?? '');
    });
    return items;
  }

  /// Saves the set of selected calendar IDs to secure storage.
  Future<void> saveSelectedCalendars(List<String> calendarIds) async {
    await secureStorage.write(
      key: _selectedCalendarsKey,
      value: jsonEncode(calendarIds),
    );
  }

  /// Loads previously selected calendar IDs from secure storage.
  /// Returns null if nothing was saved (first run).
  Future<List<String>?> loadSelectedCalendars() async {
    final raw = await secureStorage.read(key: _selectedCalendarsKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return null;
    }
  }

  /// Fetches events from the given calendar ID for today and tomorrow.
  Future<List<calendar.Event>> fetchEvents(
    http.Client client, {
    String calendarId = 'primary',
  }) async {
    final calendarApi = calendar.CalendarApi(client);
    final now = DateTime.now();
    final endOfTomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
      23,
      59,
      59,
    );

    final startOfToday = DateTime(now.year, now.month, now.day);
    final events = await calendarApi.events.list(
      calendarId,
      timeMin: startOfToday.toUtc(),
      timeMax: endOfTomorrow.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );

    return events.items ?? [];
  }

  /// Fetches a contact's photo URL by searching contacts, then directory.
  /// Returns null if no photo found or on error.
  Future<String?> fetchContactPhoto(
    http.Client client,
    String email,
  ) async {
    try {
      final peopleApi = people.PeopleServiceApi(client);
      // Try personal contacts first.
      final contactResult = await peopleApi.people.searchContacts(
        query: email,
        readMask: 'photos',
      );
      final contactUrl = _extractPhotoUrl(contactResult.results, email);
      if (contactUrl != null) return contactUrl;

      // Fallback: search Workspace directory.
      final dirResult = await peopleApi.people.searchDirectoryPeople(
        query: email,
        readMask: 'photos',
        sources: ['DIRECTORY_SOURCE_TYPE_DOMAIN_PROFILE'],
      );
      final dirUrl = _extractDirectoryPhotoUrl(dirResult.people, email);
      if (dirUrl != null) return dirUrl;

      return null;
    } catch (_) {
      return null;
    }
  }

  String? _extractPhotoUrl(
      List<people.SearchResult>? results, String email) {
    if (results == null || results.isEmpty) return null;
    final photos = results.first.person?.photos;
    if (photos == null || photos.isEmpty) return null;
    final photo = photos.firstWhere(
      (p) => p.default_ != true && p.url != null,
      orElse: () => photos.first,
    );
    if (photo.default_ == true) return null;
    return photo.url;
  }

  String? _extractDirectoryPhotoUrl(
      List<people.Person>? people_, String email) {
    if (people_ == null || people_.isEmpty) return null;
    final photos = people_.first.photos;
    if (photos == null || photos.isEmpty) return null;
    final photo = photos.firstWhere(
      (p) => p.default_ != true && p.url != null,
      orElse: () => photos.first,
    );
    if (photo.default_ == true) return null;
    return photo.url;
  }
}
