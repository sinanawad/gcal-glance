import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockHttpClient extends Mock implements http.Client {}

/// Encode credentials in the same JSON format the service uses.
String _encodeCredentials(auth.AccessCredentials credentials) {
  return jsonEncode({
    'accessToken': {
      'type': credentials.accessToken.type,
      'data': credentials.accessToken.data,
      'expiry': credentials.accessToken.expiry.toIso8601String(),
    },
    'refreshToken': credentials.refreshToken,
    'scopes': credentials.scopes,
    'idToken': credentials.idToken,
  });
}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late GoogleCalendarService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = GoogleCalendarService(
      httpClientFactory: () => MockHttpClient(),
      secureStorage: mockStorage,
      clientId: auth.ClientId('test-id', 'test-secret'),
    );
  });

  group('getAuthenticatedClient', () {
    test('returns null when no saved credentials exist', () async {
      when(() => mockStorage.read(key: 'gcal_oauth_token'))
          .thenAnswer((_) async => null);

      final client = await service.getAuthenticatedClient();

      expect(client, isNull);
      verify(() => mockStorage.read(key: 'gcal_oauth_token')).called(1);
    });

    test('returns null and clears storage when credentials are corrupted',
        () async {
      when(() => mockStorage.read(key: 'gcal_oauth_token'))
          .thenAnswer((_) async => 'not valid json {{{');
      when(() => mockStorage.delete(key: 'gcal_oauth_token'))
          .thenAnswer((_) async {});

      final client = await service.getAuthenticatedClient();

      expect(client, isNull);
      verify(() => mockStorage.delete(key: 'gcal_oauth_token')).called(1);
    });

    test('restores client from valid saved credentials', () async {
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          'access-data',
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        'refresh-token',
        ['https://www.googleapis.com/auth/calendar.readonly'],
      );

      when(() => mockStorage.read(key: 'gcal_oauth_token'))
          .thenAnswer((_) async => _encodeCredentials(credentials));
      when(() => mockStorage.write(
            key: 'gcal_oauth_token',
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final client = await service.getAuthenticatedClient();

      expect(client, isNotNull);
      verify(() => mockStorage.read(key: 'gcal_oauth_token')).called(1);
    });

    test('returns cached client on subsequent calls', () async {
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          'access-data',
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        'refresh-token',
        ['https://www.googleapis.com/auth/calendar.readonly'],
      );

      when(() => mockStorage.read(key: 'gcal_oauth_token'))
          .thenAnswer((_) async => _encodeCredentials(credentials));
      when(() => mockStorage.write(
            key: 'gcal_oauth_token',
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final first = await service.getAuthenticatedClient();
      final second = await service.getAuthenticatedClient();

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
      // Storage only read once — second call uses cache.
      verify(() => mockStorage.read(key: 'gcal_oauth_token')).called(1);
    });
  });

  group('signOut', () {
    test('deletes credentials from secure storage', () async {
      when(() => mockStorage.delete(key: 'gcal_oauth_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'gcal_selected_calendars'))
          .thenAnswer((_) async {});

      await service.signOut();

      verify(() => mockStorage.delete(key: 'gcal_oauth_token')).called(1);
      verify(() => mockStorage.delete(key: 'gcal_selected_calendars')).called(1);
    });

    test('clears cached client so next getAuthenticatedClient reads storage',
        () async {
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          'access-data',
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        'refresh-token',
        ['https://www.googleapis.com/auth/calendar.readonly'],
      );

      when(() => mockStorage.read(key: 'gcal_oauth_token'))
          .thenAnswer((_) async => _encodeCredentials(credentials));
      when(() => mockStorage.write(
            key: 'gcal_oauth_token',
            value: any(named: 'value'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'gcal_oauth_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'gcal_selected_calendars'))
          .thenAnswer((_) async {});

      // Establish a cached client.
      await service.getAuthenticatedClient();

      await service.signOut();

      // After sign-out, storage returns null → no client.
      when(() => mockStorage.read(key: 'gcal_oauth_token'))
          .thenAnswer((_) async => null);
      final client = await service.getAuthenticatedClient();

      expect(client, isNull);
    });
  });
}
