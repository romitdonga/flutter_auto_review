// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_auto_review/flutter_auto_review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RateUsManager manager;
  late RateUsConfig config;

  setUp(() async {
    // Set up shared preferences for testing
    SharedPreferences.setMockInitialValues({});

    // Create a test configuration
    config = const RateUsConfig(
      rateUsInitialize: 1,
      minDaysSinceInstall: 1,
      minAppOpens: 3,
      minEvents: 2,
      autoTrigger: 5,
      exitTrigger: 1,
      cooldownDays: 7,
    );

    // Initialize the manager
    manager = RateUsManager();
    await manager.init(config: config);
  });

  testWidgets('RateUsManager initializes correctly', (
    WidgetTester tester,
  ) async {
    expect(manager.config.rateUsInitialize, 1);
    expect(manager.config.minDaysSinceInstall, 1);
    expect(manager.config.minAppOpens, 3);
    expect(manager.config.minEvents, 2);
    expect(manager.config.autoTrigger, 5);
    expect(manager.config.exitTrigger, 1);
    expect(manager.config.cooldownDays, 7);
  });

  testWidgets('RateUsManager can be reset', (WidgetTester tester) async {
    // Reset the manager
    await manager.reset();

    // Verify that the app opens count is reset to 1 (initial value)
    await manager.init(config: config);

    // We'd need to check the internal state, but since it's private,
    // we can test the behavior instead by triggering events
    final shouldShow = await manager.onMinAppOpens();
    expect(
      shouldShow,
      false,
    ); // Should be false because app opens is now 1, not 3
  });

  testWidgets('RateUsFallbackDialog renders correctly', (
    WidgetTester tester,
  ) async {
    // Build the dialog
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: RateUsFallbackDialog())),
      ),
    );

    // Verify that the dialog contains the expected text
    expect(find.text('Rate Our App'), findsOneWidget);
    expect(
      find.text(
        'If you enjoy using our app, would you mind taking a moment to rate it? '
        'It won\'t take more than a minute. Thanks for your support!',
      ),
      findsOneWidget,
    );
    expect(find.text('Maybe Later'), findsOneWidget);
    expect(find.text('Rate Now'), findsOneWidget);
  });

  testWidgets('RateUsConfig can be created from map', (
    WidgetTester tester,
  ) async {
    final map = {
      'rateUS_initialize': 0,
      'rate_days_since_install': 10,
      'rate_min_opens': 20,
      'rate_min_events': 30,
      'rate_auto_trigger': 40,
      'rate_exit': 1,
      'rate_cooldown_days': 50,
      'app_store_id': 'test123',
    };

    final config = RateUsConfig.fromMap(map);

    expect(config.rateUsInitialize, 0);
    expect(config.minDaysSinceInstall, 10);
    expect(config.minAppOpens, 20);
    expect(config.minEvents, 30);
    expect(config.autoTrigger, 40);
    expect(config.exitTrigger, 1);
    expect(config.cooldownDays, 50);
    expect(config.appStoreId, 'test123');
  });

  testWidgets('RateUsConfig has correct default values', (
    WidgetTester tester,
  ) async {
    final defaultConfig = const RateUsConfig();

    expect(defaultConfig.rateUsInitialize, 1);
    expect(defaultConfig.minDaysSinceInstall, 3);
    expect(defaultConfig.minAppOpens, 5);
    expect(defaultConfig.minEvents, 3);
    expect(defaultConfig.autoTrigger, 10);
    expect(defaultConfig.exitTrigger, 0);
    expect(defaultConfig.cooldownDays, 30);
    expect(defaultConfig.appStoreId, null);
  });

  testWidgets('RateUsAnalytics logs events correctly', (
    WidgetTester tester,
  ) async {
    final events = <String>[];
    final params = <Map<String, dynamic>>[];

    final analytics = RateUsAnalytics(
      onEvent: (String eventName, Map<String, dynamic> parameters) {
        events.add(eventName);
        params.add(parameters);
      },
    );

    analytics.logDialogShown();
    analytics.logRated();
    analytics.logDismissed();
    analytics.logStoreRedirect();
    analytics.logFallbackShown();
    analytics.logTriggerCondition('test_trigger');

    expect(events, [
      'rate_us_dialog_shown',
      'rate_us_rated',
      'rate_us_dismissed',
      'rate_us_store_redirect',
      'rate_us_fallback_shown',
      'rate_us_trigger',
    ]);

    expect(params[5]['trigger_type'], 'test_trigger');
  });
}
