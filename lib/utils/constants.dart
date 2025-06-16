import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E88E5);
  static const secondary = Color(0xFF42A5F5);
  static const accent = Color(0xFFFFB74D);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFE53935);
  static const text = Color(0xFF212121);
  static const textLight = Color(0xFF757575);
}

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );

  static const caption = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );
}

class AppDimensions {
  static const double padding = 16.0;
  static const double margin = 16.0;
  static const double radius = 8.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
}

class AppAnimations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}

class AppStrings {
  // Auth
  static const signUp = 'Sign Up';
  static const login = 'Login';
  static const logout = 'Logout';
  static const name = 'Name';
  static const username = 'Username';
  static const email = 'Email';
  static const phone = 'Phone Number';
  static const dob = 'Date of Birth';
  static const password = 'Password';
  static const confirmPassword = 'Confirm Password';
  static const alreadyHaveAccount = 'Already have an account? Login';
  static const dontHaveAccount = "Don't have an account? Sign Up";
  static const forgotPassword = 'Forgot Password?';
  static const resetPassword = 'Reset Password';
  static const sendResetLink = 'Send Reset Link';
  static const backToLogin = 'Back to Login';

  // Registration and OTP
  static const noInternetConnection = 'No internet connection';
  static const registrationSuccessful = 'Registration successful';
  static const registrationFailed = 'Registration failed';
  static const registrationError = 'Registration error';
  static const enterOtp = 'Enter OTP';
  static const invalidOtp = 'Invalid OTP';
  static const verificationError = 'Verification error';
  static const verifyEmail = 'Verify Email';
  static const enterVerificationCode = 'Enter verification code';
  static const enterSixDigitCode = 'Enter 6-digit code';
  static const otpResendSuccess = 'OTP resent successfully';
  static const otpResendFailed = 'Failed to resend OTP';
  static const resendCode = 'Resend Code';
  static const verify = 'Verify';

  // Validation
  static const required = 'This field is required';
  static const invalidEmail = 'Please enter a valid email';
  static const invalidPhone = 'Please enter a valid 10-digit phone number';
  static const passwordTooShort = 'Password must be at least 6 characters';
  static const usernameTooShort = 'Username must be at least 3 characters';
  static const passwordsDontMatch = 'Passwords do not match';

  // Success
  static const signUpSuccess = 'Sign up successful';
  static const loginSuccess = 'Login successful';
  static const profileUpdateSuccess = 'Profile updated successfully';
  static const passwordUpdateSuccess = 'Password updated successfully';
  static const resetLinkSent =
      'Password reset link has been sent to your email';

  // Errors
  static const error = 'Error';
  static const networkError = 'Network error';
  static const serverError = 'Server error';
  static const unknownError = 'Something went wrong';
  static const invalidCredentials = 'Invalid credentials';

  // Welcome Messages
  static const appTitle = 'Bitcoin Cloud Mining';
  static const welcomeBack = 'Welcome back to your account';
  static const createAccount = 'Create a new account';
  static const resetPasswordMessage =
      'Enter your registered email and we will send you a reset link';
}

class ApiConstants {
  static const String baseUrl = 'http://localhost:5000/api';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(minutes: 15);
  static const String apiVersion = '/v1';

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String login = '/api/auth/login';
  static const String resetPassword = '/api/auth/reset-password';
  static const String validateToken = '/api/auth/validate-token';

  // Full endpoint getters
  static String getFullUrl(String endpoint) => baseUrl + endpoint;

  // Headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}

class WalletConstants {
  static const double minWithdrawalBtc = 0.0000000001;
  static const double minWithdrawalUsd = 1.0;
  static const double minWithdrawalInr = 100.0;
  static const double dailyWithdrawalLimit = 1.0; // BTC
  static const int transactionHistoryLimit = 50;
  static const Duration balanceUpdateInterval = Duration(minutes: 1);
}

class ValidationConstants {
  static const String passwordRegex =
      r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%^&*])';
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String btcAddressRegex = r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
}

class UIConstants {
  static const double buttonHeight = 48.0;
  static const double inputRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double defaultPadding = 16.0;
}
