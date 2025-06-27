import 'package:flutter/material.dart';
import 'package:flutter_auto_review/flutter_auto_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Example app showing how to integrate flutter_auto_review SDK
/// This demonstrates all the features of the SDK including:
/// - Initialization with configuration
/// - Auto-triggering based on app opens, days since install, custom events
/// - Manual triggering from settings
/// - Analytics integration
/// - App lifecycle handling for exit triggers

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RateUsManager with config
  await RateUsManager().init(
    config: const RateUsConfig(
      rateUsInitialize: 1, // 1 = enabled, 0 = disabled
      minDaysSinceInstall: 3,
      minAppOpens: 5,
      minEvents: 3,
      autoTrigger: 10,
      exitTrigger: 1, // 1 = enabled, 0 = disabled
      cooldownDays: 30,
      appStoreId: 'YOUR_APP_STORE_ID', // Replace with your App Store ID
    ),
    analytics: RateUsAnalytics(
      onEvent: (String eventName, Map<String, dynamic> parameters) {
        // Log events to your analytics provider
        // Example: FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
        debugPrint('Analytics event: $eventName, parameters: $parameters');
      },
    ),
  );

  runApp(const MyApp());
}

/// Example of how to initialize with Firebase Remote Config (add this to your project)
///
/// ```dart
/// import 'package:firebase_core/firebase_core.dart';
/// import 'package:firebase_remote_config/firebase_remote_config.dart';
///
/// Future<void> initWithFirebaseConfig() async {
///   // Initialize Firebase
///   await Firebase.initializeApp();
///
///   // Initialize Remote Config
///   final remoteConfig = FirebaseRemoteConfig.instance;
///   await remoteConfig.setConfigSettings(RemoteConfigSettings(
///     fetchTimeout: const Duration(minutes: 1),
///     minimumFetchInterval: const Duration(hours: 1),
///   ));
///
///   // Set default values
///   await remoteConfig.setDefaults({
///     'rateUS_initialize': 1,
///     'rate_days_since_install': 3,
///     'rate_min_opens': 5,
///     'rate_min_events': 3,
///     'rate_auto_trigger': 10,
///     'rate_exit': 1,
///     'rate_cooldown_days': 30,
///     'app_store_id': 'YOUR_APP_STORE_ID',
///   });
///
///   // Fetch remote config
///   await remoteConfig.fetchAndActivate();
///
///   // Get config values from Remote Config
///   final configMap = {
///     'rateUS_initialize': remoteConfig.getInt('rateUS_initialize'),
///     'rate_days_since_install': remoteConfig.getInt('rate_days_since_install'),
///     'rate_min_opens': remoteConfig.getInt('rate_min_opens'),
///     'rate_min_events': remoteConfig.getInt('rate_min_events'),
///     'rate_auto_trigger': remoteConfig.getInt('rate_auto_trigger'),
///     'rate_exit': remoteConfig.getInt('rate_exit'),
///     'rate_cooldown_days': remoteConfig.getInt('rate_cooldown_days'),
///     'app_store_id': remoteConfig.getString('app_store_id'),
///   };
///
///   // Initialize RateUsManager with Remote Config values
///   await RateUsManager().init(
///     config: RateUsConfig.fromMap(configMap),
///     analytics: RateUsAnalytics(
///       onEvent: (String eventName, Map<String, dynamic> parameters) {
///         // Log events to Firebase Analytics
///         FirebaseAnalytics.instance.logEvent(
///           name: eventName,
///           parameters: parameters,
///         );
///       },
///     ),
///   );
/// }
/// ```

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auto Review Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, RouteAware {
  final RateUsManager _rateUsManager = RateUsManager();
  int _downloadCount = 0;
  int _screenTransitions = 0;
  final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Check if we should show the rate dialog based on app opens
    _checkRateDialogOnAppOpen();

    // Check if we should show the rate dialog based on days since install
    _checkRateDialogOnDaysSinceInstall();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register for route changes to track screen transitions
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Clean up observers
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is about to exit, check if we should show the rate dialog
      _rateUsManager.onAppExit(context);
    }
  }

  @override
  void didPush() {
    // Called when this route is pushed
    _onScreenTransition();
  }

  @override
  void didPopNext() {
    // Called when a route is popped and this route shows up
    _onScreenTransition();
  }

  /// Check if we should show the rate dialog based on app opens
  Future<void> _checkRateDialogOnAppOpen() async {
    final shouldShow = await _rateUsManager.onMinAppOpens();
    if (shouldShow) {
      // Show the rate dialog after a short delay to allow the app to fully load
      Future.delayed(const Duration(seconds: 1), () {
        _rateUsManager.showRateDialog(context);
      });
    }
  }

  /// Check if we should show the rate dialog based on days since install
  Future<void> _checkRateDialogOnDaysSinceInstall() async {
    final shouldShow = await _rateUsManager.onMinDaysSinceInstall();
    if (shouldShow) {
      // Show the rate dialog after a short delay to allow the app to fully load
      Future.delayed(const Duration(seconds: 1), () {
        _rateUsManager.showRateDialog(context);
      });
    }
  }

  /// Simulate a download (custom event)
  Future<void> _simulateDownload() async {
    setState(() {
      _downloadCount++;
    });

    // Show loading indicator
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Downloading...')));

    // Simulate download delay
    await Future.delayed(const Duration(seconds: 1));

    // Show success message
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Download complete!')));

    // Trigger custom event and check if we should show the rate dialog
    final shouldShow = await _rateUsManager.onCustomEvent();
    if (shouldShow) {
      _rateUsManager.showRateDialog(context);
    }
  }

  /// Track screen transitions and trigger auto review if needed
  Future<void> _onScreenTransition() async {
    setState(() {
      _screenTransitions++;
    });

    // Check if we should show the rate dialog based on auto trigger count
    final shouldShow = await _rateUsManager.onAutoTrigger();
    if (shouldShow) {
      _rateUsManager.showRateDialog(context);
    }
  }

  /// Reset the rate us manager for testing
  Future<void> _resetManager() async {
    await _rateUsManager.reset();
    setState(() {
      _downloadCount = 0;
      _screenTransitions = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rate Us Manager reset for testing')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Auto Review Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'App Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Flutter Auto Review SDK Demo',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Testing Triggers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Downloads:'),
                          Text(
                            '$_downloadCount',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Screen Transitions:'),
                          Text(
                            '$_screenTransitions',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _simulateDownload,
                        icon: const Icon(Icons.download),
                        label: const Text('Simulate Download'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Testing Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _rateUsManager.onSettingsTrigger(context),
                        icon: const Icon(Icons.star),
                        label: const Text('Rate App (Manual Trigger)'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _resetManager,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Rate Manager'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings page to demonstrate manual trigger
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate Our App'),
            onTap: () {
              // Manual trigger from settings
              RateUsManager().onSettingsTrigger(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// About page to demonstrate screen transitions
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Flutter Auto Review Example',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'This example demonstrates how to integrate the Flutter Auto Review SDK into your app.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Version 1.0.0',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
