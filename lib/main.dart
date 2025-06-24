import 'dart:io' show Platform;

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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:workmanager/workmanager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Set zone error handling to non-fatal
  BindingBase.debugZoneErrorsAreFatal = false;

  // Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final apiService = ApiService();
  final notificationService = NotificationService(
      baseUrl: kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000',
      apiService: apiService);

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

