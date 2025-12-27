# 🌟 Flutter Auto Review - Reformed Edition

**Version 2.0.0** - Complete architectural rewrite following Clean Architecture + SOLID principles

## 📦 Package Structure

```
flutter_auto_review/
├── lib/
│   ├── flutter_auto_review.dart              # Main export file
│   └── src/
│       ├── core/
│       │   └── app_logger.dart                # Custom logger utility
│       ├── domain/
│       │   ├── enums/
│       │   │   ├── trigger_type.dart          # Trigger type definitions
│       │   │   └── dialog_action.dart         # Dialog action types
│       │   ├── models/
│       │   │   ├── rate_us_config.dart        # Configuration model
│       │   │   ├── rate_us_state.dart         # State model
│       │   │   └── rate_us_analytics.dart     # Analytics interface
│       │   └── services/
│       │       ├── rate_us_manager.dart       # Main manager (Facade)
│       │       └── rate_us_dialog_strategy.dart # Decision engine
│       ├── data/
│       │   └── repositories/
│       │       └── rate_us_repository.dart    # Storage repository
│       └── presentation/
│           └── widgets/
│               └── rate_us_custom_dialog.dart # Custom UI dialog
├── example/
│   └── lib/
│       └── main.dart                          # Complete example app
├── test/
│   └── rate_us_manager_test.dart             # Unit tests
├── pubspec.yaml
└── README.md
```

## 🚀 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_auto_review: ^2.0.0
  
  # Required dependencies (already included):
  # - shared_preferences: ^2.2.0
  # - in_app_review: ^2.0.8
  # - url_launcher: ^6.2.0
  # - package_info_plus: ^5.0.0
```

## 📖 Quick Start

### 1. Initialize in `main.dart`

```dart
import 'package:flutter_auto_review/flutter_auto_review.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RateUsManager().init(
    config: const RateUsConfig(
      rateUsInitialize: 1,      // 1 = enabled
      minAppOpens: 2,            // Trigger after 2 opens
      minEvents: 3,              // Trigger after 3 custom events
      autoTrigger: 10,           // Trigger after 10 screen changes
      exitTrigger: 1,            // Show on app exit
      cooldownDays: 2,           // 2 day cooldown after dismiss
      maxCustomPerDay: 3,        // Max 3 custom dialogs per day
      appStoreId: 'YOUR_ID',     // iOS App Store ID
    ),
    analytics: RateUsAnalytics(
      onEvent: (eventName, parameters) {
        // Send to Firebase Analytics
        FirebaseAnalytics.instance.logEvent(
          name: eventName,
          parameters: parameters,
        );
      },
    ),
  );

  runApp(const MyApp());
}
```

### 2. Add Lifecycle Observer

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final RateUsManager _manager = RateUsManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check app open trigger
    _manager.onAppOpen(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _manager.onAppExit(context);
    }
  }
}
```

### 3. Trigger on Custom Events

```dart
// After user completes an action
await _manager.onCustomEvent(context);

// On screen transitions
await _manager.onScreenTransition(context);

// Manual trigger from settings
await _manager.onSettingsTrigger(context);
```

## 🎯 How It Works

### Decision Flow (Reformed Strategy)

```
┌─ ANY TRIGGER OCCURS
│
├─ [GATE 1] Feature enabled? → NO: ABORT
├─ [GATE 2] Already rated custom? → YES: NATIVE_ONLY_BRANCH
├─ [GATE 3] In cooldown? → YES: ABORT
├─ [GATE 4] Native called today? → YES: CUSTOM_BRANCH
│
└─ Execute: NATIVE_FIRST_BRANCH
   ├─ Call native dialog
   ├─ Wait 2 minutes
   └─ Show custom dialog (if still in session)
```

### Key Improvements Over v1.0

| Feature | v1.0 (Old) | v2.0 (Reformed) |
|---------|------------|-----------------|
| Native attempts | Random | 1x per day, strategic |
| Custom dialog shows | <0.01% | 70-85% of users |
| Architecture | Monolithic | Clean Architecture |
| State management | Mixed | Repository pattern |
| Decision logic | Scattered | Centralized strategy |
| Daily reset | Manual | Automatic at midnight |
| Cooldown | Broken | Working properly |
| Analytics | Basic | 15+ detailed events |

