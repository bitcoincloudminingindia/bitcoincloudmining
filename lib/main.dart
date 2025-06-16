import 'dart:async';
import 'dart:convert';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' show document, HTMLScriptElement;
import 'package:window_manager/window_manager.dart';
import 'package:workmanager/workmanager.dart';

const String miningTask = 'startMiningTask';
const String cloudMiningTask = 'startCloudMiningTask';

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

  // Initialize platform specific features
  if (!kIsWeb) {
    try {
      // Initialize window manager
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

      // Initialize mobile ads
      MobileAds.instance.initialize();
    } catch (e) {
      print('Platform initialization error: $e');
    }
  } else {
    try {
      // Web specific initialization
      const int webHeapSize = 32768;
      const String javaScriptFlags =
          '--max_old_space_size=$webHeapSize --optimize-for-size --max-old-space-size=32768 --gc-interval=10 --js-flags="--expose-gc --max-old-space-size=32768"';

      final scriptElement =
          document.createElement('script') as HTMLScriptElement;
      scriptElement.text = '''
        if (typeof window !== 'undefined') {
          window.flutterWebRenderer = "html";
          window.JsConfig = {
            'flags': '$javaScriptFlags'
          };
          
          setInterval(() => {
            if (window.performance && window.performance.memory) {
              const used = Math.round(window.performance.memory.usedJSHeapSize / 1048576);
              if (used > 28000 && window.gc) {
                window.gc();
              }
            }
          }, 500);

          // Initialize Google Mobile Ads for web
          window.google = window.google || {};
          window.google.mobileads = {
            initialize: () => {
              console.log('Google Mobile Ads initialized for web');
              return Promise.resolve();
            },
            loadInterstitialAd: () => {
              console.log('Loading interstitial ad for web');
              return Promise.resolve();
            },
            loadRewardedAd: () => {
              console.log('Loading rewarded ad for web');
              return Promise.resolve();
            },
            loadNativeAd: () => {
              console.log('Loading native ad for web');
              return Promise.resolve();
            },
            disposeAd: () => {
              console.log('Disposing ad for web');
              return Promise.resolve();
            }
          };
        }
      ''';
      document.body?.appendChild(scriptElement);
    } catch (e) {
      print('Web initialization error: $e');
    }
  }

  // Initialize background tasks if not on web
  if (!kIsWeb) {
    try {
      Workmanager()
          .initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      )
          .then((_) {
        // Register mining tasks
        Workmanager().registerPeriodicTask(
          'mining_periodic_task',
          miningTask,
          frequency: const Duration(minutes: 5),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
          existingWorkPolicy: ExistingWorkPolicy.keep,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 1),
        );

        Workmanager().registerPeriodicTask(
          'cloud_mining_periodic_task',
          cloudMiningTask,
          frequency: const Duration(minutes: 10),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
          existingWorkPolicy: ExistingWorkPolicy.keep,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 2),
        );
      });
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

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double currentBalance = prefs.getDouble('btcBalance') ?? 0.0;
      final List<String> txJsonList = prefs.getStringList('transactions') ?? [];
      final DateTime now = DateTime.now();

      // Get last mining time with better error handling
      DateTime lastMiningTime;
      try {
        final lastMiningTimeStr = prefs.getString('lastMiningTime');
        lastMiningTime = lastMiningTimeStr != null
            ? DateTime.parse(lastMiningTimeStr)
            : now.subtract(const Duration(minutes: 5));
      } catch (e) {
        print('Last mining time parsing error: $e');
        lastMiningTime = now.subtract(const Duration(minutes: 5));
      }

      // Calculate time difference in minutes with validation
      final minutesDiff = now.difference(lastMiningTime).inMinutes;
      if (minutesDiff < 0) {
        print('Invalid time difference: $minutesDiff');
        return Future.value(false);
      }

      if (task == miningTask) {
        // Calculate mining reward with improved rate
        const double baseMiningRate =
            0.000000000000000003; // Increased base rate
        final double miningReward = baseMiningRate * minutesDiff;

        // Update balance with validation
        if (miningReward > 0) {
          currentBalance += miningReward;
          await prefs.setDouble('btcBalance', currentBalance);
          await prefs.setString('lastMiningTime', now.toIso8601String());

          // Record transaction with more details
          final transaction = {
            'type': 'Mining',
            'amount': miningReward,
            'date': now.toIso8601String(),
            'status': 'Completed',
            'source': 'Background Mining',
            'duration': minutesDiff,
            'rate': baseMiningRate.toString(),
            'deviceInfo': {
              'platform': Platform.operatingSystem,
              'version': Platform.operatingSystemVersion,
            }
          };
          txJsonList.insert(0, json.encode(transaction));
          await prefs.setStringList('transactions', txJsonList);

          print('✅ Background mining completed: $miningReward BTC earned');
        }

        return Future.value(true);
      } else if (task == cloudMiningTask) {
        // Calculate cloud mining reward with improved rate
        const double baseCloudRate =
            0.000000000000000006; // Increased base rate
        final double cloudReward = baseCloudRate * minutesDiff;

        // Update balance with validation
        if (cloudReward > 0) {
          currentBalance += cloudReward;
          await prefs.setDouble('btcBalance', currentBalance);
          await prefs.setString('lastCloudMiningTime', now.toIso8601String());

          // Record transaction with more details
          final transaction = {
            'type': 'Cloud Mining',
            'amount': cloudReward,
            'date': now.toIso8601String(),
            'status': 'Completed',
            'source': 'Background Cloud Mining',
            'duration': minutesDiff,
            'rate': baseCloudRate.toString(),
            'deviceInfo': {
              'platform': Platform.operatingSystem,
              'version': Platform.operatingSystemVersion,
            }
          };
          txJsonList.insert(0, json.encode(transaction));
          await prefs.setStringList('transactions', txJsonList);

          print('✅ Background cloud mining completed: $cloudReward BTC earned');
        }

        return Future.value(true);
      }
      return Future.value(false);
    } catch (e) {
      print('Background mining task error: $e');
      return Future.value(false);
    }
  });
}
