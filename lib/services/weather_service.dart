import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gcal_glance/config/weather_config.dart';
import 'package:gcal_glance/models/weather_condition.dart';
import 'package:http/http.dart' as http;

/// Fetches weather data from WeatherAPI.com using the forecast endpoint.
///
/// The free tier's current.json returns empty data, so we use
/// forecast.json?days=1 which provides today's forecast reliably.
///
/// Accepts an [http.Client] via constructor for testability
/// (Constitution VII: constructor injection).
class WeatherService {
  final http.Client _client;

  WeatherService(this._client);

  static const _baseUrl = 'https://api.weatherapi.com/v1/forecast.json';

  /// Fetches today's forecast for the given [location].
  /// Returns `null` on any error (network, parse, API error).
  Future<WeatherCondition?> fetchWeather(WeatherLocation location) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?key=$weatherApiKey&q=${location.latitude},${location.longitude}&days=1',
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

  /// Resolves a city name to a [WeatherLocation] by making an API call.
  /// The response includes the resolved lat/lon and canonical city name.
  /// Returns `null` on any error.
  Future<WeatherLocation?> fetchLocationByCity(String cityName) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?key=$weatherApiKey&q=${Uri.encodeComponent(cityName)}&days=1',
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final location = json['location'] as Map<String, dynamic>;
      final name = location['name'] as String;
      final lat = (location['lat'] as num).toDouble();
      final lon = (location['lon'] as num).toDouble();

      return WeatherLocation(
        cityName: name,
        latitude: lat,
        longitude: lon,
      );
    } catch (e) {
      debugPrint('WeatherService: fetchLocationByCity exception=$e');
      return null;
    }
  }
}
