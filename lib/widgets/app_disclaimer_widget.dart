import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppDisclaimerWidget extends StatelessWidget {
  final bool showFullDisclaimer;
  final VoidCallback? onAccept;

  const AppDisclaimerWidget({
    super.key,
    this.showFullDisclaimer = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    if (!showFullDisclaimer) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Simulation app - For entertainment only',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Important Notice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appDisclaimer,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Key Points:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• This is a gaming/simulation application'),
                Text('• No real Bitcoin mining occurs'),
                Text('• All rewards are virtual and for entertainment'),
                Text('• Real withdrawals require actual deposits'),
                Text('• Ads help support the free app experience'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAccept?.call();
                  },
                  child: const Text('I Understand'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, {VoidCallback? onAccept}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDisclaimerWidget(
        showFullDisclaimer: true,
        onAccept: onAccept,
      ),
    );
  }
}