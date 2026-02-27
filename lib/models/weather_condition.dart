import 'dart:convert';

/// Weather condition categories mapped from WeatherAPI.com condition codes.
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

  /// Maps a WeatherAPI.com condition code to a category.
  /// Unknown codes fall back to [cloudy].
  static WeatherCategory fromCode(int code) {
    if (code == 1000) return clear;
    if (code == 1003) return partlyCloudy;
    if (code == 1006 || code == 1009) return cloudy;
    if (code == 1030 || code == 1135 || code == 1147) return fog;
    if (code == 1087 || (code >= 1273 && code <= 1282)) return thunderstorm;
    if (code == 1066 ||
        code == 1114 ||
        code == 1117 ||
        (code >= 1204 && code <= 1237) ||
        (code >= 1255 && code <= 1264)) {
      return snow;
    }
    if (code == 1063 ||
        (code >= 1150 && code <= 1201) ||
        (code >= 1240 && code <= 1246)) {
      return rain;
    }
    return cloudy; // safe fallback
  }

  /// Maps a WeatherAPI.com icon filename number to a category.
  /// Icon URLs look like: //cdn.weatherapi.com/weather/64x64/day/113.png
  /// The number (113) maps to a condition. Unknown numbers fall back to [cloudy].
  static WeatherCategory fromIconCode(int iconCode) {
    switch (iconCode) {
      case 113: return clear;             // Sunny / Clear
      case 116: return partlyCloudy;      // Partly cloudy
      case 119: return cloudy;            // Cloudy
      case 122: return cloudy;            // Overcast
      case 143: return fog;               // Mist
      case 176: return rain;              // Patchy rain possible
      case 179: return snow;              // Patchy snow possible
      case 182: return snow;              // Patchy sleet possible
      case 185: return rain;              // Patchy freezing drizzle
      case 200: return thunderstorm;      // Thundery outbreaks possible
      case 227: return snow;              // Blowing snow
      case 230: return snow;              // Blizzard
      case 248: return fog;               // Fog
      case 260: return fog;               // Freezing fog
      case 263: return rain;              // Patchy light drizzle
      case 266: return rain;              // Light drizzle
      case 281: return rain;              // Freezing drizzle
      case 284: return rain;              // Heavy freezing drizzle
      case 293: return rain;              // Patchy light rain
      case 296: return rain;              // Light rain
      case 299: return rain;              // Moderate rain at times
      case 302: return rain;              // Moderate rain
      case 305: return rain;              // Heavy rain at times
      case 308: return rain;              // Heavy rain
      case 311: return rain;              // Light freezing rain
      case 314: return rain;              // Moderate/heavy freezing rain
      case 317: return snow;              // Light sleet
      case 320: return snow;              // Moderate/heavy sleet
      case 323: return snow;              // Patchy light snow
      case 326: return snow;              // Light snow
      case 329: return snow;              // Patchy moderate snow
      case 332: return snow;              // Moderate snow
      case 335: return snow;              // Patchy heavy snow
      case 338: return snow;              // Heavy snow
      case 350: return snow;              // Ice pellets
      case 353: return rain;              // Light rain shower
      case 356: return rain;              // Moderate/heavy rain shower
      case 359: return rain;              // Torrential rain shower
      case 362: return snow;              // Light sleet showers
      case 365: return snow;              // Moderate/heavy sleet showers
      case 368: return snow;              // Light snow showers
      case 371: return snow;              // Moderate/heavy snow showers
      case 374: return snow;              // Light showers of ice pellets
      case 377: return snow;              // Moderate/heavy showers of ice pellets
      case 386: return thunderstorm;      // Patchy light rain with thunder
      case 389: return thunderstorm;      // Moderate/heavy rain with thunder
      case 392: return thunderstorm;      // Patchy light snow with thunder
      case 395: return thunderstorm;      // Moderate/heavy snow with thunder
      default: return cloudy;
    }
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

  /// Creates a [WeatherCondition] from a WeatherAPI.com forecast JSON response.
  /// Uses `forecast.forecastday[0].day` for temperature and condition.
  /// Determines isDaytime from the icon URL path segment (day/ vs night/).
  /// Returns `null` if the response is malformed.
  static WeatherCondition? fromApiResponse(Map<String, dynamic> json) {
    try {
      final forecast = json['forecast'] as Map<String, dynamic>;
      final forecastDays = forecast['forecastday'] as List<dynamic>;
      final day = (forecastDays[0] as Map<String, dynamic>)['day']
          as Map<String, dynamic>;
      final condition = day['condition'] as Map<String, dynamic>;
      final tempC = (day['avgtemp_c'] as num).toDouble();
      final iconUrl = condition['icon'] as String;
      final text = (condition['text'] as String?) ?? '';

      // Extract icon code number from URL like //cdn.../day/113.png
      final iconMatch = RegExp(r'/(\d+)\.png').firstMatch(iconUrl);
      final iconCode = iconMatch != null ? int.parse(iconMatch.group(1)!) : 0;

      // Determine day/night from icon URL path
      final isDaytime = iconUrl.contains('/day/');

      // Upgrade to 128x128 icon for crisp rendering
      final hiResUrl = 'https:${iconUrl.replaceFirst('64x64', '128x128')}';

      return WeatherCondition(
        category: WeatherCategory.fromIconCode(iconCode),
        temperature: tempC,
        isDaytime: isDaytime,
        description: text,
        iconUrl: hiResUrl,
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