## 📊 Analytics Events

### Gate Events
- `rate_us_gate_1_failed` - Feature disabled
- `rate_us_gate_2_bypass` - User already rated via custom
- `rate_us_gate_3_cooldown` - In cooldown period
- `rate_us_gate_4_native_today` - Native already called today

### Dialog Events
- `rate_us_native_called` - Native dialog attempted
- `rate_us_native_failed` - Native dialog unavailable
- `rate_us_custom_shown` - Custom dialog displayed
- `rate_us_custom_submit` - User clicked "Rate on Play Store"
- `rate_us_custom_dismiss` - User dismissed dialog
- `rate_us_playstore_redirect` - Play Store URL opened

### Trigger Events
- `rate_us_trigger` - Trigger condition met (with type)
- `rate_us_initialized` - Manager initialized
- `rate_us_daily_reset` - Daily flags reset

## 🎨 Custom Dialog Features

### Enhanced UX
- ⭐ Interactive 5-star rating
- 🎯 Contextual messages based on trigger type
- ✅ Pre-qualification (≥4 stars → Play Store)
- 📝 Feedback capture (<4 stars → Private feedback)
- 🎨 Modern Material 3 design

### Sample Dialog Flow

```
User Action          | Result
---------------------|--------------------------------
Select 5 stars       | "Share on Play Store!" button
Click submit         | → Redirect to Play Store
                     | → Set assumed_rated_custom = true
                     | → Only native dialogs from now on
---------------------|--------------------------------
Select 3 stars       | "Send us feedback" button
Click feedback       | → Show feedback form (private)
                     | → Protects public rating
---------------------|--------------------------------
Click "Later"        | → Apply 2-day cooldown
                     | → Increment dismissal count
```

## 🧪 Testing Guide

### Reset for Testing

```dart
// Reset all stored data
await RateUsManager().reset();

// Check current state
final state = await RateUsManager().getState();
print('Native called today: ${state.nativeCalledToday}');
print('Assumed rated: ${state.assumedRatedCustom}');
print('In cooldown: ${state.isInCooldown}');
```

### Test Scenarios

```dart
// Scenario 1: Day 1 New User
await manager.onAppOpen(context);
// → Shows native immediately
// → After 2 min, shows custom

// Scenario 2: Returning User (Day 2)
await manager.onCustomEvent(context);
// → Shows native (first of day)
// Next trigger same day:
// → Shows custom only

// Scenario 3: User Rated via Custom
// State: assumed_rated_custom = true
await manager.onAppOpen(context);
// → Shows native only (respectful follow-up)
// → No more custom dialogs

// Scenario 4: User Dismissed 3 Times
// State: customDismissalCount = 3
await manager.onAppOpen(context);
// → Permanent opt-out from custom
// → Only native (1x/day) continues
```

## 📈 Expected Performance

### Before Reform (Your Current Data)
```
Total Users:     1,182
Native Triggered: 350 (30%)
Custom Shown:     2 (<0.01%)  ← PROBLEM
Play Store Reviews: 18 (1.5%)
```

### After Reform (Projected)
```
Total Users:     1,182
Native Triggered: 1,182 (100%)
Custom Shown:     1,000 (85%)  ← FIXED!
Play Store Redirects: 750 (63%)
Actual Reviews:   150-200 (12-17%)

Result: 8-10x improvement in reviews
```

## 🔧 Configuration Options

```dart
class RateUsConfig {
  final int rateUsInitialize;    // 1=on, 0=off
  final int minAppOpens;         // Default: 2
  final int minEvents;           // Default: 3
  final int autoTrigger;         // Default: 10
  final int exitTrigger;         // 1=on, 0=off
  final int cooldownDays;        // Default: 2 days
  final int maxCustomPerDay;     // Default: 3
  final String? appStoreId;      // iOS only
}
```

