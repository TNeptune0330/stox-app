# Stox - Stock Trading Simulator

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.io)

A modern, gamified stock trading simulator built with Flutter that provides users with a realistic trading experience using real-time market data.

## 📋 Product Requirements Document

For complete product specifications, roadmap, and technical requirements, see our comprehensive **[Product Requirements Document (PRD)](./PRD.md)**.

## ✨ Key Features

- **📈 Real-Time Trading Simulation** - Practice with live market data
- **🎮 Gamification System** - Achievements and progress tracking  
- **💎 Neon Navy Design** - Modern dark theme with smooth animations
- **📱 Cross-Platform** - iOS, Android, and Web support
- **🔒 Secure & Private** - Supabase backend with encryption
- **📚 Educational Focus** - Learn investing without financial risk

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / Xcode for mobile development
- Supabase account for backend services

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/stox-app.git
   cd stox-app/stox
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Copy `lib/config/env.example.dart` to `lib/config/env.dart`
   - Add your API keys and configuration

4. **Run the app**
   ```bash
   flutter run
   ```

## 🛠 Development

### Essential Commands
```bash
flutter pub get          # Install dependencies
flutter run              # Run in debug mode
flutter run --release    # Run in release mode
flutter build apk        # Build Android APK
flutter build ipa        # Build iOS IPA
flutter analyze          # Static analysis
flutter test             # Run tests
flutter clean            # Clean build artifacts
```

### Project Structure
```
lib/
├── config/              # API keys and configuration
├── models/              # Data models and entities
├── providers/           # State management (Provider pattern)
├── screens/             # UI screens and pages
├── services/            # Business logic and API calls
├── widgets/             # Reusable UI components
└── utils/               # Helper functions and utilities
```

## 🎨 Design System

**Neon Navy Theme**
- Primary: Electric Blue (#3B82F6)
- Background: Deep Navy (#0B1220)
- Surface: Dark Blue (#151E2E)
- Typography: Nunito font family
- Animations: Custom motion system with reduced motion support

## 📊 Architecture

- **Frontend:** Flutter with Provider state management
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **Market Data:** Finnhub API (stocks) + CoinGecko API (crypto)
- **Local Storage:** Hive for offline capabilities
- **Monetization:** AdMob integration

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

## 📱 Platform Support

- ✅ **iOS** - iPhone and iPad
- ✅ **Android** - Phones and tablets  
- ✅ **Web** - PWA capabilities
- 🔄 **Desktop** - macOS, Windows, Linux (planned)

## 🔐 Security & Privacy

- End-to-end encryption for sensitive data
- GDPR and CCPA compliance
- Secure OAuth 2.0 authentication
- No real money transactions (simulation only)
- Comprehensive privacy controls

## 📈 Roadmap

- **Q1 2025:** MVP launch with core trading features
- **Q2 2025:** Social features and advanced analytics
- **Q3 2025:** Premium subscription and monetization
- **Q4 2025:** AI insights and advanced trading tools

See the full [Development Roadmap](./PRD.md#7-development-roadmap) in our PRD.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please read our [Contributing Guidelines](./CONTRIBUTING.md) for detailed information.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🆘 Support

- 📧 **Email:** support@stox-app.com
- 📚 **Documentation:** [Full PRD](./PRD.md)
- 🐛 **Bug Reports:** [GitHub Issues](https://github.com/yourusername/stox-app/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/yourusername/stox-app/discussions)

## 📜 Disclaimers

⚠️ **Important:** Stox is a trading simulator for educational purposes only. This app does not provide financial advice and does not involve real money transactions. Past performance in simulation does not guarantee future results in real trading.

---

**Built with ❤️ by the Stox Team**
