import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class GoogleCalendarService {
  static const _tokenFile = 'token.json';
  static const _credentialsFile = 'go-gcal-cli-credentials.json';

  auth.AutoRefreshingAuthClient? _client;

  Future<auth.ClientId?> _getClientId() async {
    final credentialsPath = path.join(Directory.current.path, _credentialsFile);
    final file = File(credentialsPath);
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    final json = jsonDecode(content);
    final installed = json['installed'];
    if (installed == null) {
      return null;
    }
    return auth.ClientId(installed['client_id'], installed['client_secret']);
  }

  void _saveCredentials(auth.AccessCredentials credentials) {
    final tokenPath = path.join(Directory.current.path, _tokenFile);
    final file = File(tokenPath);
    file.writeAsStringSync(json.encode(credentials.toJson()));
  }

  Future<bool> _loadSavedCredentials() async {
    final tokenPath = path.join(Directory.current.path, _tokenFile);
    final file = File(tokenPath);
    if (!await file.exists()) return false;

    final clientId = await _getClientId();
    if (clientId == null) return false;

    try {
      final contents = await file.readAsString();
      final credentials = auth.AccessCredentials.fromJson(
        json.decode(contents),
      );
      _client = auth.autoRefreshingClient(clientId, credentials, http.Client());
      return true;
    } catch (e) {
      dev.log('Could not load saved credentials: $e');
      return false;
    }
  }

  Future<http.Client?> getAuthenticatedClient() async {
    if (_client != null) return _client;
    if (await _loadSavedCredentials()) {
      return _client;
    }
    return null;
  }

  Future<http.Client?> signIn() async {
    if (_client != null) return _client;

    if (await _loadSavedCredentials()) {
      return _client;
    }

    final clientId = await _getClientId();
    if (clientId == null) {
      dev.log(
        'Could not find or parse $_credentialsFile. Please ensure it is in the project root directory.',
      );
      return null;
    }

    try {
      final credentials = await obtainAccessCredentialsViaUserConsent(
        clientId,
        [calendar.CalendarApi.calendarReadonlyScope],
        http.Client(),
        (url) {
          launchUrl(Uri.parse(url));
        },
      );
      _saveCredentials(credentials);
      _client = auth.autoRefreshingClient(clientId, credentials, http.Client());
      return _client;
    } catch (e) {
      dev.log('Sign in failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    _client?.close();
    _client = null;
    final tokenPath = path.join(Directory.current.path, _tokenFile);
    final file = File(tokenPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
