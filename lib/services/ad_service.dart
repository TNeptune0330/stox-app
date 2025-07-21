import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import '../config/ad_config.dart';

// Temporarily disabled for iOS build issues
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  // Stub methods to maintain compatibility
  Future<void> initialize() async {
    // AdMob initialization disabled
  }

  Widget createBannerAd() {
    return Container(); // Return empty container instead of banner ad
  }
  
  void onTradeCompleted() {
    // AdMob onTradeCompleted disabled
    print('AdService: Trade completed event - disabled');
  }
}