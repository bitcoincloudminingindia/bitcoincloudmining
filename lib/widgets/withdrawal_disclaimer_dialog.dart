import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WithdrawalDisclaimerDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinue;
  final IconData icon;

  static const Color kBlue = Color(0xFF1976D2); // Material Blue 700

  const WithdrawalDisclaimerDialog({
    super.key,
    this.title = 'Disclaimer',
    this.message =
        '⚠️ This is a virtual mining simulation app. All BTC shown is virtual. Withdrawals are enabled only when minimum thresholds are reached and verified.',
    this.onContinue,
    this.icon = Icons.warning_amber_rounded,
  });

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _exitApp(BuildContext context) {
    // Android/iOS दोनों के लिए exit
    Navigator.of(context).pop();
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top bar indicator (like image)
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Icon(icon, color: kBlue, size: 56),
            const SizedBox(height: 18),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onContinue != null) onContinue!();
                    },
                    child: const Text(
                      'Agree and Continue',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _exitApp(context),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: kBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                text: 'By continuing, you agree with our ',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                children: [
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: kBlue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _launchUrl(
                          'https://doc-hosting.flycricket.io/bitcoin-cloud-mining-privacy-policy/e7bf1a89-eb0d-4b5b-bf33-f72ca57b4e64/privacy'),
                  ),
                  const TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: const TextStyle(
                      color: kBlue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _launchUrl(
                          'https://doc-hosting.flycricket.io/bitcoin-cloud-mining-terms-of-use/44cea453-e05c-463b-bfb6-cd64fbdfe0a7/terms'),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function
Future<void> showWithdrawalDisclaimerDialog({
  required BuildContext context,
  String? title,
  String? message,
  VoidCallback? onContinue,
  IconData? icon,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => WithdrawalDisclaimerDialog(
      title: title ?? 'Disclaimer',
      message: message ??
          '⚠️ This is a virtual mining simulation app. All BTC shown is virtual. Withdrawals are enabled only when minimum thresholds are reached and verified.',
      onContinue: onContinue,
      icon: icon ?? Icons.warning_amber_rounded,
    ),
  );
}
