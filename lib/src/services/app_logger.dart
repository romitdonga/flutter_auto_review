// ignore_for_file: avoid_print

//RDX ----------------------------------------------------------------------------

// Insted of use log/print/debugPrint use my created AppLogger

// 🎨 Quick Reference:
// Method                 Use Case         Example
// AppLogger.d()        Debug info       AppLogger.d('Loading...', tag: 'UI')
// AppLogger.i()        General info     AppLogger.i('User logged in')
// AppLogger.w()        Warnings         AppLogger.w('Slow network')
// AppLogger.e()        Errors           AppLogger.e('Failed', error: e)
// AppLogger.s()        Success          AppLogger.s('Saved successfully')
// AppLogger.n()        Network          AppLogger.n('API call completed')
// AppLogger.section()  Dividers         AppLogger.section('Run #2 started')

// Use Anywhere With One Line
// //tag use for identify module or feature
// dartAppLogger.d('Debug message', tag: 'MyFeature');
// AppLogger.s('Success!', tag: 'API');
// AppLogger.e('Error occurred', tag: 'Database', error: e, stackTrace: stack);
//RDX ----------------------------------------------------------------------------

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug(0, '🔍', '\x1B[36m'), // Cyan
  info(1, 'ℹ️', '\x1B[37m'), // White
  warning(2, '⚠️', '\x1B[33m'), // Yellow
  error(3, '❌', '\x1B[31m'), // Red
  success(4, '✅', '\x1B[32m'), // Green
  network(5, '🌐', '\x1B[35m'), // Magenta
  isolate(6, '🔄', '\x1B[34m'); // Blue

  final int priority;
  final String emoji;
  final String ansiColor;
  const LogLevel(this.priority, this.emoji, this.ansiColor);
}

class AppLogger {
  static const String _resetColor = '\x1B[0m';
  static const String _boldColor = '\x1B[1m';

  static bool enableLogsInDebug = true;
  static bool enableLogsInRelease = false; // 🔒 PRODUCTION LOCK
  static LogLevel minimumLogLevel = LogLevel.debug;

  /// Enable/disable colored output
  static bool enableColors = true;

  /// Enable timestamps
  static bool enableTimestamps = true;

  /// Maximum tag length for alignment
  static int maxTagLength = 20;

  // ========== PRIVATE CONSTRUCTOR ==========
  AppLogger._();

  // ========== CORE LOGGING GATE ==========
  /// The ONE gate all logs pass through
  static void _log(
    LogLevel level,
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // 🔒 ZERO-PERFORMANCE PRODUCTION LOCK
    if (kReleaseMode && !enableLogsInRelease) return;
    if (kDebugMode && !enableLogsInDebug) return;
    if (level.priority < minimumLogLevel.priority) return;

    // Build log message
    final timestamp = enableTimestamps
        ? DateTime.now().toString().substring(11, 23)
        : '';

    final paddedTag = tag.padRight(maxTagLength);

    final color = enableColors ? level.ansiColor : '';
    final reset = enableColors ? _resetColor : '';
    final bold = enableColors ? _boldColor : '';

    final prefix = '${level.emoji} [$paddedTag]';
    final timeStr = timestamp.isNotEmpty ? '[$timestamp]' : '';

    final logMessage = '$color$bold$prefix$reset $timeStr $color$message$reset';

    // Output using dart:developer for better performance
    developer.log(
      logMessage,
      name: tag,
      time: DateTime.now(),
      level: level.priority * 100,
      error: error,
      stackTrace: stackTrace,
    );

    // If there's additional data, log it as JSON
    if (data != null && data.isNotEmpty) {
      developer.log('  📋 Data: $data', name: tag);
    }

    // If there's an error, log it
    if (error != null) {
      developer.log('  💥 Error: $error', name: tag, error: error);
    }

    // If there's a stack trace, log it
    if (stackTrace != null) {
      developer.log(
        '  📚 Stack: ${stackTrace.toString().split('\n').take(5).join('\n  ')}',
        name: tag,
      );
    }
  }

