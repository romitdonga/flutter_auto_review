import 'package:flutter/material.dart';
import 'package:flutter_auto_review/flutter_auto_review.dart';

late RateUsManager rateManager;
late StorageRepository storage;

/// Simple console to show analytics + debug logs.
final ValueNotifier<List<String>> logs = ValueNotifier([]);

void logMsg(String msg) {
  final now = DateTime.now();
  final t =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  logs.value = [...logs.value, "[$t] $msg"];
}

/// ---------- MAIN ----------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  storage = await StorageRepository.init();

  rateManager = await RateUsManager.init(
    storage: storage,
    config: const RateUsConfig(
      rateUsInitialize: 1,
      minAppOpens: 0,
      cooldownDays: 2,
      appStoreId: null,
    ),
    analytics: RateUsAnalytics(
      onEvent: (e, p) => logMsg("Analytics: $e -> $p"),
    ),
  );

  logMsg("Demo App Started");
  logMsg("Rate Manager Initialized");

  runApp(const AutoReviewDemo());
}

/// ------------------------------------------------------------
/// DEMO APP
/// ------------------------------------------------------------
class AutoReviewDemo extends StatelessWidget {
  const AutoReviewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Review Demo',
      theme: ThemeData(useMaterial3: true),
      home: const DemoHome(),
    );
  }
}

/// ------------------------------------------------------------
/// MAIN SCREEN
/// ------------------------------------------------------------
class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  Future<void> _appOpen() async {
    logMsg("Trigger: onAppOpen()");
    await rateManager.onAppOpen();
    await rateManager.tryShowRateDialog(context);
    setState(() {});
  }

  Future<void> _genericTrigger() async {
    logMsg("Trigger: tryShowRateDialog()");
    await rateManager.tryShowRateDialog(context);
    setState(() {});
  }

  Future<void> _manualTrigger() async {
    logMsg("Trigger: Manual Settings Trigger");
    await rateManager.tryShowRateDialog(context, manual: true);
    setState(() {});
  }

  Future<void> _clearAssumedRated() async {
    await storage.setAssumedRatedCustom(false);
    logMsg("Reset: assumedRatedCustom = false");
    setState(() {});
  }

  Future<void> _clearLastCancel() async {
    await storage.setLastCustomCancel(DateTime.now());
    logMsg("Reset: lastCustomCancel = null");
    setState(() {});
  }

  Future<void> _clearNativeDate() async {
    await storage.setNativeCalledDate(DateTime.now().toIso8601String());
    logMsg("Reset: nativeCallDate = null");
    setState(() {});
  }

  Future<void> _incAppOpens() async {
    await storage.incrementAppOpens();
    logMsg("AppOpens++ -> ${storage.appOpens}");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Auto Review Demo")),
      body: Column(
        children: [
          _buildStatePanel(),
          _buildControls(),
          Expanded(child: _buildConsole()),
        ],
      ),
    );
  }

  /// ---------------------------------------------------------
  /// STATE PANEL
  /// ---------------------------------------------------------
  Widget _buildStatePanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.blueGrey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Storage State",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            children: [
              _chip("appOpens: ${storage.appOpens}"),
              _chip("customShown: ${storage.customShownCount}"),
              _chip("assumedRated: ${storage.assumedRatedCustom}"),
              _chip("lastCancel: ${storage.lastCustomCancel}"),
              _chip("nativeCalled: ${storage.nativeCalledToday()}"),
            ],
          ),
        ],
      ),
    );
  }

  /// ---------------------------------------------------------
  /// TRIGGER BUTTONS
  /// ---------------------------------------------------------
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 10,
        children: [
          _btn("App Open", _appOpen),
          _btn("Generic Trigger", _genericTrigger),
          _btn("Manual Trigger", _manualTrigger),
          _btn("AppOpens++", _incAppOpens),
          _btn("Reset Rated", _clearAssumedRated),
          _btn("Reset Cancel", _clearLastCancel),
          _btn("Reset Native", _clearNativeDate),
        ],
      ),
    );
  }

  /// ---------------------------------------------------------
  /// LOG CONSOLE
  /// ---------------------------------------------------------
  Widget _buildConsole() {
    return Container(
      color: Colors.black,
      child: ValueListenableBuilder(
        valueListenable: logs,
        builder: (_, list, __) {
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => Text(
              list[i],
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Small UI helpers
  Widget _btn(String t, Future<void> Function() onTap) {
    return ElevatedButton(onPressed: onTap, child: Text(t));
  }

  Widget _chip(String t) {
    return Chip(label: Text(t));
  }
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final storage = await StorageRepository.init();
//   final manager = await RateUsManager.init(
//     storage: storage,
//     config: const RateUsConfig(
//       rateUsInitialize: 1,
//       minAppOpens: 0,
//       cooldownDays: 2,
//       appStoreId: null,
//     ),
//     analytics: RateUsAnalytics(
//       onEvent: (name, params) {
//         // FirebaseAnalytics.instance.log(name: eventName, parameters: parameters);
//         debugPrint('GA4 EVENT: $name -> $params');
//       },
//     ),
//   );
//   runApp(MyApp(manager: manager, storage: storage));
// }

// class MyApp extends StatelessWidget {
//   final RateUsManager manager;
//   final StorageRepository storage;
//   const MyApp({super.key, required this.manager, required this.storage});

//   @override
//   Widget build(BuildContext context) {
//     return Provider.value(
//       value: manager,
//       child: MaterialApp(title: 'Auto Review Demo', home: HomeScreen()),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   RateUsManager? manager;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     manager ??= Provider.of<RateUsManager>(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Auto Review Demo'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.star),
//             onPressed: () => manager?.tryShowRateDialog(context, manual: true),
//             tooltip: 'Rate (manual)',
//           ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           const Text('Tap buttons to simulate triggers and flows'),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: () async {
//               await manager?.onAppOpen();
//               await manager?.tryShowRateDialog(context);
//             },
//             child: const Text('Simulate App Open Trigger'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: () => manager?.tryShowRateDialog(context),
//             child: const Text('Simulate Generic Trigger'),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: () async {
//               await manager?.tryShowRateDialog(context, manual: true);
//             },
//             child: const Text('Manual Settings Trigger'),
//           ),
//         ],
//       ),
//     );
//   }
// }
