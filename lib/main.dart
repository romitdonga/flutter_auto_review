import 'package:flutter/material.dart';
import 'package:flutter_auto_review/flutter_auto_review.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the RateUsManager with default config
  await RateUsManager().init(
    config: const RateUsConfig(
      rateUsInitialize: 1, // 1 = enabled, 0 = disabled
      minDaysSinceInstall: 3,
      minAppOpens: 5,
      minEvents: 3,
      autoTrigger: 10,
      exitTrigger: 0, // 1 = enabled, 0 = disabled
      cooldownDays: 30,
      appStoreId: '123456789', // Replace with your App Store ID
    ),
    analytics: RateUsAnalytics(
      onEvent: (String eventName, Map<String, dynamic> parameters) {
        // Send analytics events to your analytics provider
        debugPrint('Analytics event: $eventName, parameters: $parameters');
      },
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auto Review Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Center(child: Text('Flutter Auto Review Demo')),
    );
  }
}
