import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

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

  /// Returns the cached authenticated client, or attempts to restore from
  /// secure storage. Returns null if no saved credentials exist.
  Future<http.Client?> getAuthenticatedClient() async {
    if (_client != null) return _client;
    // Stub: US1 will implement _loadSavedCredentials from secure storage
    return null;
  }

  /// Opens browser for OAuth consent, obtains credentials, persists them,
  /// and returns the authenticated client.
  Future<http.Client?> signIn() async {
    if (_client != null) return _client;
    // Stub: US1 will implement full browser-based OAuth flow
    return null;
  }

  /// Closes the HTTP client, cancels credential update subscription,
  /// and deletes saved credentials.
  Future<void> signOut() async {
    _credentialUpdatesSubscription?.cancel();
    _credentialUpdatesSubscription = null;
    _client?.close();
    _client = null;
    // Stub: US1 will implement _clearCredentials from secure storage
  }

  /// Closes any open HTTP clients. Call from widget dispose().
  void dispose() {
    _credentialUpdatesSubscription?.cancel();
    _credentialUpdatesSubscription = null;
    _client?.close();
    _client = null;
  }

  /// Fetches events from the given calendar IDs for today and tomorrow.
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
