import 'package:flutter/material.dart';
import 'package:flutter_auto_review/flutter_auto_review.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auto Review Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Auto Review Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final RateUsManager _rateUsManager = RateUsManager();
  int _counter = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRateUsManager();
  }

  Future<void> _initRateUsManager() async {
    // Create a configuration for the rate us feature
    const config = RateUsConfig(
      rateUsInitialize: 1, // Enable the feature
      minDaysSinceInstall: 0, // For testing: Show immediately
      minAppOpens: 3, // Show after 3 app opens
      minEvents: 2, // Show after 2 custom events
      autoTrigger: 5, // Auto-trigger after 5 screen transitions
      exitTrigger: 1, // Trigger on app exit
      cooldownDays: 1, // Wait 1 day before showing again after dismissal
      appStoreId: '123456789', // Example App Store ID
    );

    // Create analytics handler
    final analytics = RateUsAnalytics(
      onEvent: (eventName, parameters) {
        // In a real app, you would send these events to your analytics service
        debugPrint('Analytics event: $eventName, params: $parameters');
      },
    );

    // Initialize the manager
    await _rateUsManager.init(config: config, analytics: analytics);

    setState(() {
      _isInitialized = true;
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    // Trigger custom event
    _rateUsManager.onCustomEvent().then((shouldShow) async {
      if (shouldShow) {
        if (!mounted) return;
        await _rateUsManager.showRateDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _rateUsManager.reset(),
              child: const Text('Reset Rate Us Data'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isInitialized
                  ? () async {
                      if (!mounted) return;
                      await _rateUsManager.showRateDialog(context);
                    }
                  : null,
              child: const Text('Show Rate Dialog Manually'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isInitialized
                  ? () async {
                      if (!mounted) return;
                      await _rateUsManager.onSettingsTrigger(context);
                    }
                  : null,
              child: const Text('Trigger from Settings'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isInitialized
                  ? () async {
                      final shouldShow = await _rateUsManager.onAutoTrigger();
                      if (!mounted) return;
                      if (shouldShow) {
                        await _rateUsManager.showRateDialog(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Auto trigger condition not met'),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text('Auto Trigger'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isInitialized
                  ? () async {
                      final shouldShow = await _rateUsManager.onMinAppOpens();
                      if (!mounted) return;
                      if (shouldShow) {
                        await _rateUsManager.showRateDialog(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Min app opens condition not met'),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text('Check Min App Opens'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isInitialized
                  ? () async {
                      final shouldShow = await _rateUsManager
                          .onMinDaysSinceInstall();
                      if (!mounted) return;
                      if (shouldShow) {
                        await _rateUsManager.showRateDialog(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Min days condition not met'),
                          ),
                        );
                      }
                    }
                  : null,
              child: const Text('Check Min Days Since Install'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
