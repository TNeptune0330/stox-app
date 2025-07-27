import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/local_database_service.dart';

// AdMob temporarily disabled
class RevenueAdMobService {
  static const String _logPrefix = '[AdMob-DISABLED]';
  
  static Future<void> initialize() async {
    print('$_logPrefix AdMob disabled for now');
  }
  
  static Future<void> loadBannerAd() async {
    print('$_logPrefix Banner ads disabled');
  }
  
  static Future<void> loadInterstitialAd() async {
    print('$_logPrefix Interstitial ads disabled');
  }
  
  static Future<void> loadRewardedAd() async {
    print('$_logPrefix Rewarded ads disabled');
  }
  
  static void showInterstitialAd() {
    print('$_logPrefix Interstitial ads disabled');
  }
  
  static void showRewardedAd({Function? onReward}) {
    print('$_logPrefix Rewarded ads disabled');
  }
  
  static Widget createBannerAdWidget() {
    return const SizedBox.shrink(); // No ads
  }
  
  static Map<String, dynamic> getAdStats() {
    return {
      'status': 'disabled',
      'banner_loaded': false,
      'interstitial_loaded': false,
      'rewarded_loaded': false,
    };
  }
  
  static void dispose() {
    print('$_logPrefix AdMob disabled - nothing to dispose');
  }
  
  // Additional stub methods for compatibility
  static Widget? getBannerAd() {
    return null; // Return null since ads are disabled
  }
  
  static bool get isBannerAdLoaded => false;
  static bool get isInterstitialAdLoaded => false;
  static bool get isRewardedAdLoaded => false;
  static bool get isNativeAdLoaded => false;
  
  static Future<void> onTradeCompleted() async {
    print('$_logPrefix Trade completed event - disabled');
  }
  
  static Future<void> onScreenTransition(String screenName) async {
    print('$_logPrefix Screen transition to $screenName - disabled');
  }
}