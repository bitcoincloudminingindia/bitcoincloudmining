import 'package:flutter/material.dart';

class WithdrawalEligibilityWidget extends StatelessWidget {
  final double btcBalance;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  static const double minBtc = 0.00005;

  const WithdrawalEligibilityWidget({
    super.key,
    required this.btcBalance,
    this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final eligible = btcBalance >= minBtc;
    final theme = Theme.of(context);
    return Center(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: eligible ? Colors.green[50] : Colors.blue[50],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Icon(
                  eligible ? Icons.verified_rounded : Icons.lock_clock,
                  size: 48,
                  color: eligible ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Withdrawal Eligibility',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'Your Balance:',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${btcBalance.toStringAsFixed(8)} BTC',
                style: TextStyle(
                  color: eligible ? Colors.green[800] : Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: eligible ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      eligible ? Icons.check_circle : Icons.info_outline,
                      color: eligible ? Colors.green : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        eligible
                            ? 'You are eligible for withdrawal!'
                            : 'Withdrawals will be available once your balance reaches 0.00005 BTC.',
                        style: TextStyle(
                          color:
                              eligible ? Colors.green[900] : Colors.blue[900],
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Back', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: eligible ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: eligible ? 4 : 0,
                    ),
                    child: const Text('Next', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
