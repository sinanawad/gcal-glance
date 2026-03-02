import 'dart:convert';

/// Weather condition categories mapped from WMO weather codes.
enum WeatherCategory {
  clear,
  partlyCloudy,
  cloudy,
  rain,
  snow,
  thunderstorm,
  fog;

  /// Whether this category uses animated particles.
  bool get isAnimated =>
      this == rain || this == snow || this == thunderstorm;

  /// Maps a WMO weather interpretation code to a category.
  /// See https://open-meteo.com/en/docs for code table.
  /// Unknown codes fall back to [cloudy].
  static WeatherCategory fromWmoCode(int code) {
    return switch (code) {
      0 || 1 => clear,
      2 => partlyCloudy,
      3 => cloudy,
      45 || 48 => fog,
      51 || 53 || 55 || 56 || 57 => rain,     // drizzle / freezing drizzle
      61 || 63 || 65 || 66 || 67 => rain,     // rain / freezing rain
      71 || 73 || 75 || 77 => snow,            // snow / snow grains
      80 || 81 || 82 => rain,                  // rain showers
      85 || 86 => snow,                        // snow showers
      95 || 96 || 99 => thunderstorm,          // thunderstorm (+ hail)
      _ => cloudy,
    };
  }

  /// Maps a WMO weather code to a WeatherAPI.com icon filename number.
  /// This lets us use WeatherAPI's polished CDN icons with Open-Meteo data.
  static int wmoToIconCode(int wmoCode) {
    return switch (wmoCode) {
      0 || 1 => 113,   // Sunny / Clear
      2 => 116,         // Partly cloudy
      3 => 122,         // Overcast
      45 || 48 => 143,  // Fog
      51 => 263,         // Light drizzle
      53 => 266,         // Drizzle
      55 => 302,         // Dense drizzle
      56 => 281,         // Freezing drizzle
      57 => 284,         // Heavy freezing drizzle
      61 => 296,         // Slight rain
      63 => 302,         // Moderate rain
      65 => 308,         // Heavy rain
      66 => 311,         // Light freezing rain
      67 => 314,         // Heavy freezing rain
      71 => 326,         // Slight snow
      73 => 332,         // Moderate snow
      75 => 338,         // Heavy snow
      77 => 350,         // Snow grains
      80 => 353,         // Slight rain showers
      81 => 356,         // Moderate rain showers
      82 => 359,         // Violent rain showers
      85 => 368,         // Slight snow showers
      86 => 371,         // Heavy snow showers
      95 => 389,         // Thunderstorm
      96 => 392,         // Thunderstorm + slight hail
      99 => 395,         // Thunderstorm + heavy hail
      _ => 119,          // Cloudy fallback
    };
  }
}

/// Immutable snapshot of current weather from a single API fetch.
class WeatherCondition {
  final WeatherCategory category;
  final double temperature;
  final bool isDaytime;
  final String description;
  final String? iconUrl;
  final DateTime updatedAt;

  const WeatherCondition({
    required this.category,
    required this.temperature,
    required this.isDaytime,
    required this.description,
    this.iconUrl,
    required this.updatedAt,
  });

  /// Whether this condition uses animated particles.
  bool get isAnimated => category.isAnimated;

  /// Temperature formatted as rounded int + degree symbol (e.g. "14°").
  String get temperatureDisplay => '${temperature.round()}°';

  /// Creates a [WeatherCondition] from an Open-Meteo JSON response.
  /// Expects `current.temperature_2m`, `current.weather_code`, `current.is_day`.
  /// Uses WeatherAPI.com CDN for icons via WMO → icon code mapping.
  /// Returns `null` if the response is malformed.
  static WeatherCondition? fromApiResponse(Map<String, dynamic> json) {
    try {
      final current = json['current'] as Map<String, dynamic>;
      final tempC = (current['temperature_2m'] as num).toDouble();
      final wmoCode = current['weather_code'] as int;
      final isDay = current['is_day'] as int;

      final isDaytime = isDay == 1;
      final iconCode = WeatherCategory.wmoToIconCode(wmoCode);
      final dayNight = isDaytime ? 'day' : 'night';

      return WeatherCondition(
        category: WeatherCategory.fromWmoCode(wmoCode),
        temperature: tempC,
        isDaytime: isDaytime,
        description: '',
        iconUrl:
            'https://cdn.weatherapi.com/weather/128x128/$dayNight/$iconCode.png',
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Immutable user-configured location for weather data.
class WeatherLocation {
  final String cityName;
  final double latitude;
  final double longitude;

  const WeatherLocation({
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  /// Serializes to a JSON-encodable map for secure storage.
  Map<String, dynamic> toJson() => {
        'cityName': cityName,
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Deserializes from a JSON map.
  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      cityName: json['cityName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  /// Convenience: deserialize from a JSON string.
  static WeatherLocation? fromJsonString(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return WeatherLocation.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Convenience: serialize to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}
