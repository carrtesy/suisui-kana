import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob unit IDs.
///
/// Android uses the real Suisui Kana "Home Banner" unit. iOS is not configured
/// for release yet, so it still points at Google's official TEST banner.
///
/// NOTE: never tap a live ad on your own device — that is invalid traffic and
/// can get the AdMob account suspended. Register test devices (see main.dart)
/// before running debug builds against the real unit.
class AdIds {
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-2551676193232813/4450458428' // Android Home Banner (real)
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
}

/// A self-loading banner pinned to the bottom of the app. Occupies no space
/// until an ad has loaded, and quietly shows nothing if loading fails.
class BannerAdBar extends StatefulWidget {
  const BannerAdBar({super.key});

  @override
  State<BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<BannerAdBar> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _ad = null; // leave the bar empty
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
