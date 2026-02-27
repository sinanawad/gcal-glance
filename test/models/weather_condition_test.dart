import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/weather_condition.dart';

void main() {
  group('WeatherCategory.fromCode', () {
    test('maps 1000 to clear', () {
      expect(WeatherCategory.fromCode(1000), WeatherCategory.clear);
    });

    test('maps 1003 to partlyCloudy', () {
      expect(WeatherCategory.fromCode(1003), WeatherCategory.partlyCloudy);
    });

    test('maps 1006 and 1009 to cloudy', () {
      expect(WeatherCategory.fromCode(1006), WeatherCategory.cloudy);
      expect(WeatherCategory.fromCode(1009), WeatherCategory.cloudy);
    });

    test('maps rain codes to rain', () {
      expect(WeatherCategory.fromCode(1063), WeatherCategory.rain);
      expect(WeatherCategory.fromCode(1150), WeatherCategory.rain);
      expect(WeatherCategory.fromCode(1183), WeatherCategory.rain);
      expect(WeatherCategory.fromCode(1201), WeatherCategory.rain);
      expect(WeatherCategory.fromCode(1240), WeatherCategory.rain);
      expect(WeatherCategory.fromCode(1246), WeatherCategory.rain);
    });

    test('maps snow codes to snow', () {
      expect(WeatherCategory.fromCode(1066), WeatherCategory.snow);
      expect(WeatherCategory.fromCode(1114), WeatherCategory.snow);
      expect(WeatherCategory.fromCode(1117), WeatherCategory.snow);
      expect(WeatherCategory.fromCode(1210), WeatherCategory.snow);
      expect(WeatherCategory.fromCode(1237), WeatherCategory.snow);
      expect(WeatherCategory.fromCode(1255), WeatherCategory.snow);
      expect(WeatherCategory.fromCode(1264), WeatherCategory.snow);
    });

    test('maps thunderstorm codes to thunderstorm', () {
      expect(WeatherCategory.fromCode(1087), WeatherCategory.thunderstorm);
      expect(WeatherCategory.fromCode(1273), WeatherCategory.thunderstorm);
      expect(WeatherCategory.fromCode(1276), WeatherCategory.thunderstorm);
      expect(WeatherCategory.fromCode(1282), WeatherCategory.thunderstorm);
    });

    test('maps fog codes to fog', () {
      expect(WeatherCategory.fromCode(1030), WeatherCategory.fog);
      expect(WeatherCategory.fromCode(1135), WeatherCategory.fog);
      expect(WeatherCategory.fromCode(1147), WeatherCategory.fog);
    });

    test('maps unknown codes to cloudy fallback', () {
      expect(WeatherCategory.fromCode(9999), WeatherCategory.cloudy);
      expect(WeatherCategory.fromCode(0), WeatherCategory.cloudy);
    });
  });

  group('WeatherCategory.isAnimated', () {
    test('static categories return false', () {
      expect(WeatherCategory.clear.isAnimated, false);
      expect(WeatherCategory.partlyCloudy.isAnimated, false);
      expect(WeatherCategory.cloudy.isAnimated, false);
      expect(WeatherCategory.fog.isAnimated, false);
    });

    test('dynamic categories return true', () {
      expect(WeatherCategory.rain.isAnimated, true);
      expect(WeatherCategory.snow.isAnimated, true);
      expect(WeatherCategory.thunderstorm.isAnimated, true);
    });
  });

  group('WeatherCondition', () {
    test('temperatureDisplay rounds and adds degree symbol', () {
      final condition = WeatherCondition(
        category: WeatherCategory.clear,
        temperature: 14.3,
        isDaytime: true,
        description: 'Sunny',
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(condition.temperatureDisplay, '14°');
    });

    test('temperatureDisplay handles negative temperatures', () {
      final condition = WeatherCondition(
        category: WeatherCategory.snow,
        temperature: -5.7,
        isDaytime: false,
        description: 'Blizzard',
        updatedAt: DateTime.now(),
      );
      expect(condition.temperatureDisplay, '-6°');
    });

    test('temperatureDisplay handles zero', () {
      final condition = WeatherCondition(
        category: WeatherCategory.cloudy,
        temperature: 0.0,
        isDaytime: true,
        description: 'Overcast',
        updatedAt: DateTime.now(),
      );
      expect(condition.temperatureDisplay, '0°');
    });

    test('fromApiResponse parses valid forecast response', () {
      final json = {
        'location': {
          'name': 'Sofia',
          'lat': 42.7,
          'lon': 23.32,
          'localtime': '2026-02-27 14:42',
        },
        'forecast': {
          'forecastday': [
            {
              'day': {
                'avgtemp_c': 22.5,
                'condition': {
                  'text': 'Partly cloudy',
                  'icon': '//cdn.weatherapi.com/weather/64x64/day/116.png',
                },
              },
            },
          ],
        },
      };

      final result = WeatherCondition.fromApiResponse(json);
      expect(result, isNotNull);
      expect(result!.category, WeatherCategory.partlyCloudy);
      expect(result.temperature, 22.5);
      expect(result.isDaytime, true);
      expect(result.description, 'Partly cloudy');
    });

    test('fromApiResponse detects nighttime from icon URL', () {
      final json = {
        'forecast': {
          'forecastday': [
            {
              'day': {
                'avgtemp_c': 5.0,
                'condition': {
                  'text': 'Clear',
                  'icon': '//cdn.weatherapi.com/weather/64x64/night/113.png',
                },
              },
            },
          ],
        },
      };

      final result = WeatherCondition.fromApiResponse(json);
      expect(result, isNotNull);
      expect(result!.isDaytime, false);
      expect(result.category, WeatherCategory.clear);
    });

    test('fromApiResponse returns null on malformed JSON', () {
      expect(WeatherCondition.fromApiResponse({}), isNull);
      expect(WeatherCondition.fromApiResponse({'forecast': 'bad'}), isNull);
    });

    test('isAnimated delegates to category', () {
      final rain = WeatherCondition(
        category: WeatherCategory.rain,
        temperature: 10.0,
        isDaytime: true,
        description: 'Rain',
        updatedAt: DateTime.now(),
      );
      final clear = WeatherCondition(
        category: WeatherCategory.clear,
        temperature: 25.0,
        isDaytime: true,
        description: 'Sunny',
        updatedAt: DateTime.now(),
      );
      expect(rain.isAnimated, true);
      expect(clear.isAnimated, false);
    });
  });

  group('WeatherLocation', () {
    test('toJson and fromJson round-trip', () {
      const location = WeatherLocation(
        cityName: 'Sofia',
        latitude: 42.6977,
        longitude: 23.3219,
      );

      final json = location.toJson();
      final restored = WeatherLocation.fromJson(json);

      expect(restored.cityName, 'Sofia');
      expect(restored.latitude, 42.6977);
      expect(restored.longitude, 23.3219);
    });

    test('toJsonString and fromJsonString round-trip', () {
      const location = WeatherLocation(
        cityName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
      );

      final jsonStr = location.toJsonString();
      final restored = WeatherLocation.fromJsonString(jsonStr);

      expect(restored, isNotNull);
      expect(restored!.cityName, 'London');
      expect(restored.latitude, 51.5074);
      expect(restored.longitude, -0.1278);
    });

    test('fromJsonString returns null on invalid JSON', () {
      expect(WeatherLocation.fromJsonString('not json'), isNull);
      expect(WeatherLocation.fromJsonString(''), isNull);
    });
  });
}
