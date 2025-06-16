class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);
}

class AuthenticationError implements Exception {
  final String message;
  AuthenticationError(this.message);
}

class NetworkError implements Exception {
  final String message;
  NetworkError(this.message);
}

class ApiError implements Exception {
  final String message;
  final String? code;
  ApiError(this.message, {this.code});
}
