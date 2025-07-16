import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.instance.createBannerAd();
    _bannerAd!.load().then((_) {
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border.all(
          color: const Color(0xFF533483),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = AdService.instance.createNativeAd();
    _nativeAd!.load().then((_) {
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF533483),
          width: 1,
        ),
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

class RewardedAdButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRewardEarned;
  final IconData icon;

  const RewardedAdButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRewardEarned,
    this.icon = Icons.card_giftcard,
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _isWatching = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          widget.icon,
          color: const Color(0xFFf39c12),
          size: 32,
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          widget.subtitle,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        trailing: _isWatching
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF533483)),
                ),
              )
            : ElevatedButton(
                onPressed: AdService.instance.isRewardedAdAvailable
                    ? _watchRewardedAd
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF533483),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Watch'),
              ),
      ),
    );
  }

  void _watchRewardedAd() async {
    setState(() {
      _isWatching = true;
    });

    try {
      await AdService.instance.showRewardedAd(
        onRewardEarned: () {
          widget.onRewardEarned();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reward earned! 🎉'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          }
        },
        onAdClosed: () {
          if (mounted) {
            setState(() {
              _isWatching = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWatching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to show ad: $e'),
            backgroundColor: const Color(0xFFf44336),
          ),
        );
      }
    }
  }
}