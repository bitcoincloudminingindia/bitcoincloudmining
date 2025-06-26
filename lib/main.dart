import 'dart:io' show Platform;

import 'package:bitcoin_cloud_mining/config/api_config.dart';
import 'package:bitcoin_cloud_mining/models/notification.dart' as model;
import 'package:bitcoin_cloud_mining/providers/auth_provider.dart';
import 'package:bitcoin_cloud_mining/providers/notification_provider.dart';
import 'package:bitcoin_cloud_mining/providers/reward_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/screens/launch_screen.dart';
import 'package:bitcoin_cloud_mining/screens/loading_user_data_screen.dart';
import 'package:bitcoin_cloud_mining/screens/navigation_screen.dart';
import 'package:bitcoin_cloud_mining/screens/notification_screen.dart';
import 'package:bitcoin_cloud_mining/screens/wallet_screen.dart';
import 'package:bitcoin_cloud_mining/services/api_service.dart';
import 'package:bitcoin_cloud_mining/services/notification_service.dart';
import 'package:bitcoin_cloud_mining/utils/enums.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:workmanager/workmanager.dart';

import 'fcm_service.dart';
import 'utils/storage_utils.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Set zone error handling to non-fatal
  BindingBase.debugZoneErrorsAreFatal = false;

  // Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and FCM (Android only)
  await Firebase.initializeApp();
  await FcmService.initializeFCM();

  // Only initialize window_manager on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      windowManager.ensureInitialized().then((_) {
        const WindowOptions windowOptions = WindowOptions(
          size: Size(800, 600),
          minimumSize: Size(800, 600),
          backgroundColor: Colors.transparent,
          title: 'Bitcoin Cloud Mining',
          titleBarStyle: TitleBarStyle.normal,
        );
        windowManager.waitUntilReadyToShow(windowOptions).then((_) {
          windowManager.show();
          windowManager.focus();
          windowManager.setPreventClose(true);
        });
      });
    } catch (e) {
      print('Platform initialization error: $e');
    }
  }

  // Always initialize mobile ads on supported platforms (not web)
  if (!kIsWeb) {
    try {
      MobileAds.instance.initialize();
      // Register native ad factory only on Android/iOS, and only if implemented natively
      if (Platform.isAndroid || Platform.isIOS) {
        // MobileAds.instance.registerNativeAdFactory('listTile', ...);
        // Register your native ad factory in native code, not Dart.
      }
    } catch (e) {
      print('Mobile Ads initialization error: $e');
    }
  }

  // Initialize background tasks if not on web
  if (!kIsWeb) {
    try {
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      // Removed periodic mining and cloud mining task registration for manual mining only
    } catch (e) {
      print('Background task initialization error: $e');
    }
  }

  // Initialize services
  final apiService = ApiService();
  final notificationService = NotificationService(
      baseUrl: kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000',
      apiService: apiService);

  // Run the app
  runApp(MyApp(
    apiService: apiService,
    notificationService: notificationService,
  ));
}

class MyApp extends StatefulWidget {
  final ApiService apiService;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.apiService,
    required this.notificationService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _setupFCM();
    _setupNotificationListeners();
  }

  Future<void> _setupFCM() async {
    await FcmService.requestPermission();
    final token = await FcmService.getFcmToken();
    if (token != null) {
      await sendTokenToBackend(token);
    }
    FcmService.listenFCM();
  }

  void _setupNotificationListeners() {
    // Listen for local notification taps
    widget.notificationService.selectNotificationSubject.listen((payload) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        final notification = model.Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Local Notification',
          body: payload ?? '',
          status: 'unread',
          timestamp: DateTime.now(),
          category: NotificationCategory.system,
          payload: payload,
        );
        provider.addNotificationFromLocal(notification);
      }
    });

    // Listen for FCM foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        final notification = model.Notification(
          id: message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification?.title ?? 'Push Notification',
          body: message.notification?.body ?? '',
          status: 'unread',
          timestamp: DateTime.now(),
          category: NotificationCategory.system,
          payload: message.data['payload'],
        );
        provider.addNotificationFromLocal(notification);
      }
    });
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      final jwtToken = await StorageUtils.getToken();
      final url = Uri.parse(ApiConfig.fcmTokenUrl);
      final headers = ApiConfig.getHeaders(token: jwtToken);
      final response = await http.post(
        url,
        headers: headers,
        body: '{"token": "$token"}',
      );
      if (response.statusCode == 200) {
        print('FCM token sent to backend successfully');
      } else {
        print('Failed to send FCM token to backend: \\${response.body}');
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowEvent(String eventName) {
    print('[WindowManager] onWindowEvent: $eventName');
  }

  @override
  void onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      final bool? shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm close'),
            content: const Text('Are you sure you want to close the app?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      if (shouldClose == true) {
        await windowManager.destroy();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WalletProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RewardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
              notificationService: widget.notificationService),
        ),
        Provider.value(value: widget.apiService),
        Provider.value(value: widget.notificationService),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Bitcoin Cloud Mining',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        initialRoute: '/launch',
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => const LaunchScreen(),
          '/launch': (context) => const LaunchScreen(),
          '/loading': (context) => const LoadingUserDataScreen(),
          '/wallet': (context) => const WalletScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/navigation': (context) => const NavigationScreen(),
        },
      ),
    );
  }
}