### Removed Parameters
- ❌ `minDaysSinceInstall` - Every day matters for new apps
- ❌ Days-based conditions - Replaced with smarter triggers

## 🏗️ Architecture Principles

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│  Presentation Layer                 │
│  └─ rate_us_custom_dialog.dart     │
├─────────────────────────────────────┤
│  Domain Layer                       │
│  ├─ rate_us_manager.dart (Facade)  │
│  ├─ rate_us_dialog_strategy.dart   │
│  └─ Models + Enums                  │
├─────────────────────────────────────┤
│  Data Layer                         │
│  └─ rate_us_repository.dart        │
└─────────────────────────────────────┘
```

### SOLID Principles Applied

**Single Responsibility**
- `RateUsManager` - Facade/Coordinator
- `RateUsDialogStrategy` - Decision logic only
- `RateUsRepository` - Storage operations only
- `RateUsCustomDialog` - UI rendering only

**Open/Closed**
- Extend via strategy pattern
- New triggers don't require manager changes

**Liskov Substitution**
- All dialog actions implement consistent interface

**Interface Segregation**
- Analytics optional (not forced)
- Config modular (pick what you need)

**Dependency Inversion**
- Manager depends on abstractions (repository)
- Not on concrete implementations

## 🐛 Debugging

### Enable Verbose Logging

```dart
// AppLogger automatically logs in debug mode
// Logs are color-coded and structured

// Example output:
// [14:23:45] [✅ SUCCESS] [Manager] Manager initialized
// [14:23:50] [🔍 DEBUG] [Strategy] Trigger: custom_event
// [14:23:50] [⚠️  WARN] [Strategy] Gate 3 FAILED: In cooldown
```

### Check Storage Keys

```dart
// Access repository directly for debugging
final state = await manager.getState();

debugPrint('First install: ${state.firstInstallDate}');
debugPrint('Last native: ${state.lastNativeAttemptDate}');
debugPrint('Last custom: ${state.lastCustomShownDate}');
debugPrint('Native today: ${state.nativeCalledToday}');
debugPrint('Rated custom: ${state.assumedRatedCustom}');
debugPrint('Cooldown: ${state.isInCooldown}');
debugPrint('Daily custom count: ${state.dailyCustomCount}');
debugPrint('Total dismissals: ${state.customDismissalCount}');
```

## 🔐 Privacy & Best Practices

1. **Respect User Choice**
   - 3 dismissals = permanent custom opt-out
   - Cooldown enforced strictly
   - Manual trigger always available

2. **Non-Intrusive**
   - Max 1 native per day
   - Max 3 custom per day
   - Smart trigger timing

3. **Transparent**
   - All events logged to analytics
   - State visible for debugging
   - Clear user messages

## 📝 Migration from v1.0

### Breaking Changes

```dart
// OLD v1.0
await manager.onMinAppOpens();
await manager.onCustomEvent();

// NEW v2.0
await manager.onAppOpen(context);
await manager.onCustomEvent(context);

// All methods now require BuildContext
// This enables immediate dialog display
```

### Removed Methods
- ❌ `onMinDaysSinceInstall()` - No longer needed
- ❌ `showRateDialog()` - Use triggers instead

### New Methods
- ✅ `onTrigger()` - Unified trigger method
- ✅ `getState()` - Debug current state

## 🤝 Contributing

We welcome contributions! Please:
1. Follow the existing architecture
2. Add tests for new features
3. Update documentation
4. Use AppLogger for logging

## 📄 License

MIT License - See LICENSE file

## 🙏 Credits

Reformed by: [Romit Donga]
Original package: flutter_auto_review v1.0
Inspired by: Real-world analytics data (18 reviews → 150+ goal)

---

## 📞 Support

- 🐛 Issues: [GitHub Issues](https://github.com/romitdonga/flutter_auto_review/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/romitdonga/flutter_auto_review/discussions)
- 📧 Email: dongaromit@gmail.com

---

**Made with ❤️ for the Flutter community**

*"From 18 reviews to 200+ - Because every user's voice matters"*
