import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gcal_glance/models/weather_condition.dart';
import 'package:http/http.dart' as http;

/// Fetches current weather data from Open-Meteo (free, no API key).
///
/// Accepts an [http.Client] via constructor for testability.
class WeatherService {
  final http.Client _client;

  WeatherService(this._client);

  static const _weatherUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _geocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  /// Fetches current weather for the given [location].
  /// Returns `null` on any error (network, parse, API error).
  Future<WeatherCondition?> fetchWeather(WeatherLocation location) async {
    try {
      final uri = Uri.parse(
        '$_weatherUrl?latitude=${location.latitude}&longitude=${location.longitude}'
        '&current=temperature_2m,weather_code,is_day',
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherCondition.fromApiResponse(json);
    } catch (e) {
      debugPrint('WeatherService: fetchWeather exception=$e');
      return null;
    }
  }

  /// Resolves a city name to a [WeatherLocation] using Open-Meteo geocoding.
  /// Returns `null` on any error.
  Future<WeatherLocation?> fetchLocationByCity(String cityName) async {
    try {
      final uri = Uri.parse(
        '$_geocodingUrl?name=${Uri.encodeComponent(cityName)}&count=1',
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results[0] as Map<String, dynamic>;
      return WeatherLocation(
        cityName: first['name'] as String,
        latitude: (first['latitude'] as num).toDouble(),
        longitude: (first['longitude'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('WeatherService: fetchLocationByCity exception=$e');
      return null;
    }
  }
}
