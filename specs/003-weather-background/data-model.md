# Data Model: Weather Background Feature

## Entities

### WeatherCondition (immutable)

Represents the current weather state from a single API fetch.

| Field | Type | Description |
|-------|------|-------------|
| category | WeatherCategory enum | One of: clear, partlyCloudy, cloudy, rain, snow, thunderstorm, fog |
| temperature | double | Current temperature in Celsius |
| isDaytime | bool | True when `current.is_day == 1` in API response |
| description | String | Human-readable condition (e.g., "light rain") |
| updatedAt | DateTime | Timestamp of the API response |

**Derived properties**:
- `temperatureDisplay` → String: formatted as "14°" (rounded int + degree symbol)
- `isAnimated` → bool: true for rain, snow, thunderstorm categories

**Validation rules**:
- temperature can be any double (no clamping — extreme temps are valid)
- category must be a valid enum value (unknown API codes map to `cloudy` as fallback)

### WeatherCategory (enum)

| Value | Static/Animated | WeatherAPI.com Code Mapping |
|-------|----------------|---------------------------|
| clear | Static | 1000 |
| partlyCloudy | Static | 1003 |
| cloudy | Static | 1006, 1009, fallback |
| rain | Animated | 1063, 1150-1201, 1240-1246 |
| snow | Animated | 1066, 1114, 1117, 1204-1237, 1255-1264 |
| thunderstorm | Animated | 1087, 1273-1282 |
| fog | Static | 1030, 1135, 1147 |

### WeatherLocation (immutable)

Represents the user's configured location for weather data.

| Field | Type | Description |
|-------|------|-------------|
| cityName | String | Display name (e.g., "London") |
| latitude | double | Geographic latitude |
| longitude | double | Geographic longitude |

**Persistence**: Serialized as JSON string, stored via `flutter_secure_storage` with key `weather_location`.

**Lifecycle**:
1. User enters city name via 'W' shortcut
2. First API call uses `q=CityName` parameter
3. Response returns lat/lon → stored alongside city name
4. Subsequent calls use lat/lon directly (more reliable)

## State Transitions

```
No Location → [User enters city via 'W'] → Location Set, No Weather
Location Set, No Weather → [API fetch succeeds] → Weather Available
Weather Available → [API fetch succeeds] → Weather Available (updated)
Weather Available → [API fetch fails] → Weather Available (stale, retained)
Location Set, No Weather → [API fetch fails] → Location Set, No Weather (no visual)
```

## Relationships

- CalendarHomePage holds both `WeatherLocation?` and `WeatherCondition?` as state
- ClockColumn receives `WeatherCondition?` to render the visual
- WeatherService is stateless — receives location, returns condition
