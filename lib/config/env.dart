class Environment {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // API Keys
  static const String finnhubApiKey =
      'd1raaj1r01qk8n65pv5gd1raaj1r01qk8n65pv60';
  static const String coinGeckoApiKey =
      'CG-cgs7H2zjz6Kks7kdN9JsTTcx'; // Optional - free tier available

  // Google OAuth
  static const String googleClientId =
      '264305191086-ruelf34qlbnngfubd7m52418hta9c3oh.apps.googleusercontent.com';

  // App Configuration
  static const String appName = 'Stox';
  static const String appVersion = '1.0.0';
  static const double initialCashBalance = 10000.00;

  // API Endpoints
  static const String coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';
}
