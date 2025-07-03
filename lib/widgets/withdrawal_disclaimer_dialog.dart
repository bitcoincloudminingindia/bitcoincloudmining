import 'package:flutter/material.dart';

/// Ek reusable withdrawal disclaimer dialog widget.
class WithdrawalDisclaimerDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;
  final IconData icon;

  const WithdrawalDisclaimerDialog({
    super.key,
    this.title = 'Disclaimer',
    this.message =
        'This app is a simulation game. The BTC shown here is virtual and has no real monetary value. The withdrawal feature is for demo purposes only.',
    this.onContinue,
    this.onCancel,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 32),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onCancel != null) onCancel!();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            if (onContinue != null) onContinue!();
          },
          child: const Text('I Understand, Continue'),
        ),
      ],
    );
  }
}

/// Helper function jo dialog show karta hai
dynamic showWithdrawalDisclaimerDialog({
  required BuildContext context,
  String? title,
  String? message,
  VoidCallback? onContinue,
  VoidCallback? onCancel,
  IconData? icon,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => WithdrawalDisclaimerDialog(
      title: title ?? 'Disclaimer',
      message: message ??
          'This app is a simulation game. The BTC shown here is virtual and has no real monetary value. The withdrawal feature is for demo purposes only.',
      onContinue: onContinue,
      onCancel: onCancel,
      icon: icon ?? Icons.warning_amber_rounded,
    ),
  );
}

/// Example usage (comment):
///
/// ElevatedButton(
///   onPressed: () {
///     showWithdrawalDisclaimerDialog(
///       context: context,
///       onContinue: () {
///         // Yahan aap withdrawal screen open kar sakte hain
///       },
///     );
///   },
///   child: Text('Withdraw'),
/// )
