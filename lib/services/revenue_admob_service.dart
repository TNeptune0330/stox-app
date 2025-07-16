import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/local_database_service.dart';

class RevenueAdMobService {
  static const String _logPrefix = '[AdMob-Revenue]';
  
  // Ad Unit IDs - Replace with your actual AdMob IDs for production
  static String get _bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Test ID
      : 'ca-app-pub-3940256099942544/2934735716'; // Test ID
  
  static String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Test ID
      : 'ca-app-pub-3940256099942544/4411468910'; // Test ID
  
  static String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917' // Test ID
      : 'ca-app-pub-3940256099942544/1712485313'; // Test ID
  
  static String get _nativeAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110' // Test ID
      : 'ca-app-pub-3940256099942544/3986624511'; // Test ID
  
  // Ad instances
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static NativeAd? _nativeAd;
  
  // Ad loading states
  static bool _isBannerAdLoaded = false;
  static bool _isInterstitialAdLoaded = false;
  static bool _isRewardedAdLoaded = false;
  static bool _isNativeAdLoaded = false;
  
  // Revenue optimization
  static int _sessionLength = 0;
  static int _totalTrades = 0;
  static int _adsShown = 0;
  static double _totalRevenue = 0.0;
  static DateTime _sessionStartTime = DateTime.now();
  
  // User engagement tracking
  static const int _minSessionTimeForInterstitial = 30; // seconds
  static const int _minTradesForRewarded = 3;
  static const int _maxAdsPerSession = 8;
  
