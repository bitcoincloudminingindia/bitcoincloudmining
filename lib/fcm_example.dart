import 'dart:async';

import 'package:bitcoin_cloud_mining/config/api_config.dart';
import 'package:bitcoin_cloud_mining/fcm_service.dart';
import 'package:bitcoin_cloud_mining/utils/storage_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FcmService.initializeFCM();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    await FcmService.requestPermission();
    final token = await FcmService.getFcmToken();
    setState(() => _fcmToken = token);
    debugPrint('FCM Token: $token');
    if (token != null) {
      await sendTokenToBackend(token);
    }
    FcmService.listenFCM();
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
        debugPrint('FCM token sent to backend successfully');
      } else {
        debugPrint('Failed to send FCM token to backend: \\${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending FCM token to backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FCM Example')),
        body: Center(
          child: SelectableText(
            _fcmToken == null
                ? 'Fetching FCM token...'
                : 'FCM Token:\n$_fcmToken',
          ),
        ),
      ),
    );
  }
}
