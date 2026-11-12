import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized Advertising Configuration for Gold Calculator.
///
/// Features:
/// - [adsEnabled] defaults to false for a 100% ad-free launch experience.
/// - Test banner & interstitial IDs for Android and iOS.
/// - [preloadInterstitial] and [showPostCalculationAd] with completion callbacks.
/// - [SmartAdBannerWidget] rendering nothing when ads are disabled or unsupported.
class AdConfig {
  /// Master toggle for all advertisements in the application.
  /// Defaults to `false` for a 100% ad-free, clean launch experience.
  static bool adsEnabled = false;

  /// AdMob Standard Test IDs for Banner Ads
  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';

  /// AdMob Standard Test IDs for Interstitial Ads
  static const String androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';

  /// Returns true only on supported native mobile platforms (Android & iOS).
  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Returns true only if ads are enabled by the user/system AND running on mobile.
  static bool get isAdsActive => adsEnabled && isMobilePlatform;

  /// Banner Ad Unit ID based on current mobile platform
  static String get bannerAdUnitId {
    if (!isMobilePlatform) return '';
    return Platform.isAndroid ? androidBannerTestId : iosBannerTestId;
  }

  /// Interstitial Ad Unit ID based on current mobile platform
  static String get interstitialAdUnitId {
    if (!isMobilePlatform) return '';
    return Platform.isAndroid
        ? androidInterstitialTestId
        : iosInterstitialTestId;
  }

  static InterstitialAd? _interstitialAd;
  static bool _isLoadingInterstitial = false;
  static bool _isSdkInitialized = false;

  /// Initializes the Google Mobile Ads SDK safely if ads are enabled and active.
  static Future<void> initializeSdk() async {
    if (!isAdsActive || _isSdkInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isSdkInitialized = true;
    } catch (e) {
      debugPrint('AdMob SDK initialization error: $e');
    }
  }

  /// Preloads an interstitial ad in the background.
  /// Gracefully no-ops when ads are disabled or running on unsupported platforms.
  static void preloadInterstitial() {
    if (!isAdsActive || _isLoadingInterstitial || _interstitialAd != null) {
      return;
    }

    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Displays an interstitial ad (e.g. after a calculation), executing [onComplete]
  /// when dismissed or immediately if ads are disabled/unavailable.
  static void showPostCalculationAd({VoidCallback? onComplete}) {
    if (!isAdsActive || _interstitialAd == null) {
      onComplete?.call();
      if (isAdsActive) {
        preloadInterstitial();
      }
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;

    bool hasCompleted = false;
    void finish() {
      if (!hasCompleted) {
        hasCompleted = true;
        onComplete?.call();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish();
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        finish();
        preloadInterstitial();
      },
    );

    ad.show();
  }
}

/// Smart Banner Ad Widget that gracefully renders nothing ([SizedBox.shrink])
/// when ads are disabled ([AdConfig.adsEnabled] is false) or running on non-mobile platforms.
class SmartAdBannerWidget extends StatefulWidget {
  final AdSize adSize;

  const SmartAdBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<SmartAdBannerWidget> createState() => _SmartAdBannerWidgetState();
}

class _SmartAdBannerWidgetState extends State<SmartAdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdConfig.isAdsActive) return;

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
          debugPrint('SmartAdBannerWidget failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.isAdsActive || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
