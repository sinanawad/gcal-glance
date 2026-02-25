import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

const _storageKey = 'gcal_oauth_token';
const _selectedCalendarsKey = 'gcal_selected_calendars';
const _scopes = [calendar.CalendarApi.calendarReadonlyScope];

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

    final events = await calendarApi.events.list(
      calendarId,
      timeMin: now.toUtc(),
      timeMax: endOfTomorrow.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );

    return events.items ?? [];
  }
}
