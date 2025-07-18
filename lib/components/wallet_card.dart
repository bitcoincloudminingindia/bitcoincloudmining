import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletCard extends StatefulWidget {
  const WalletCard({super.key});

  @override
  _WalletCardState createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _isLoading = true;
  String _error = '';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _setupWallet();
  }

  void _setupWallet() async {
    await _fetchBalance();
    _setupBalanceListener();
  }

  Future<void> _fetchBalance() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final balance = await _apiService.getWalletBalance();

      if (!mounted) return;

      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      walletProvider.updateBalance(balance);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupBalanceListener() {
    _apiService.onBalanceUpdate = (newBalance) {
      if (!mounted) return;
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      walletProvider.updateBalance(newBalance);
    };

    _apiService.onError = (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
      });
    };
  }

  @override
  void dispose() {
    _apiService.onBalanceUpdate = null;
    _apiService.onError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final balance = walletProvider.formattedBtcBalance;
    final btcPrice = walletProvider.btcPrice;
    final localBalance = btcPrice * double.parse(balance);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wallet Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_error.isNotEmpty)
              Text(
                _error,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$balance BTC',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${localBalance.toStringAsFixed(10)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _fetchBalance,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
