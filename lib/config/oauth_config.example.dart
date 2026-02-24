/// OAuth 2.0 credentials for Google Calendar API.
///
/// To configure:
/// 1. Go to https://console.cloud.google.com/
/// 2. Create a project (or select an existing one)
/// 3. Enable the Google Calendar API
/// 4. Go to Credentials → Create Credentials → OAuth 2.0 Client ID
/// 5. Select "Desktop app" as the application type
/// 6. Copy this file to `oauth_config.dart` (same directory)
/// 7. Replace the placeholder values below with your actual credentials
///
/// IMPORTANT: `oauth_config.dart` is gitignored — never commit real credentials.
const String oauthClientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
const String oauthClientSecret = 'YOUR_CLIENT_SECRET';