  static Future<void> initialize() async {
    try {
      print('$_logPrefix 🎯 Initializing AdMob with revenue optimization...');
      
      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      // Set request configuration for better targeting
      final requestConfiguration = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        maxAdContentRating: MaxAdContentRating.t,
      );
      
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      
      // Load all ad types
      await Future.wait([
        _loadBannerAd(),
        _loadInterstitialAd(),
        _loadRewardedAd(),
        _loadNativeAd(),
      ]);
      
      // Start session tracking
      _sessionStartTime = DateTime.now();
      _startSessionTracking();
      
      print('$_logPrefix ✅ AdMob initialized successfully');
    } catch (e) {
      print('$_logPrefix ❌ AdMob initialization failed: $e');
    }
  }
  
  // Banner Ad Management
  static Future<void> _loadBannerAd() async {
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('$_logPrefix ✅ Banner ad loaded');
            _isBannerAdLoaded = true;
            _trackAdRevenue('banner', 0.02); // Estimated CPM
          },
          onAdFailedToLoad: (ad, error) {
            print('$_logPrefix ❌ Banner ad failed to load: $error');
            _isBannerAdLoaded = false;
            ad.dispose();
            // Retry after delay
            Future.delayed(const Duration(seconds: 30), _loadBannerAd);
          },
          onAdOpened: (ad) {
            print('$_logPrefix 👆 Banner ad opened');
            _trackAdInteraction('banner', 'click');
          },
        ),
      );
      
      await _bannerAd!.load();
    } catch (e) {
      print('$_logPrefix ❌ Banner ad loading error: $e');
    }
  }
  
  static BannerAd? getBannerAd() {
    return _isBannerAdLoaded ? _bannerAd : null;
  }
  
  // Interstitial Ad Management
  static Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            print('$_logPrefix ✅ Interstitial ad loaded');
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('$_logPrefix ✅ Interstitial ad dismissed');
                _trackAdRevenue('interstitial', 0.50); // Estimated eCPM
                ad.dispose();
                _isInterstitialAdLoaded = false;
                // Preload next ad
                Future.delayed(const Duration(seconds: 5), _loadInterstitialAd);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('$_logPrefix ❌ Interstitial ad failed to show: $error');
                ad.dispose();
                _isInterstitialAdLoaded = false;
                Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('$_logPrefix ❌ Interstitial ad failed to load: $error');
            _isInterstitialAdLoaded = false;
            // Retry after delay
            Future.delayed(const Duration(seconds: 60), _loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      print('$_logPrefix ❌ Interstitial ad loading error: $e');
    }
  }
  
  static Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      print('$_logPrefix ❌ Interstitial ad not ready');
      return false;
    }
    
    // Check if user is ready for interstitial (engagement-based)
    if (!_shouldShowInterstitial()) {
      print('$_logPrefix ⏰ User not ready for interstitial yet');
      return false;
    }
    
    try {
      await _interstitialAd!.show();
      _adsShown++;
      print('$_logPrefix ✅ Interstitial ad shown successfully');
      return true;
    } catch (e) {
      print('$_logPrefix ❌ Error showing interstitial ad: $e');
      return false;
    }
  }
  
  // Rewarded Ad Management
  static Future<void> _loadRewardedAd() async {
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('$_logPrefix ✅ Rewarded ad loaded');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('$_logPrefix ✅ Rewarded ad dismissed');
                ad.dispose();
                _isRewardedAdLoaded = false;
                // Preload next ad
                Future.delayed(const Duration(seconds: 5), _loadRewardedAd);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('$_logPrefix ❌ Rewarded ad failed to show: $error');
                ad.dispose();
                _isRewardedAdLoaded = false;
                Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('$_logPrefix ❌ Rewarded ad failed to load: $error');
            _isRewardedAdLoaded = false;
            Future.delayed(const Duration(seconds: 60), _loadRewardedAd);
          },
        ),
      );
    } catch (e) {
      print('$_logPrefix ❌ Rewarded ad loading error: $e');
    }
  }
  
  static Future<bool> showRewardedAd({
    required Function(double reward) onReward,
    Function()? onAdClosed,
  }) async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      print('$_logPrefix ❌ Rewarded ad not ready');
      return false;
    }
    
    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('$_logPrefix 🎁 User earned reward: ${reward.amount} ${reward.type}');
          _trackAdRevenue('rewarded', 1.00); // Higher eCPM for rewarded ads
          _grantReward(reward.amount.toDouble());
          onReward(reward.amount.toDouble());
        },
      );
      
      _adsShown++;
      if (onAdClosed != null) onAdClosed();
      print('$_logPrefix ✅ Rewarded ad shown successfully');
      return true;
    } catch (e) {
      print('$_logPrefix ❌ Error showing rewarded ad: $e');
      return false;
    }
  }
  
  // Native Ad Management
  static Future<void> _loadNativeAd() async {
    try {
      _nativeAd = NativeAd(
        adUnitId: _nativeAdUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            print('$_logPrefix ✅ Native ad loaded');
            _isNativeAdLoaded = true;
            _trackAdRevenue('native', 0.35); // Estimated eCPM
          },
          onAdFailedToLoad: (ad, error) {
            print('$_logPrefix ❌ Native ad failed to load: $error');
            _isNativeAdLoaded = false;
            ad.dispose();
            Future.delayed(const Duration(seconds: 45), _loadNativeAd);
          },
          onAdOpened: (ad) {
            print('$_logPrefix 👆 Native ad opened');
            _trackAdInteraction('native', 'click');
          },
        ),
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: const Color(0xFF1a1a2e),
          cornerRadius: 10.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: const Color(0xFF7209b7),
            style: NativeTemplateFontStyle.monospace,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white70,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.italic,
            size: 14.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white60,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 12.0,
          ),
        ),
      );
      
      await _nativeAd!.load();
    } catch (e) {
      print('$_logPrefix ❌ Native ad loading error: $e');
    }
  }
  
  static NativeAd? getNativeAd() {
    return _isNativeAdLoaded ? _nativeAd : null;
  }
  
  // Smart Ad Triggering
  static Future<void> onTradeCompleted() async {
    _totalTrades++;
    print('$_logPrefix 📊 Trade completed. Total trades: $_totalTrades');
    
    // Show interstitial after every 3-5 trades (randomized)
    final random = Random();
    final tradesThreshold = 3 + random.nextInt(3);
    
    if (_totalTrades % tradesThreshold == 0) {
      await Future.delayed(const Duration(seconds: 1));
      await showInterstitialAd();
    }
  }
  
  static Future<void> onScreenTransition(String screenName) async {
    print('$_logPrefix 🔄 Screen transition: $screenName');
    
    // Show interstitial on specific high-value screens
    if (['portfolio', 'leaderboard', 'settings'].contains(screenName)) {
      final random = Random();
      if (random.nextDouble() < 0.3) { // 30% chance
        await Future.delayed(const Duration(milliseconds: 500));
        await showInterstitialAd();
      }
    }
  }
  
  static Future<void> onAppPause() async {
    print('$_logPrefix ⏸️ App paused');
    // Show interstitial when user returns (if session is long enough)
    if (_getSessionLength() > 60) {
      await showInterstitialAd();
    }
  }
  
  static Future<void> onLowCashBalance() async {
    print('$_logPrefix 💰 Low cash balance detected');
    // Offer rewarded ad for bonus cash
    if (_isRewardedAdLoaded) {
      // This would trigger a dialog offering bonus cash
      await showRewardedAd(
        onReward: (reward) {
          final bonusCash = reward * 100; // $100 per reward point
          _grantBonusCash(bonusCash);
        },
      );
    }
  }
  
  // Revenue Optimization
  static void _trackAdRevenue(String adType, double estimatedRevenue) {
    _totalRevenue += estimatedRevenue;
    LocalDatabaseService.saveSetting('total_ad_revenue', _totalRevenue);
    
    print('$_logPrefix 💰 Ad revenue: $adType earned \$${estimatedRevenue.toStringAsFixed(3)}');
    print('$_logPrefix 💰 Total session revenue: \$${_totalRevenue.toStringAsFixed(3)}');
  }
  
  static void _trackAdInteraction(String adType, String interaction) {
    final interactions = LocalDatabaseService.getSetting<int>('${adType}_${interaction}_count') ?? 0;
    LocalDatabaseService.saveSetting('${adType}_${interaction}_count', interactions + 1);
    
    print('$_logPrefix 👆 Ad interaction: $adType $interaction');
  }
  
  static bool _shouldShowInterstitial() {
    // Don't show too many ads in one session
    if (_adsShown >= _maxAdsPerSession) {
      return false;
    }
    
    // Ensure minimum session time
    if (_getSessionLength() < _minSessionTimeForInterstitial) {
      return false;
    }
    
    // Ensure minimum time between interstitials
    final lastInterstitialTime = LocalDatabaseService.getSetting<int>('last_interstitial_time') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastInterstitialTime < 120000) { // 2 minutes
      return false;
    }
    
    LocalDatabaseService.saveSetting('last_interstitial_time', currentTime);
    return true;
  }
  
  static int _getSessionLength() {
    return DateTime.now().difference(_sessionStartTime).inSeconds;
  }
  
  static void _grantReward(double rewardAmount) {
    // Grant in-game currency or other rewards
    final bonusCash = rewardAmount * 50; // $50 per reward point
    _grantBonusCash(bonusCash);
  }
  
  static void _grantBonusCash(double amount) {
    final user = LocalDatabaseService.getCurrentUser();
    if (user != null) {
      LocalDatabaseService.updateUserCashBalance(user.cashBalance + amount);
      print('$_logPrefix 🎁 Granted \$${amount.toStringAsFixed(2)} bonus cash');
    }
  }
  
  static void _startSessionTracking() {
    // Track session length every minute
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      _sessionLength = _getSessionLength();
      LocalDatabaseService.saveSetting('session_length', _sessionLength);
    });
  }
  
  // Public API
  static bool get isBannerAdLoaded => _isBannerAdLoaded;
  static bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  static bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  static bool get isNativeAdLoaded => _isNativeAdLoaded;
  
  static Map<String, dynamic> getAdStats() {
    return {
      'ads_shown': _adsShown,
      'total_trades': _totalTrades,
      'session_length': _sessionLength,
      'total_revenue': _totalRevenue,
      'banner_loaded': _isBannerAdLoaded,
      'interstitial_loaded': _isInterstitialAdLoaded,
      'rewarded_loaded': _isRewardedAdLoaded,
      'native_loaded': _isNativeAdLoaded,
    };
  }
  
  static Future<void> dispose() async {
    print('$_logPrefix 🧹 Disposing AdMob service...');
    
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    
    // Save final stats
    await LocalDatabaseService.saveSetting('final_session_revenue', _totalRevenue);
    await LocalDatabaseService.saveSetting('final_session_ads', _adsShown);
    
    print('$_logPrefix ✅ AdMob service disposed');
  }
}