import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/storage_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.login),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await StorageUtils.saveToken(data['token']);

        // Save admin info if available
        if (data['admin'] != null) {
          await StorageUtils.saveAdminInfo(
            id: data['admin']['id'] ?? '',
            name: data['admin']['username'] ?? '',
            email: data['admin']['email'] ?? '',
          );
        }

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.adminDashboard),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to get dashboard data'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAdminNotifications() async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.adminNotifications),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Failed to get admin notifications'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.allUsers),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to get users list'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.userDetails + userId),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to get user details'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Generic GET method for reusable API calls
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + endpoint),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'API request failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // General POST method for various API calls
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + endpoint),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'API request failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWithdrawals() async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.adminWithdrawals),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to get withdrawal data'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? adminNote,
  }) async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.updateTransaction),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'transactionId': transactionId,
          'status': status,
          'adminNote': adminNote,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Failed to update transaction status'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addUserData(
      Map<String, dynamic> userData) async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.addUserData),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add user data'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.refreshToken),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await StorageUtils.saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to refresh token'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> profileData) async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.updateUserProfile),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add new methods for bulk notifications
  Future<Map<String, dynamic>> sendBulkNotification(
      Map<String, dynamic> data) async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.sendBulkNotification),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to send notifications'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUsers() async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.users),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch users'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserGroups() async {
    try {
      final token = await StorageUtils.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.userGroups),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to fetch user groups'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
