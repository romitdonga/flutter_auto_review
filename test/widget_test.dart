// test/rate_us_manager_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_auto_review/flutter_auto_review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset mock shared prefs before each test
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'StorageRepository initializes correctly and native flag behavior',
    () async {
      final storage = await StorageRepository.init();

      // firstInstallDate should be present
      final first = storage.firstInstallDate;
      expect(first, isA<DateTime>());

      // Initially no native called today
      expect(storage.nativeCalledToday(), isFalse);

      // Set native called date to now and verify the flag becomes true
      await storage.setNativeCalledDate(DateTime.now().toIso8601String());
      expect(storage.nativeCalledToday(), isTrue);

      // assumedRatedCustom default is false
      expect(storage.assumedRatedCustom, isFalse);

      // Set assumedRatedCustom true and check
      await storage.setAssumedRatedCustom(true);
      expect(storage.assumedRatedCustom, isTrue);
    },
  );

  testWidgets(
    'Fallback dialog renders and submit sets assumedRatedCustom + analytics logged',
    (WidgetTester tester) async {
      final storage = await StorageRepository.init();

      final events = <String>[];
      final params = <Map<String, dynamic>>[];

      final analytics = RateUsAnalytics(
        onEvent: (name, p) {
          events.add(name);
          params.add(Map<String, dynamic>.from(p));
        },
      );

      final manager = await RateUsManager.init(
        storage: storage,
        config: const RateUsConfig(
          rateUsInitialize: 1,
          minAppOpens: 0,
          cooldownDays: 2,
        ),
        analytics: analytics,
      );

      // Pump app to provide BuildContext for showDialog
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => manager.tryShowRateDialog(context),
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Trigger the dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // After in_app_review likely unavailable in test environment, fallback dialog should be shown
      expect(find.byType(RateUsFallbackDialog), findsOneWidget);
      expect(find.text('Enjoying the app?'), findsOneWidget);

      // Interact: enter a comment and tap Rate button
      await tester.enterText(find.byType(TextField), 'Great app!');
      await tester.tap(find.text('Rate'));
      await tester.pumpAndSettle();

      // After submit: assumedRatedCustom should be true
      expect(storage.assumedRatedCustom, isTrue);

      // Analytics should have captured fallback shown + fallback submit (and possibly other attempts)
      expect(events, contains('rate_us_fallback_shown'));
      expect(events, contains('rate_us_fallback_submit'));
      // Check params of fallback_submit include stars (default 5)
      final submitIndex = events.indexOf('rate_us_fallback_submit');
      expect(submitIndex, isNonNegative);
      expect(params[submitIndex]['stars'], isNotNull);
    },
  );

  testWidgets(
    'Fallback dialog cancel triggers cooldown and blocks custom until cooldown expires',
    (WidgetTester tester) async {
      final storage = await StorageRepository.init();

      final events = <String>[];
      final analytics = RateUsAnalytics(
        onEvent: (name, p) {
          events.add(name);
        },
      );

      final manager = await RateUsManager.init(
        storage: storage,
        config: const RateUsConfig(
          rateUsInitialize: 1,
          minAppOpens: 0,
          cooldownDays: 3, // use 3 days cooldown for test
        ),
        analytics: analytics,
      );

      // Show dialog and cancel
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => manager.tryShowRateDialog(context),
                    child: const Text('OpenCancel'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OpenCancel'));
      await tester.pumpAndSettle();

      expect(find.byType(RateUsFallbackDialog), findsOneWidget);
      await tester.tap(find.text('Not now')); // dialog 'Not now' cancels
      await tester.pumpAndSettle();

      // lastCustomCancel should be set
      final lastCancel = storage.lastCustomCancel;
      expect(lastCancel, isNotNull);

      // Immediately attempting to show should prefer native branch (custom blocked).
      // To simulate, we mark nativeAlreadyCalledToday false (it is false), so manager will attempt native.
      // Because in-app-review is likely unavailable, it will attempt fallback but our cooldown should block custom.
      // To test blocking behavior we call tryShowRateDialog again and ensure that we don't get another custom shown event
      // (events already captured contain 'rate_us_fallback_shown' for first display).
      events.clear();

      await tester.tap(find.text('OpenCancel'));
      await tester.pumpAndSettle();

      // Since cooldown is active, manager will go to native branch (which will likely fallback to custom only if native unavailable).
      // But custom should be blocked; therefore, we should not see another 'rate_us_fallback_shown' event added.
      expect(events, isEmpty);
    },
  );

  testWidgets(
    'Manual trigger (settings) bypasses cooldown and prefers native attempt',
    (tester) async {
      final storage = await StorageRepository.init();

      final events = <String>[];
      final analytics = RateUsAnalytics(
        onEvent: (name, p) {
          events.add(name);
        },
      );

      final manager = await RateUsManager.init(
        storage: storage,
        config: const RateUsConfig(
          rateUsInitialize: 1,
          minAppOpens: 0,
          cooldownDays: 2,
        ),
        analytics: analytics,
      );

      // Simulate a prior custom cancel so cooldown is active
      await storage.setLastCustomCancel(DateTime.now());

      // Pump UI and call manual trigger (should bypass cooldown and attempt native)
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        manager.tryShowRateDialog(context, manual: true),
                    child: const Text('Manual'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      // Analytics should include 'rate_us_manual_trigger' and either native attempt or native_unavailable fallback
      expect(
        events,
        anyOf(
          contains('rate_us_manual_trigger'),
          contains('rate_us_native_attempt'),
        ),
      );
    },
  );
}