  // ========== PUBLIC API - EASY TO USE ==========

  /// Debug logs (only in debug mode by default)
  static void d(
    String message, {
    String tag = 'App',
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Info logs
  static void i(
    String message, {
    String tag = 'App',
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Warning logs
  static void w(
    String message, {
    String tag = 'App',
    Object? error,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.warning, message, tag: tag, error: error, data: data);
  }

  /// Error logs
  static void e(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Success logs
  static void s(
    String message, {
    String tag = 'App',
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.success, message, tag: tag, data: data);
  }

  /// Network logs
  static void n(
    String message, {
    String tag = 'Network',
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.network, message, tag: tag, data: data);
  }

  /// Isolate/Background logs
  static void isolate(
    String message, {
    String tag = 'Isolate',
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.isolate, message, tag: tag, data: data);
  }

  // ========== SPECIALIZED LOGGERS ==========

  /// Section divider
  static void section(String title, {String tag = 'App'}) {
    final divider = '═' * 60;
    _log(LogLevel.info, '\n$divider\n  $title\n$divider', tag: tag);
  }

  /// Pretty print JSON/Map
  static void json(Map<String, dynamic> data, {String tag = 'JSON'}) {
    _log(LogLevel.debug, 'JSON Data:', tag: tag, data: data);
  }

  /// API Request log
  static void apiRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    n('$method $url', tag: 'API-Request');
    if (headers != null) d('Headers: $headers', tag: 'API-Request');
    if (body != null) d('Body: $body', tag: 'API-Request');
  }

  /// API Response log
  static void apiResponse({
    required int statusCode,
    required String url,
    dynamic body,
    Duration? duration,
  }) {
    final durationStr = duration != null
        ? ' (${duration.inMilliseconds}ms)'
        : '';
    final level = statusCode >= 200 && statusCode < 300
        ? LogLevel.success
        : LogLevel.error;

    _log(level, '$statusCode $url$durationStr', tag: 'API-Response');
    if (body != null) d('Response: $body', tag: 'API-Response');
  }

  /// Function trace (enter/exit tracking)
  static void trace(String functionName, {String tag = 'Trace'}) {
    d('→ $functionName()', tag: tag);
  }

  /// Performance measurement
  static void perf(
    String operation,
    Duration duration, {
    String tag = 'Performance',
  }) {
    final ms = duration.inMilliseconds;
    final color = ms < 100
        ? LogLevel.success
        : ms < 500
        ? LogLevel.warning
        : LogLevel.error;
    _log(color, '$operation took ${ms}ms', tag: tag);
  }

  // ========== CONDITIONAL LOGGING MACROS ==========

  /// Only log in debug mode
  static void debugOnly(String message, {String tag = 'Debug'}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, tag: tag);
    }
  }

  /// Only log in release mode
  static void releaseOnly(String message, {String tag = 'Release'}) {
    if (kReleaseMode) {
      _log(LogLevel.info, message, tag: tag);
    }
  }

  /// Only log in profile mode
  static void profileOnly(String message, {String tag = 'Profile'}) {
    if (kProfileMode) {
      _log(LogLevel.info, message, tag: tag);
    }
  }

  // ========== UTILITY METHODS ==========

  /// Disable all logs
  static void disableAll() {
    enableLogsInDebug = false;
    enableLogsInRelease = false;
  }

  /// Enable all logs (use carefully!)
  static void enableAll() {
    enableLogsInDebug = true;
    enableLogsInRelease = true;
  }

  /// Set minimum log level
  static void setMinimumLevel(LogLevel level) {
    minimumLogLevel = level;
  }

  /// Print current configuration
  static void printConfig() {
    print('\n========== AppLogger Configuration ==========');
    print(
      'Build Mode: ${kDebugMode
          ? 'DEBUG'
          : kReleaseMode
          ? 'RELEASE'
          : 'PROFILE'}',
    );
    print('Logs Enabled (Debug): $enableLogsInDebug');
    print('Logs Enabled (Release): $enableLogsInRelease');
    print('Minimum Level: ${minimumLogLevel.name}');
    print('Colors Enabled: $enableColors');
    print('Timestamps Enabled: $enableTimestamps');
    print('===========================================\n');
  }
}

// AppLogger.d('App started', tag: 'Main');
// AppLogger.apiRequest(method: 'GET', url: 'https://api.com/data');
// AppLogger.s('Operation complete', tag: 'Worker');

// ============================================================================
// 🎯 USAGE EXAMPLES - HOW TO USE EVERYWHERE
// ============================================================================

/*

// ========== 1. BASIC USAGE ==========
void example1() {
  AppLogger.d('Debug message');
  AppLogger.i('Info message');
  AppLogger.w('Warning message');
  AppLogger.e('Error message');
  AppLogger.s('Success message');
}

// ========== 2. WITH TAGS ==========
void example2() {
  AppLogger.d('Loading history...', tag: 'AutonomousBG');
  AppLogger.s('✅ Successfully got 8 songs', tag: 'Pollinations');
  AppLogger.e('Failed to save', tag: 'Database');
}

// ========== 3. WITH DATA ==========
void example3() {
  AppLogger.i('User logged in', tag: 'Auth', data: {
    'userId': '12345',
    'timestamp': DateTime.now().toString(),
  });
}

// ========== 4. ERROR LOGGING ==========
void example4() {
  try {
    throw Exception('Something went wrong');
  } catch (e, stack) {
    AppLogger.e(
      'Operation failed',
      tag: 'Service',
      error: e,
      stackTrace: stack,
    );
  }
}

// ========== 5. NETWORK LOGGING ==========
void example5() async {
  final stopwatch = Stopwatch()..start();
  
  AppLogger.apiRequest(
    method: 'POST',
    url: 'https://api.example.com/users',
    body: {'name': 'John'},
  );
  
  // ... make request ...
  
  stopwatch.stop();
  AppLogger.apiResponse(
    statusCode: 200,
    url: 'https://api.example.com/users',
    body: {'id': '123'},
    duration: stopwatch.elapsed,
  );
}

// ========== 6. SECTION DIVIDERS ==========
void example6() {
  AppLogger.section('Run #2 started', tag: 'AutonomousBG');
  // ... do work ...
  AppLogger.section('Run #2 finished', tag: 'AutonomousBG');
}

// ========== 7. PERFORMANCE TRACKING ==========
void example7() async {
  final stopwatch = Stopwatch()..start();
  
  // ... expensive operation ...
  await Future.delayed(Duration(milliseconds: 250));
  
  stopwatch.stop();
  AppLogger.perf('Database query', stopwatch.elapsed);
}

// ========== 8. CONDITIONAL LOGGING ==========
void example8() {
  AppLogger.debugOnly('This only shows in debug');
  AppLogger.releaseOnly('This only shows in release');
}

// ========== 9. CLEAN ARCHITECTURE USAGE ==========

// Domain Layer
class GetUserUseCase {
  Future<User> call(String id) async {
    AppLogger.trace('GetUserUseCase.call', tag: 'Domain');
    // ... logic ...
    return User();
  }
}

// Data Layer
class UserRepositoryImpl {
  Future<User> getUser(String id) async {
    AppLogger.d('Fetching user: $id', tag: 'Repository');
    // ... fetch logic ...
    AppLogger.s('User fetched successfully', tag: 'Repository');
    return User();
  }
}

// Presentation Layer
class UserBloc {
  void loadUser(String id) {
    AppLogger.d('Loading user', tag: 'UserBloc');
    // ... bloc logic ...
  }
}

// ========== 10. CONFIGURATION ==========
void setupLogger() {
  // Configure at app startup
  AppLogger.enableColors = true;
  AppLogger.enableTimestamps = true;
  AppLogger.maxTagLength = 20;
  
  // Set minimum level (e.g., only show warnings and errors)
  // AppLogger.setMinimumLevel(LogLevel.warning);
  
  // Print current config
  AppLogger.printConfig();
}

*/
