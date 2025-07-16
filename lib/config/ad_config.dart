class AdConfig {
  // Test ad IDs for development
  static const String testBannerAdId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testNativeAdId = 'ca-app-pub-3940256099942544/2247696110';
  
  // Production ad IDs - replace with your actual AdMob ad unit IDs
  static const String prodBannerAdId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodInterstitialAdId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodRewardedAdId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String prodNativeAdId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  
  // Use test ads in debug mode, production ads in release mode
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
  
  static String get bannerAdId => isDebugMode ? testBannerAdId : prodBannerAdId;
  static String get interstitialAdId => isDebugMode ? testInterstitialAdId : prodInterstitialAdId;
  static String get rewardedAdId => isDebugMode ? testRewardedAdId : prodRewardedAdId;
  static String get nativeAdId => isDebugMode ? testNativeAdId : prodNativeAdId;
  
  // AdMob App IDs
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';
}