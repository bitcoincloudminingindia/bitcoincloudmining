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
**This app is a simulation. All BTC and wallet balance shown are virtual and have no real monetary value.**

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
- BTC rewards are credited based on ad interactions and app tasks. Real BTC withdrawals are subject to our payout policy.
- Mining rates may vary based on network conditions and your mining power.
- The app may offer **power-ups** and **boosters** to enhance your mining speed.
- **Rewarded ads** are available to boost your mining earnings.

## 4. Wallet & Transactions  
- This wallet displays your virtual BTC balance earned through gameplay and rewarded ads.  
- The minimum withdrawal amount is 0.00005 BTC.  
- Withdrawals are subject to our minimum threshold and processed manually after review. Withdrawals are usually processed within 48 hours.  
- No transaction fees are charged for withdrawals.  
- ⚠️ This is a virtual mining simulation app. All BTC shown is virtual. Withdrawals are enabled only when minimum thresholds are reached and verified.  
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

Privacy Policy: https://doc-hosting.flycricket.io/bitcoin-cloud-mining-privacy-policy/140d10f0-13a2-42a0-a93a-ec68298f58db/privacy
Terms & Conditions: https://doc-hosting.flycricket.io/bitcoin-cloud-mining-terms-of-use/8c21ec3c-9f18-4255-8ec1-9c8a4c98bf95/terms
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

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E),
                Color(0xFF0D47A1),
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
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: Container(
          color: Colors.black.withAlpha(128),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '⚠️ This is a virtual mining simulation app. All BTC shown is virtual. Withdrawals are enabled only when minimum thresholds are reached and verified.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our app.\n\nWe do not share your personal information with third parties except as necessary to provide our services or as required by law.\n\nWe may update this Privacy Policy from time to time. Continued use of the app after updates constitutes acceptance of the revised policy.\n\nFor any questions, contact us at bitcoincloudminingformobile@gmail.com.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
