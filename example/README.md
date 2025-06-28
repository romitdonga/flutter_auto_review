# Flutter Auto Review Example

This is an example application demonstrating how to use the `flutter_auto_review` package.

## Features

- Initialize the rate us manager with custom configuration
- Trigger rating dialog based on different conditions:
  - Custom events
  - App opens
  - Days since install
  - Auto trigger
  - Settings trigger
  - Manual trigger
- Reset stored data for testing
- Analytics events logging

## Getting Started

1. Make sure you have Flutter installed
2. Clone this repository
3. Run `flutter pub get` in the example directory
4. Run the app with `flutter run`

## Usage

The app includes several buttons to test different features of the `flutter_auto_review` package:

- **Reset Rate Us Data**: Clears all stored data
- **Show Rate Dialog Manually**: Shows the rating dialog immediately
- **Trigger from Settings**: Simulates triggering the dialog from app settings
- **Auto Trigger**: Simulates auto-triggering the dialog
- **Check Min App Opens**: Checks if the minimum app opens condition is met
- **Check Min Days Since Install**: Checks if the minimum days since install condition is met
- **Floating Action Button**: Increments counter and triggers a custom event

## Configuration

The example app initializes the RateUsManager with the following configuration:

```dart
final config = RateUsConfig(
  rateUsInitialize: 1, // Enable the feature
  minDaysSinceInstall: 0, // For testing: Show immediately
  minAppOpens: 3, // Show after 3 app opens
  minEvents: 2, // Show after 2 custom events
  autoTrigger: 5, // Auto-trigger after 5 screen transitions
  exitTrigger: 1, // Trigger on app exit
  cooldownDays: 1, // Wait 1 day before showing again after dismissal
  appStoreId: '123456789', // Example App Store ID
);
```

You can modify these values to test different scenarios. 