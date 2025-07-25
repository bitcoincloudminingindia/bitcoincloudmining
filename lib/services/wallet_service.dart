import 'api_service.dart';

class WalletService {
  final ApiService _apiService = ApiService();
  Future<Map<String, dynamic>> initializeWallet() async {
    try {
      final response = await _apiService.makeRequest(
        endpoint: '/api/wallet/initialize',
        method: 'POST',
      );

      // FIX: Use parentheses for type check
      if (!response['success'] || response['data'] is! Map<String, dynamic>) {
        throw Exception(response['message'] ?? 'Failed to initialize wallet');
      }

      final data = response['data'] as Map<String, dynamic>;

      // Ensure we got a valid wallet response
      if (data['balance'] == null) {
        throw Exception('Invalid wallet data: missing balance');
      }

      // Return the initialized wallet data
      return data;
    } catch (e) {
      // Check if it's a DNS error and provide better message
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('no address associated with hostname')) {
        throw Exception(
            'Network connection issue. Please check your internet connection and try again.');
      }

      rethrow;
    }
  }

  Future<double> getWalletBalance() async {
    try {
      final response = await _apiService.makeRequest(
        endpoint: '/api/wallet/balance',
        method: 'GET',
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Failed to get wallet balance');
      }

      final balance = response['data']['balance'] ?? '0.000000000000000000';
      return double.tryParse(balance) ?? 0.0;
    } catch (e) {
      // Check if it's a DNS error and provide better message
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('no address associated with hostname')) {
        throw Exception(
            'Network connection issue. Please check your internet connection and try again.');
      }

      rethrow;
    }
  }
}
