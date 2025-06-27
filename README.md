# Flutter Auto Review

A lightweight, cross-platform SDK for intelligently prompting users to review your Flutter app at the right moment.

## Features

- ✅ **Native Dialog**: Uses `in_app_review` for system dialog
- ✅ **Auto Triggers**: Based on app opens, install days, core actions, exit
- ✅ **Manual Trigger**: Button press (e.g., from settings)
- ✅ **Smart Cooldown**: Remembers if user rated or dismissed
- ✅ **Persistent Storage**: Via shared_preferences
- ✅ **Cross-platform**: Android + iOS support
- ✅ **Lightweight & Reusable**: Minimal boilerplate
- ✅ **Custom Config**: You set min days/app opens/cooldown
- ✅ **Firebase Config Support**: Update trigger rules remotely
- ⭐ **Custom URL launcher**: If system dialog fails or is unavailable
- 📊 **Analytics**: Log user interaction for A/B testing

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_auto_review: ^1.0.0
```

## Basic Usage

### Initialize

Initialize the SDK in your app's `main.dart`:

```dart
import 'package:flutter_auto_review/flutter_auto_review.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with default config
  await RateUsManager().init(
    config: const RateUsConfig(
      rateUsInitialize: 1, // 1 = enabled, 0 = disabled
      minDaysSinceInstall: 3,
      minAppOpens: 5,
      minEvents: 3,
      autoTrigger: 10,
      exitTrigger: 0, // 1 = enabled, 0 = disabled
      cooldownDays: 30,
      appStoreId: 'YOUR_APP_STORE_ID', // For iOS fallback
    ),
  );
  
  runApp(const MyApp());
}
```

### Auto-Trigger Events

Add these to your app to automatically trigger the review dialog at the right moment:

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final RateUsManager _rateUsManager = RateUsManager();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check for app opens trigger
    _checkRateDialog();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App exit trigger
      _rateUsManager.onAppExit(context);
    }
  }
  
  Future<void> _checkRateDialog() async {
    // App opens trigger
    final shouldShow = await _rateUsManager.onMinAppOpens();
    if (shouldShow) {
      _rateUsManager.showRateDialog(context);
    }
  }
  
  // For custom events (e.g., user completes a core action)
  void _onCoreActionCompleted() async {
    final shouldShow = await _rateUsManager.onCustomEvent();
    if (shouldShow) {
      _rateUsManager.showRateDialog(context);
    }
  }
  
  // For screen transitions
  void _onScreenTransition() async {
    final shouldShow = await _rateUsManager.onAutoTrigger();
    if (shouldShow) {
      _rateUsManager.showRateDialog(context);
    }
  }
}
```

### Manual Trigger

Add a button in your settings or another appropriate place:

```dart
ElevatedButton(
  onPressed: () => RateUsManager().onSettingsTrigger(context),
  child: const Text('Rate Our App'),
)
```

## Firebase Remote Config Integration

To use Firebase Remote Config, first set up Firebase in your app, then update the SDK initialization:

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

// Get remote config values
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();

// Create config map from remote config
final configMap = {
  'rateUS_initialize': remoteConfig.getInt('rateUS_initialize'),
  'rate_days_since_install': remoteConfig.getInt('rate_days_since_install'),
  'rate_min_opens': remoteConfig.getInt('rate_min_opens'),
  'rate_min_events': remoteConfig.getInt('rate_min_events'),
  'rate_auto_trigger': remoteConfig.getInt('rate_auto_trigger'),
  'rate_exit': remoteConfig.getInt('rate_exit'),
  'rate_cooldown_days': remoteConfig.getInt('rate_cooldown_days'),
  'app_store_id': remoteConfig.getString('app_store_id'),
};

// Initialize with remote config
await RateUsManager().init(
  config: RateUsConfig.fromMap(configMap),
);
```

## Analytics Integration

Add analytics to track user interactions:

```dart
await RateUsManager().init(
  config: const RateUsConfig(/* ... */),
  analytics: RateUsAnalytics(
    onEvent: (String eventName, Map<String, dynamic> parameters) {
      // Send to your analytics provider (Firebase Analytics, Amplitude, etc.)
      FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: parameters,
      );
    },
  ),
);
```

## Configuration Options

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `rateUsInitialize` | int | Master switch (1=on, 0=off) | 1 |
| `minDaysSinceInstall` | int | Min days since install | 3 |
| `minAppOpens` | int | App opens before triggering | 5 |
| `minEvents` | int | Custom events before triggering | 3 |
| `autoTrigger` | int | Screen transitions before triggering | 10 |
| `exitTrigger` | int | Show on exit (1=yes, 0=no) | 0 |
| `cooldownDays` | int | Days to wait after dismissal | 30 |
| `appStoreId` | String? | iOS App Store ID for fallback | null |

## Testing

To reset the SDK state for testing:

```dart
await RateUsManager().reset();
```

## Benefits

- 📦 **One SDK**: Plug into all apps, one-time setup
- 🚀 **Smart Timing**: Shows dialog only when useful
- 😌 **Non-intrusive**: Honors cooldowns and user decisions
- 📈 **Boost Ratings**: Higher chance of getting feedback
- 🛠 **Easy to Maintain**: Single point of config/update

## License

This project is licensed under the MIT License - see the LICENSE file for details.
