# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Essential Commands
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app (debug mode)
- `flutter run --release` - Run the app (release mode)
- `flutter build apk` - Build Android APK
- `flutter build ipa` - Build iOS IPA (requires iOS development setup)
- `flutter analyze` - Static analysis and linting
- `flutter test` - Run unit tests
- `flutter clean` - Clean build artifacts

### Git Repository Management
**IMPORTANT**: After every change to the codebase, the entire git repository should be updated with proper commit messages. This ensures:
- All changes are tracked and versioned
- Collaboration is seamless
- Rollback capability is maintained
- Development history is preserved

Use: `git add .` followed by `git commit -m "descriptive message"` after any code modifications.

### Platform-Specific Commands
- `flutter run -d chrome` - Run on Chrome (web)
- `flutter run -d android` - Run on Android device/emulator
- `flutter run -d ios` - Run on iOS device/simulator

## Project Architecture

### Core Structure
This is a Flutter stock trading simulator app with the following architecture:

**State Management**: Provider pattern with ChangeNotifier
- `AuthProvider` - User authentication state
- `PortfolioProvider` - User portfolio and holdings
- `MarketDataProvider` - Real-time market data
- `ThemeProvider` - App theming and customization
- `AchievementProvider` - User achievements and gamification

**Data Layer**:
- `LocalDatabaseService` - Local SQLite database via Hive
- `EnhancedMarketDataService` - Primary market data service with caching
- `StorageService` - Local storage and preferences
- `SupabaseClient` - Backend database and authentication

**Key Services**:
- `RevenueAdMobService` - AdMob integration for monetization
- `ConnectionManager` - Network connectivity management
- `LocalTradingService` - Offline trading capabilities
- `ComprehensiveTestService` - Production testing suite

### Application Flow
1. **App Initialization** (`main.dart`):
   - Initializes Supabase, local database, market data service
   - Sets up AdMob and starts periodic market updates
   - Runs comprehensive tests in debug mode

2. **Authentication Flow**:
   - Google Sign-In integration via `AuthProvider`
   - Supabase authentication backend
   - Offline capability with local storage fallback

3. **Main Navigation** (`screens/main_navigation.dart`):
   - Bottom navigation with 4 tabs: Market, Portfolio, Achievements, Settings
   - IndexedStack for tab state preservation
   - Banner ads integrated at bottom

4. **Market Data**:
   - Real-time data from Finnhub API
   - Local caching for offline functionality
   - Periodic updates every 30 seconds
   - Fallback to cached data when offline

### Key Configuration Files
- `lib/config/api_keys.dart` - API keys for external services
- `lib/config/supabase_config.dart` - Supabase connection settings
- `lib/config/ad_config.dart` - AdMob configuration
- `lib/config/env.dart` - Environment-specific settings

### Important Implementation Details

**Offline-First Architecture**:
The app is designed to work offline with local trading capabilities. All market data is cached locally and trading operations can function without network connectivity.

**Testing Integration**:
The app includes a comprehensive testing service that runs on startup in debug mode, validating database connections, market data services, and core functionality.

**Multi-Platform Support**:
Configured for iOS, Android, Web, macOS, Windows, and Linux with platform-specific optimizations.

**AdMob Integration**:
Banner ads are integrated throughout the app using `BannerAdWidget` with proper lifecycle management.

### Development Notes

**API Configuration Required**:
- Google Sign-In requires OAuth 2.0 setup
- Finnhub API key needed for live market data
- CoinGecko API key for cryptocurrency data
- Supabase project configuration

**Database Schema**:
Uses Supabase backend with local SQLite caching. Schema defined in `supabase_schema.sql`.

**Theme System**:
Material 3 theming with custom color schemes and dark mode support. Theme persistence via local storage.

**Error Handling**:
Comprehensive error handling with offline fallbacks and user-friendly error states throughout the app.

### Testing
- Unit tests in `test/` directory
- Widget tests using Flutter testing framework
- Integration tests via `ComprehensiveTestService`
- Manual testing workflows documented in `SETUP_INSTRUCTIONS.md`

### Debugging
- Debug prints throughout services for development
- Error logging to console
- Network connectivity monitoring
- Market data update monitoring