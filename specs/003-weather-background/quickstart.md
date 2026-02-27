# Quickstart: Weather Background Feature

## Prerequisites

1. Existing gcal-glance app running on Linux desktop
2. WeatherAPI.com account with API key ([sign up free](https://www.weatherapi.com/))

## Setup

### 1. Add Weather API Key

```bash
# Copy the template
cp lib/config/weather_config.example.dart lib/config/weather_config.dart

# Edit and replace YOUR_API_KEY with your OpenWeatherMap key
```

### 2. Build & Run

```bash
flutter pub get
flutter run -d linux
```

### 3. Configure Location

1. Press **W** to open the location dialog
2. Enter a city name (e.g., "Sofia" or "London")
3. Weather visual appears behind the date within seconds

## Files Added/Modified

| File | Change |
|------|--------|
| `lib/config/weather_config.example.dart` | **NEW** — API key template |
| `lib/config/weather_config.dart` | **NEW** (gitignored) — actual API key |
| `lib/models/weather_condition.dart` | **NEW** — WeatherCondition + WeatherCategory + WeatherLocation models |
| `lib/services/weather_service.dart` | **NEW** — OpenWeatherMap API client |
| `lib/widgets/weather_background.dart` | **NEW** — CustomPainter for weather visuals (icons + particle animations) |
| `lib/widgets/clock_column.dart` | **MODIFIED** — Stack weather visual behind date, show temperature |
| `lib/screens/calendar_home_page.dart` | **MODIFIED** — Weather polling, location state, 'W' shortcut |
| `lib/main.dart` | **MODIFIED** — Inject WeatherService |
| `.gitignore` | **MODIFIED** — Add weather_config.dart |
| `test/models/weather_condition_test.dart` | **NEW** — Model unit tests |

## Verification

```bash
flutter analyze    # Zero issues
flutter test       # All tests pass
```

## Usage

- **W** key: Configure weather location
- Weather updates automatically every 30 minutes
- Calm conditions (clear, cloudy, fog): static CRT-styled icons
- Dynamic conditions (rain, snow, storm): subtle particle animations
- Temperature shown as small text near the date (e.g., "14°")
