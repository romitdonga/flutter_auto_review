import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../flutter_auto_review.dart';

class RateUsManager {
  final RateUsConfig config;
  final StorageRepository storage;
  final RateUsAnalytics analytics;
  final InAppReview _inAppReview = InAppReview.instance;

  RateUsManager._(this.config, this.storage, this.analytics);

  static Future<RateUsManager> init({
    RateUsConfig? config,
    required StorageRepository storage,
    RateUsAnalytics? analytics,
  }) async {
    final cfg = config ?? const RateUsConfig();
    final an = analytics ?? RateUsAnalytics();
    return RateUsManager._(cfg, storage, an);
  }

  /// Call on app open to increment counters if you use minAppOpens flow
  Future<void> onAppOpen() async {
    await storage.incrementAppOpens();
    analytics.log('rate_us_app_open', {'app_opens': storage.appOpens});
  }

  /// Main entry: call this whenever you want to evaluate showing rating prompt.
  Future<void> tryShowRateDialog(
    BuildContext context, {
    bool manual = false,
  }) async {
    if (config.rateUsInitialize == 0) {
      analytics.log('rate_us_blocked', {'reason': 'disabled'});
      return;
    }

    // Manual triggers (from settings) should prefer native and bypass cooldown
    if (manual) {
      analytics.log('rate_us_manual_trigger', {});
      await _attemptNative(context, force: true);
      return;
    }

    // If user already submitted via custom, prefer native only branch
    if (storage.assumedRatedCustom) {
      analytics.log('rate_us_already_custom', {});
      await _attemptNative(context);
      return;
    }

    // If in cooldown for custom dismiss, do native branch (custom blocked)
    final lastCancel = storage.lastCustomCancel;
    if (lastCancel != null) {
      final diff = DateTime.now().difference(lastCancel).inDays;
      if (diff < config.cooldownDays) {
        analytics.log('rate_us_in_cooldown', {
          'days_left': config.cooldownDays - diff,
        });
        await _attemptNative(context);
        return;
      }
    }

    // If native not yet called today -> call native
    if (!storage.nativeCalledToday()) {
      await _attemptNative(context);
      return;
    }

    // else show custom dialog branch
    await _showCustomDialog(context);
  }

  Future<void> _attemptNative(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!force && storage.nativeCalledToday()) {
      analytics.log('rate_us_native_skipped_already_today', {});
      return;
    }

    try {
      analytics.log('rate_us_native_attempt', {});
      final available = await _inAppReview.isAvailable();
      if (available) {
        await _inAppReview.requestReview();
        await storage.setNativeCalledDate(DateTime.now().toIso8601String());
        analytics.log('rate_us_trigger', {'via': 'native', 'available': true});
        return;
      } else {
        analytics.log('rate_us_native_unavailable', {});
      }
    } catch (e, st) {
      analytics.log('rate_us_native_error', {'error': e.toString()});
    }

    // fallback to custom if native can't run
    await _showCustomDialog(context);
  }

  Future<void> _showCustomDialog(BuildContext context) async {
    analytics.log('rate_us_fallback_shown', {
      'count': storage.customShownCount,
    });
    await storage.incrementCustomShown();
    final result = await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const RateUsFallbackDialog(),
    );
    if (result == null) {
      // treat as cancel
      await storage.setLastCustomCancel(DateTime.now());
      analytics.log('rate_us_fallback_dismiss', {});
      return;
    }
    final action = result['action'] as String? ?? 'cancel';
    if (action == 'cancel') {
      await storage.setLastCustomCancel(DateTime.now());
      analytics.log('rate_us_fallback_cancel', {});
      return;
    } else if (action == 'submit') {
      final stars = result['stars'] as int? ?? 5;
      final comment = result['comment'] as String? ?? '';
      analytics.log('rate_us_fallback_submit', {
        'stars': stars,
        'comment': comment,
      });
      // assume user will rate on Play Store; mark flag to avoid future custom prompts
      await storage.setAssumedRatedCustom(true);
      // launch store (use simple url launcher)
      await _openStorePage();
      return;
    }
  }

  Future<void> _openStorePage() async {
    try {
      if (Platform.isIOS && config.appStoreId != null) {
        final url = 'https://apps.apple.com/app/id${config.appStoreId}';
        await _launchUrl(url);
      } else if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        final url =
            'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
        await _launchUrl(url);
      } else {
        await _inAppReview.openStoreListing(appStoreId: config.appStoreId);
      }
      analytics.logStoreRedirect();
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    }
  }

  /// Launch a URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
