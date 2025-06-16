import 'package:flutter/material.dart';

class ErrorHandler {
  static void handleError(BuildContext context, dynamic error) {
    String errorMessage = 'An error occurred';

    if (error is NetworkError) {
      errorMessage = 'Network error: Please check your internet connection';
    } else if (error is AuthenticationError) {
      errorMessage = 'Authentication error: Please login again';
    } else if (error is ValidationError) {
      errorMessage = 'Validation error: ${error.message}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class NetworkError implements Exception {
  final String message;
  NetworkError([this.message = 'Network error']);
}

class AuthenticationError implements Exception {
  final String message;
  AuthenticationError([this.message = 'Authentication error']);
}

class ValidationError implements Exception {
  final String message;
  ValidationError([this.message = 'Validation error']);
}
