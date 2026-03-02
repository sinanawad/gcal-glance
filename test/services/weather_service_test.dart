import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/weather_condition.dart';
import 'package:gcal_glance/services/weather_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late MockClient mockClient;
  late WeatherService service;

  setUp(() {
    mockClient = MockClient();
    service = WeatherService(mockClient);
  });

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  final sampleWeatherResponse = jsonEncode({
    'current': {
      'temperature_2m': 14.5,
      'weather_code': 2,
      'is_day': 1,
    },
  });

  final sampleGeocodingResponse = jsonEncode({
    'results': [
      {
        'name': 'Sofia',
        'latitude': 42.6977,
        'longitude': 23.3219,
      },
    ],
  });

  group('fetchWeather', () {
    test('returns WeatherCondition on success', () async {
      final location = const WeatherLocation(
        cityName: 'Sofia',
        latitude: 42.7,
        longitude: 23.32,
      );

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(sampleWeatherResponse, 200),
      );

      final result = await service.fetchWeather(location);
      expect(result, isNotNull);
      expect(result!.category, WeatherCategory.partlyCloudy);
      expect(result.temperature, 14.5);
      expect(result.isDaytime, true);
    });

    test('returns null on HTTP error', () async {
      final location = const WeatherLocation(
        cityName: 'Sofia',
        latitude: 42.7,
        longitude: 23.32,
      );

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('{"error": "bad request"}', 400),
      );

      final result = await service.fetchWeather(location);
      expect(result, isNull);
    });

    test('returns null on network exception', () async {
      final location = const WeatherLocation(
        cityName: 'Sofia',
        latitude: 42.7,
        longitude: 23.32,
      );

      when(() => mockClient.get(any())).thenThrow(
        http.ClientException('Connection refused'),
      );

      final result = await service.fetchWeather(location);
      expect(result, isNull);
    });

    test('returns null on malformed JSON', () async {
      final location = const WeatherLocation(
        cityName: 'Sofia',
        latitude: 42.7,
        longitude: 23.32,
      );

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('not json', 200),
      );

      final result = await service.fetchWeather(location);
      expect(result, isNull);
    });
  });

  group('fetchLocationByCity', () {
    test('returns WeatherLocation with resolved lat/lon', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(sampleGeocodingResponse, 200),
      );

      final result = await service.fetchLocationByCity('Sofia');
      expect(result, isNotNull);
      expect(result!.cityName, 'Sofia');
      expect(result.latitude, 42.6977);
      expect(result.longitude, 23.3219);
    });

    test('returns null when no results found', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode({}), 200),
      );

      final result = await service.fetchLocationByCity('Xyzzyville');
      expect(result, isNull);
    });

    test('returns null on HTTP error', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('{"error": "not found"}', 400),
      );

      final result = await service.fetchLocationByCity('InvalidCity');
      expect(result, isNull);
    });

    test('returns null on network exception', () async {
      when(() => mockClient.get(any())).thenThrow(
        http.ClientException('Connection refused'),
      );

      final result = await service.fetchLocationByCity('Sofia');
      expect(result, isNull);
    });
  });
}
