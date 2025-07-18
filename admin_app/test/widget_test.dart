// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:bitcoin_cloud_mining_admin/main.dart';
import 'package:bitcoin_cloud_mining_admin/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Admin app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AdminApp());

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AdminApp());

    // Wait for initialization
    await tester.pumpAndSettle();

    // Verify that login screen is shown when not authenticated
    expect(find.byType(LoginScreen), findsOneWidget);

    // Verify login form elements are present
    expect(
      find.byType(TextFormField),
      findsAtLeast(2),
    ); // Email and password fields
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AdminApp());

    // Verify that the app initializes properly
    expect(find.byType(ResponsiveWrapper), findsOneWidget);
    expect(find.byType(AdminHome), findsOneWidget);
  });
}
