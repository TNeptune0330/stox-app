# Stox App Setup Instructions

## Required Configuration

### 1. Google Sign-In Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials for:
   - Web client (for Supabase)
   - Android client
   - iOS client
5. Update `lib/config/api_keys.dart` with your client IDs

### 2. Supabase Configuration
1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Create a new project
3. Your URL and anon key are already configured in `lib/config/env.dart`
4. Run the database schema from the main README

### 3. AdMob Configuration
- Test ad IDs are already configured
- For production, replace test IDs in `lib/config/ad_config.dart`

### 4. API Keys for Market Data
1. Get Finnhub API key from [finnhub.io](https://finnhub.io/)
2. Get CoinGecko API key from [coingecko.com](https://www.coingecko.com/en/api)
3. Update `lib/config/api_keys.dart`

## Running the App

1. `flutter pub get`
2. `flutter run`

## Known Issues

- Google Sign-In requires proper OAuth configuration
- Market data APIs require valid API keys
- AdMob works with test IDs in development

## App Features

✅ **Working Features:**
- App initialization and navigation
- AdMob integration (test ads)
- Supabase connection
- Material 3 theming
- State management with Provider

⚠️ **Requires Configuration:**
- Google Sign-In (OAuth setup needed)
- Live market data (API keys needed)
- Production ads (real AdMob IDs needed)

## Testing

The app will run with placeholder data when APIs are not configured. You can test:
- UI navigation
- Theme switching
- Ad integration
- Basic app flow

Configure the APIs above for full functionality.