import 'package:flutter/material.dart';
import 'package:flutter_auto_review/flutter_auto_review.dart';
import 'package:rive/rive.dart';

import 'app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Rate Us Manager
  await RateUsManager().init(
    config: const RateUsConfig(
      rateUsInitialize: 1,
      minAppOpens: 2,
      minEvents: 3,
      autoTrigger: 10,
      exitTrigger: 1,
      cooldownDays: 2,
      maxCustomPerDay: 3,
      appStoreId: 'YOUR_APP_STORE_ID',
    ),
    analytics: RateUsAnalytics(
      onEvent: (eventName, parameters) {
        // Send to Firebase Analytics or your analytics provider
        AppLogger.n('Analytics: $eventName', tag: 'GA4', data: parameters);
      },
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rate Us Reformed Example',
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final RateUsManager _manager = RateUsManager();
  int _customEvents = 0;
  int _screenTransitions = 0;
  RateUsState? _currentState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppOpenTrigger();
    _loadCurrentState();
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

  Future<void> _checkAppOpenTrigger() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      await _manager.onAppOpen(context);
    }
  }

  Future<void> _loadCurrentState() async {
    final state = await _manager.getState();
    setState(() => _currentState = state);
  }

  Future<void> _simulateCustomEvent() async {
    setState(() => _customEvents++);
    await _manager.onCustomEvent(context);
    await _loadCurrentState();
  }

  Future<void> _simulateScreenTransition() async {
    setState(() => _screenTransitions++);
    await _manager.onScreenTransition(context);
    await _loadCurrentState();
  }

  Future<void> _resetManager() async {
    await _manager.reset();
    setState(() {
      _customEvents = 0;
      _screenTransitions = 0;
      _currentState = null;
    });
    await _loadCurrentState();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Manager reset complete')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Us Reformed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStateCard(),
            const SizedBox(height: 16),
            _buildTriggerTestCard(),
            const SizedBox(height: 16),
            _buildControlsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Current State',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_currentState != null) ...[
              _buildStateRow(
                'Native Called Today',
                _currentState!.nativeCalledToday ? '✅' : '❌',
              ),
              _buildStateRow(
                'Assumed Rated Custom',
                _currentState!.assumedRatedCustom ? '✅' : '❌',
              ),
              _buildStateRow(
                'In Cooldown',
                _currentState!.isInCooldown ? '🔒' : '✅',
              ),
              _buildStateRow(
                'Daily Custom Count',
                '${_currentState!.dailyCustomCount}/3',
              ),
              _buildStateRow(
                'Total Dismissals',
                '${_currentState!.customDismissalCount}',
              ),
              _buildStateRow(
                'First Install',
                _formatDate(_currentState!.firstInstallDate),
              ),
              _buildStateRow(
                'Last Native',
                _formatDate(_currentState!.lastNativeAttemptDate),
              ),
              _buildStateRow(
                'Last Custom',
                _formatDate(_currentState!.lastCustomShownDate),
              ),
            ] else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildStateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTriggerTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Test Triggers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custom Events:'),
                Text(
                  '$_customEvents',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _simulateCustomEvent,
              icon: const Icon(Icons.event),
              label: const Text('Simulate Custom Event'),
            ),
            const Divider(height: 24),
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
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _simulateScreenTransition,
              icon: const Icon(Icons.screen_rotation),
              label: const Text('Simulate Screen Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎮 Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _manager.onSettingsTrigger(context),
              icon: const Icon(Icons.star),
              label: const Text('Manual Rate Trigger'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _resetManager,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Manager'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

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
            leading: const Icon(Icons.star),
            title: const Text('Rate Our App'),
            subtitle: const Text('Help us grow with your review'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => RateUsManager().onSettingsTrigger(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 2.0.0 - Reformed'),
          ),
        ],
      ),
    );
  }
}

class ExampleEvents extends StatefulWidget {
  const ExampleEvents({super.key});

  @override
  State<ExampleEvents> createState() => _ExampleEventsState();
}

class _ExampleEventsState extends State<ExampleEvents> {
  File? _riveFile;
  RiveWidgetController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _riveFile = await File.asset(
      'packages/flutter_auto_review/assets/rating.riv',
      riveFactory: Factory.rive,
    );
    _controller = RiveWidgetController(_riveFile!);
    _controller?.stateMachine.addEventListener(_onRiveEvent);
    setState(() {});
  }

  String ratingValue = 'Rating: 0';

  void _onRiveEvent(Event event) {
    // Access custom properties defined on the event
    print(event);
    var rating = event.numberProperty('rating')?.value ?? 0;
    setState(() {
      ratingValue = 'Rating: $rating';
    });
  }

  @override
  void dispose() {
    _controller?.stateMachine.removeEventListener(_onRiveEvent);
    _controller?.stateMachine.dispose();
    _riveFile?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: _riveFile == null
              ? const SizedBox()
              : RiveWidget(controller: _controller!, fit: Fit.cover),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            ratingValue,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
