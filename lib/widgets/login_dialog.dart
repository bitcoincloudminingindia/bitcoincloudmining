import 'dart:io' show exit, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/loading_user_data_screen.dart';
import '../screens/terms_condition_screen.dart';
import '../utils/constants.dart';
import '../utils/validators.dart' as form_validators;
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'sign_up_dialog.dart' as signup;

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      if (Platform.isAndroid || Platform.isIOS) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    }
    return false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Close login dialog
        Navigator.of(context).pop();

        // Show loading screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoadingUserDataScreen(),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      setState(() {
        _errorMessage = 'An error occurred during login. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(26, 35, 126, 0.95),
                Color.fromRGBO(13, 71, 161, 0.95),
                Color.fromRGBO(2, 119, 189, 0.95),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(51),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.currency_bitcoin,
                      size: 64,
                      color: Colors.amber[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.amber[400]!, Colors.amber[700]!],
                    ).createShader(bounds),
                    child: const Text(
                      AppStrings.appTitle,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.welcomeBack,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withAlpha(179),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.1),
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: form_validators.Validators.validateEmail,
                            prefixIcon: Icons.email,
                            prefixIconColor: Colors.grey[300],
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            borderColor: Colors.grey[300]!,
                            focusedBorderColor: Colors.grey[400]!,
                            backgroundColor: Colors.grey[900]!.withAlpha(26),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: !_isPasswordVisible,
                            validator:
                                form_validators.Validators.validatePassword,
                            prefixIcon: Icons.lock,
                            prefixIconColor: Colors.grey[300],
                            suffix: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[300],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            borderColor: Colors.grey[300]!,
                            focusedBorderColor: Colors.grey[400]!,
                            backgroundColor: Colors.grey[900]!.withAlpha(26),
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withAlpha(51),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[400]!.withAlpha(77),
                                  Colors.blue[600]!
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue[400]!.withAlpha(77),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomButton(
                              onPressed: _login,
                              text: AppStrings.login,
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ResetPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => const signup.SignUpDialog(),
                        barrierDismissible: false,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      AppStrings.dontHaveAccount,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'By continuing, I agree to our ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (context) => Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.85,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      child: TermsConditionScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Terms',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: ' & '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPolicyScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
