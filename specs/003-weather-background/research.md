# Research: Weather Background Feature

## Decision 1: Weather API Provider

**Decision**: WeatherAPI.com (free tier, user already has account and key)

**Rationale**:
- User already has an account and API key
- Free tier: 1,000,000 calls/month — more than sufficient at 30-min intervals (~1,440 calls/month)
- Simple REST endpoint: `https://api.weatherapi.com/v1/current.json?key=KEY&q=CITY`
- Returns `is_day` field directly (1/0) — no sunrise/sunset computation needed for FR-008
- Condition codes with human-readable `condition.text` and numeric `condition.code`
- Accepts city names directly via `q=` parameter — no separate geocoding needed
- Response includes lat/lon for the resolved location

**Alternatives considered**:
- OpenWeatherMap — similar capability but user doesn't have an account
- Open-Meteo (no API key needed) — less granular condition codes
- AccuWeather — more restrictive free tier

## Decision 2: Weather Condition Mapping

**Decision**: Map WeatherAPI.com condition codes to 7 visual categories

| WeatherAPI Codes | Our Category | Visual Type | Day/Night Variant |
|-----------------|--------------|-------------|-------------------|
| 1000 | clear | Static icon | Sun / Moon+stars |
| 1003 | partlyCloudy | Static icon | Sun+cloud / Moon+cloud |
| 1006, 1009 | cloudy | Static icon | Same day/night |
| 1063, 1150-1201, 1240-1246 | rain | Animated particles | Falling drops |
| 1066, 1114, 1117, 1204-1237, 1255-1264 | snow | Animated particles | Falling flakes |
| 1087, 1273-1282 | thunderstorm | Animated particles | Drops + flash |
| 1030, 1135, 1147 | fog | Static icon | Horizontal lines |
| (any other code) | cloudy | Static icon | Safe fallback |

**Rationale**: 7 categories cover all common conditions. Uncommon codes map to nearest visual. Day/night provided directly by `is_day` field in API response.

## Decision 3: No New Dependencies

**Decision**: Use only the existing `http` and `dart:convert` packages

**Rationale**:
- `http` package already in pubspec.yaml (used by googleapis)
- WeatherAPI.com returns simple JSON — `dart:convert` handles parsing
- No weather-specific SDK needed for a single REST endpoint
- Keeps dependency count minimal per project conventions

## Decision 4: Location Input Method

**Decision**: Keyboard shortcut 'W' opens a text dialog for city name; resolved via WeatherAPI.com's built-in `q=CityName` parameter

**Rationale**:
- Consistent with existing shortcuts (S/M/O/C)
- WeatherAPI.com accepts city names directly (`q=Sofia`) — no separate geocoding needed
- First successful fetch returns lat/lon in `location` object, which we persist for subsequent calls
- City name stored alongside lat/lon for display purposes

**Alternatives considered**:
- Lat/lon only input — too unfriendly for casual use
- Separate geocoding step — unnecessary since the weather API handles it

## Decision 5: Polling Strategy

**Decision**: Separate 30-minute timer for weather, independent of the 60-second calendar poll

**Rationale**:
- Weather changes slowly — 30-minute interval is standard and well within API quota
- Separate timer prevents weather fetch failures from affecting calendar updates
- Initial fetch at startup, then periodic; failed fetches silently retain last known data

## Decision 6: Visual Rendering Approach

**Decision**: CustomPainter behind the date text in ClockColumn, matching CRT aesthetic

**Rationale**:
- CustomPainter already used extensively (TimelineStrip, CrosshatchPainter, FlipDigit)
- Can draw CRT-styled icons (line art, pixel-style) and particle animations
- Layered behind date text via Stack widget — text stays legible
- Low opacity (0.3-0.5) ensures weather visual is ambient, not distracting
- Particle animations (rain/snow) use simple offset lists updated per frame

## Decision 7: Temperature Unit

**Decision**: Celsius — WeatherAPI.com's `temp_c` field used directly

**Rationale**:
- API returns `temp_c` (Celsius) directly in the response
- No conversion needed
- Matches user's locale
- Could be made configurable later but not in scope for this spec

## WeatherAPI.com Response Format

Endpoint: `GET https://api.weatherapi.com/v1/current.json?key={KEY}&q={QUERY}`

Key fields used from response:

```
location.name        → city display name
location.lat         → latitude (persist for subsequent calls)
location.lon         → longitude (persist for subsequent calls)
current.temp_c       → temperature in Celsius
current.is_day       → 1 (day) or 0 (night)
current.condition.text  → "Partly cloudy", "Light rain", etc.
current.condition.code  → numeric code for category mapping
```
