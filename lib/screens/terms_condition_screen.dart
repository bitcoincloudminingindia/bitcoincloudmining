import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class TermsConditionScreen extends StatelessWidget {
  final String appName;
  final String supportEmail;
  const TermsConditionScreen({
    super.key,
    this.appName = 'Bitcoin Cloud Mining',
    this.supportEmail = 'bitcoincloudminingformobile@gmail.com',
  });

  @override
  Widget build(BuildContext context) {
    final String dynamicLastUpdated =
        DateFormat('MMMM yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E), // Deep blue
                Color(0xFF0D47A1), // Darker blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Deep blue
              Color(0xFF0D47A1), // Darker blue
            ],
          ),
        ),
        child: Container(
          color: Colors.black.withAlpha(128),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: """
**Terms & Conditions**  
_Last Updated: ${dynamicLastUpdated}_

Welcome to **$appName**. By using our app, you agree to the following terms and conditions. Please read them carefully before using the service.

## 1. Acceptance of Terms  
By accessing or using **$appName**, you confirm that you have read, understood, and agreed to these Terms & Conditions. If you do not agree, please do not use the app.

## 2. Eligibility  
- You must be at least **18 years old** or the age of majority in your jurisdiction.  
- By using the app, you confirm that you are legally allowed to participate in virtual Bitcoin mining and transactions.

## 3. App Usage & Mining  
- **$appName** provides Bitcoin cloud mining services.
- Mining earnings are paid in real BTC and can be withdrawn to your external wallet.
- Mining rates may vary based on network conditions and your mining power.
- The app may offer **power-ups** and **boosters** to enhance your mining speed.
- **Rewarded ads** are available to boost your mining earnings.

## 4. Wallet & Transactions  
- Your **in-app wallet** stores your real BTC balance.
- The minimum withdrawal amount is 0.000000000000000001 BTC.
- Withdrawals are processed within 48 hours.
- No transaction fees are charged for withdrawals.
- The app reserves the right to delay or deny withdrawals if fraudulent activity is suspected.

## 5. Prohibited Activities  
You agree **not** to:  
- Use bots, automation, or scripts to manipulate mining or rewards.  
- Engage in hacking, fraudulent activities, or exploits to gain an unfair advantage.  
- Violate any applicable laws or attempt to launder funds through the app.

## 6. Advertisements & Monetization  
- The app may display advertisements, including **rewarded ads** that provide in-app benefits.  
- Ad-blocking tools may impact the app's functionality and could result in limited access to features.

## 7. Account Suspension & Termination  
We reserve the right to suspend or terminate accounts that:  
- Violate these Terms & Conditions.  
- Engage in fraudulent activities or abuse the system.  
- Remain inactive for an extended period.

## 8. No Guarantees & Liability Disclaimer  
- We do not guarantee specific earnings, rewards, or profits from using the app.  
- The app is provided "as-is," and we are **not responsible** for any financial losses or damages arising from app usage.  
- Cryptocurrency markets are volatile. Any **Bitcoin value estimations** in the app are purely for informational purposes.

## 9. Changes to Terms  
We may update these Terms & Conditions at any time. Continued use of the app after updates constitutes acceptance of the revised terms.

## 10. Contact Us  
If you have any questions about these terms, please contact us at **$supportEmail**.

---
By using **$appName**, you acknowledge and agree to these Terms & Conditions.
""",
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, color: Colors.white),
                strong: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
                em: const TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.white),
                h2: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
