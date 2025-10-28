import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:parent_rs/firebase_options.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/fcm_token_helper.dart';
import 'flutter_flow/awesome_notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for app to work)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize notifications without requesting permissions yet
  // This sets up the notification channels but doesn't block startup
  await AwesomeNotificationHelper.initializeWithoutPermissions();

  // Setup foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📱 Foreground notification received!');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show notification using AwesomeNotifications
    AwesomeNotificationHelper.showNotificationFromFirebase(message);
  });

  // FCM token refresh listener'ni sozlash
  FCMTokenHelper.setupTokenRefreshListener();

  // Start the app immediately - don't wait for permissions or tokens
  runApp(const MyApp());

  // Initialize Firebase Messaging and FCM token asynchronously after app starts
  // This prevents blocking the UI
  _initializeMessagingAsync();
}

/// Initialize Firebase Messaging and FCM token asynchronously
/// This runs after the app UI is displayed to avoid blocking startup
Future<void> _initializeMessagingAsync() async {
  try {
    debugPrint('🚀 Starting async Firebase Messaging initialization...');

    // Add a small delay to ensure app UI is fully rendered
    await Future.delayed(const Duration(milliseconds: 500));

    // Request notification permissions first (AwesomeNotifications)
    // This is the primary notification system for the app
    debugPrint('📱 Requesting notification permissions...');
    await AwesomeNotificationHelper.requestPermissions();
    debugPrint('✅ Notification permissions requested');

    // Small delay between permission requests to avoid conflicts
    await Future.delayed(const Duration(milliseconds: 300));

    // Request Firebase Messaging permission
    debugPrint('🔔 Requesting Firebase Messaging permission...');
    await FirebaseMessaging.instance.requestPermission();
    debugPrint('✅ Firebase Messaging permission requested');

    // Get FCM token (non-blocking, happens in background)
    final token = await FCMTokenHelper.getFCMToken();
    debugPrint('✅ Initial FCM Token: $token');
  } catch (e) {
    debugPrint('⚠️ Error during async messaging initialization: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e as RouteMatch))
          .toList();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'LMS-RS',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
