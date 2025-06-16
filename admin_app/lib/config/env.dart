class Env {
  static const String apiUrl = 'http://your-backend-url:5000/api';
  static const String adminApiUrl = '$apiUrl/admin';
  static const Duration tokenExpiry = Duration(hours: 24);
  static const Duration apiTimeout = Duration(seconds: 30);
}