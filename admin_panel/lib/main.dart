import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/storage_utils.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/admin_notifications_screen.dart';
import 'screens/admin_withdraw_screen.dart';
import 'screens/users_screen.dart';
import 'screens/user_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _determineInitialRoute(),
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'Bitcoin Mining Admin Panel',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: Colors.grey[50],
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[800],
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.blue[800]),
              titleTextStyle: TextStyle(
                color: Colors.blue[800],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[400]!),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor:
                Color.fromRGBO(18, 18, 18, 1.0), // 0xFF121212
            appBarTheme: AppBarTheme(
              backgroundColor: Color.fromRGBO(31, 31, 31, 1.0), // 0xFF1F1F1F
              foregroundColor: Colors.blue[300],
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.blue[300]),
              titleTextStyle: TextStyle(
                color: Colors.blue[300],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[700],
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            cardTheme: CardTheme(
              color: const Color(0xFF1F1F1F),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[400]!),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          themeMode: ThemeMode.system,
          initialRoute: snapshot.data ?? LoginScreen.routeName,
          routes: {
            '/': (context) => const LoginScreen(),
            LoginScreen.routeName: (context) => const LoginScreen(),
            AdminDashboard.routeName: (context) => const AdminDashboard(),
            AdminNotificationsScreen.routeName: (context) =>
                const AdminNotificationsScreen(),
            AdminWithdrawScreen.routeName: (context) =>
                const AdminWithdrawScreen(),
            UsersScreen.routeName: (context) => const UsersScreen(),
            UserDetailsScreen.routeName: (context) => const UserDetailsScreen(),
          },
        );
      },
    );
  }

  Future<String> _determineInitialRoute() async {
    // Check if user is already logged in
    final token = await StorageUtils.getToken();
    if (token?.isNotEmpty == true) {
      return AdminDashboard.routeName;
    }
    return LoginScreen.routeName;
  }
}
