import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/weather_condition.dart';

void main() {
  group('WeatherCategory.fromWmoCode', () {
    test('maps 0 and 1 to clear', () {
      expect(WeatherCategory.fromWmoCode(0), WeatherCategory.clear);
      expect(WeatherCategory.fromWmoCode(1), WeatherCategory.clear);
    });

    test('maps 2 to partlyCloudy', () {
      expect(WeatherCategory.fromWmoCode(2), WeatherCategory.partlyCloudy);
    });

    test('maps 3 to cloudy', () {
      expect(WeatherCategory.fromWmoCode(3), WeatherCategory.cloudy);
    });

    test('maps fog codes to fog', () {
      expect(WeatherCategory.fromWmoCode(45), WeatherCategory.fog);
      expect(WeatherCategory.fromWmoCode(48), WeatherCategory.fog);
    });

    test('maps drizzle and rain codes to rain', () {
      expect(WeatherCategory.fromWmoCode(51), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(53), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(55), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(61), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(63), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(65), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(80), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(82), WeatherCategory.rain);
    });

    test('maps freezing precipitation to rain', () {
      expect(WeatherCategory.fromWmoCode(56), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(57), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(66), WeatherCategory.rain);
      expect(WeatherCategory.fromWmoCode(67), WeatherCategory.rain);
    });

    test('maps snow codes to snow', () {
      expect(WeatherCategory.fromWmoCode(71), WeatherCategory.snow);
      expect(WeatherCategory.fromWmoCode(73), WeatherCategory.snow);
      expect(WeatherCategory.fromWmoCode(75), WeatherCategory.snow);
      expect(WeatherCategory.fromWmoCode(77), WeatherCategory.snow);
      expect(WeatherCategory.fromWmoCode(85), WeatherCategory.snow);
      expect(WeatherCategory.fromWmoCode(86), WeatherCategory.snow);
    });

    test('maps thunderstorm codes to thunderstorm', () {
      expect(WeatherCategory.fromWmoCode(95), WeatherCategory.thunderstorm);
      expect(WeatherCategory.fromWmoCode(96), WeatherCategory.thunderstorm);
      expect(WeatherCategory.fromWmoCode(99), WeatherCategory.thunderstorm);
    });

    test('maps unknown codes to cloudy fallback', () {
      expect(WeatherCategory.fromWmoCode(9999), WeatherCategory.cloudy);
      expect(WeatherCategory.fromWmoCode(-1), WeatherCategory.cloudy);
    });
  });

  group('WeatherCategory.wmoToIconCode', () {
    test('maps clear to 113', () {
      expect(WeatherCategory.wmoToIconCode(0), 113);
      expect(WeatherCategory.wmoToIconCode(1), 113);
    });

    test('maps partly cloudy to 116', () {
      expect(WeatherCategory.wmoToIconCode(2), 116);
    });

    test('maps rain intensities to different icons', () {
      expect(WeatherCategory.wmoToIconCode(61), 296); // slight
      expect(WeatherCategory.wmoToIconCode(63), 302); // moderate
      expect(WeatherCategory.wmoToIconCode(65), 308); // heavy
    });

    test('maps snow intensities to different icons', () {
      expect(WeatherCategory.wmoToIconCode(71), 326); // slight
      expect(WeatherCategory.wmoToIconCode(73), 332); // moderate
      expect(WeatherCategory.wmoToIconCode(75), 338); // heavy
    });

    test('maps thunderstorm to 389', () {
      expect(WeatherCategory.wmoToIconCode(95), 389);
    });

    test('maps unknown to 119 (cloudy)', () {
      expect(WeatherCategory.wmoToIconCode(9999), 119);
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
        description: '',
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(condition.temperatureDisplay, '14°');
    });

    test('temperatureDisplay handles negative temperatures', () {
      final condition = WeatherCondition(
        category: WeatherCategory.snow,
        temperature: -5.7,
        isDaytime: false,
        description: '',
        updatedAt: DateTime.now(),
      );
      expect(condition.temperatureDisplay, '-6°');
    });

    test('temperatureDisplay handles zero', () {
      final condition = WeatherCondition(
        category: WeatherCategory.cloudy,
        temperature: 0.0,
        isDaytime: true,
        description: '',
        updatedAt: DateTime.now(),
      );
      expect(condition.temperatureDisplay, '0°');
    });

    test('fromApiResponse parses valid Open-Meteo response', () {
      final json = {
        'current': {
          'temperature_2m': 14.5,
          'weather_code': 2,
          'is_day': 1,
        },
      };

      final result = WeatherCondition.fromApiResponse(json);
      expect(result, isNotNull);
      expect(result!.category, WeatherCategory.partlyCloudy);
      expect(result.temperature, 14.5);
      expect(result.isDaytime, true);
      expect(
        result.iconUrl,
        'https://cdn.weatherapi.com/weather/128x128/day/116.png',
      );
    });

    test('fromApiResponse uses night icon when is_day is 0', () {
      final json = {
        'current': {
          'temperature_2m': 5.0,
          'weather_code': 0,
          'is_day': 0,
        },
      };

      final result = WeatherCondition.fromApiResponse(json);
      expect(result, isNotNull);
      expect(result!.isDaytime, false);
      expect(result.category, WeatherCategory.clear);
      expect(
        result.iconUrl,
        'https://cdn.weatherapi.com/weather/128x128/night/113.png',
      );
    });

    test('fromApiResponse returns null on malformed JSON', () {
      expect(WeatherCondition.fromApiResponse({}), isNull);
      expect(WeatherCondition.fromApiResponse({'current': 'bad'}), isNull);
    });

    test('isAnimated delegates to category', () {
      final rain = WeatherCondition(
        category: WeatherCategory.rain,
        temperature: 10.0,
        isDaytime: true,
        description: '',
        updatedAt: DateTime.now(),
      );
      final clear = WeatherCondition(
        category: WeatherCategory.clear,
        temperature: 25.0,
        isDaytime: true,
        description: '',
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
