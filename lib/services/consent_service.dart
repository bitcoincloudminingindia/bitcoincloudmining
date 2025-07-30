import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  // Consent status constants
  static const String _consentStatusKey = 'user_consent_status';
  static const String _consentVersionKey = 'consent_version';
  static const String _consentTimestampKey = 'consent_timestamp';

  // Current consent version - increment when privacy policy changes
  static const String currentConsentVersion = '1.0';

  // Consent status
  bool _isConsentRequired = false;
  bool _hasUserConsent = false;
  bool _isInitialized = false;

  // Getters
  bool get isConsentRequired => _isConsentRequired;
  bool get hasUserConsent => _hasUserConsent;
  bool get isInitialized => _isInitialized;

  // Initialize consent service
  Future<void> initialize() async {
    try {
      _isConsentRequired = await _checkIfConsentRequired();

      if (_isConsentRequired) {
        await _loadConsentStatus();
      } else {
        _hasUserConsent = true; // No consent required for non-EU/CA users
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('ConsentService: Initialized');
        print('Consent Required: $_isConsentRequired');
        print('Has Consent: $_hasUserConsent');
      }
    } catch (e) {
      _isInitialized = true;
      _hasUserConsent = true; // Default to true on error
      if (kDebugMode) {
        print('ConsentService: Error during initialization: $e');
      }
    }
  }

  // Check if consent is required based on user location
  Future<bool> _checkIfConsentRequired() async {
    try {
      // For EU GDPR compliance, check if user is in EU
      // For CCPA compliance, check if user is in California
      // This is a simplified check - in production, use proper geolocation

      // You can implement actual geolocation check here
      // For now, we'll assume consent is required for all users
      return true; // Change this based on your geo-targeting logic
    } catch (e) {
      return false; // Default to not required on error
    }
  }

  // Load consent status from storage
  Future<void> _loadConsentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedVersion = prefs.getString(_consentVersionKey);
      final hasConsent = prefs.getBool(_consentStatusKey) ?? false;

      // Check if consent version is current
      if (savedVersion == currentConsentVersion && hasConsent) {
        _hasUserConsent = true;
      } else {
        _hasUserConsent = false;
        // Clear old consent if version mismatch
        if (savedVersion != currentConsentVersion) {
          await _clearConsentData();
        }
      }
    } catch (e) {
      _hasUserConsent = false;
    }
  }

  // Save consent status
  Future<void> _saveConsentStatus(bool consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_consentStatusKey, consent);
      await prefs.setString(_consentVersionKey, currentConsentVersion);
      await prefs.setString(
          _consentTimestampKey, DateTime.now().toIso8601String());

      _hasUserConsent = consent;
    } catch (e) {
      if (kDebugMode) {
        print('ConsentService: Error saving consent: $e');
      }
    }
  }

  // Clear consent data
  Future<void> _clearConsentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentStatusKey);
      await prefs.remove(_consentVersionKey);
      await prefs.remove(_consentTimestampKey);
    } catch (e) {
      if (kDebugMode) {
        print('ConsentService: Error clearing consent data: $e');
      }
    }
  }

  // Grant consent
  Future<void> grantConsent() async {
    await _saveConsentStatus(true);
    if (kDebugMode) {
      print('ConsentService: Consent granted');
    }
  }

  // Revoke consent
  Future<void> revokeConsent() async {
    await _saveConsentStatus(false);
    if (kDebugMode) {
      print('ConsentService: Consent revoked');
    }
  }

  // Show consent dialog
  Future<bool> showConsentDialog(BuildContext context) async {
    if (!_isConsentRequired || _hasUserConsent) {
      return true;
    }

    final completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ConsentDialog(
        onConsentGiven: () async {
          await grantConsent();
          completer.complete(true);
        },
        onConsentDenied: () async {
          await revokeConsent();
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  // Get consent status info
  Map<String, dynamic> getConsentInfo() {
    return {
      'is_required': _isConsentRequired,
      'has_consent': _hasUserConsent,
      'version': currentConsentVersion,
      'is_initialized': _isInitialized,
    };
  }
}

// Consent Dialog Widget
class ConsentDialog extends StatelessWidget {
  final VoidCallback onConsentGiven;
  final VoidCallback onConsentDenied;

  const ConsentDialog({
    super.key,
    required this.onConsentGiven,
    required this.onConsentDenied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            color: Colors.blue[600],
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'प्राइवेसी और विज्ञापन',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'हम आपको बेहतर अनुभव प्रदान करने के लिए विज्ञापन दिखाते हैं।',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• व्यक्तिगत विज्ञापन दिखाने के लिए डेटा का उपयोग\n'
              '• ऐप के प्रदर्शन में सुधार\n'
              '• विज्ञापन आय से ऐप निःशुल्क रखना',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(51)),
              ),
              child: const Text(
                'आप किसी भी समय सेटिंग में जाकर अपनी प्राइवेसी प्राथमिकताएं बदल सकते हैं।',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConsentDenied();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'अस्वीकार करें',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConsentGiven();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'स्वीकार करें',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Consent Management Widget for Settings
class ConsentManagementWidget extends StatefulWidget {
  const ConsentManagementWidget({super.key});

  @override
  State<ConsentManagementWidget> createState() =>
      _ConsentManagementWidgetState();
}

class _ConsentManagementWidgetState extends State<ConsentManagementWidget> {
  final ConsentService _consentService = ConsentService();

  @override
  Widget build(BuildContext context) {
    if (!_consentService.isConsentRequired) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'प्राइवेसी सेटिंग्स',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'व्यक्तिगत विज्ञापन: ${_consentService.hasUserConsent ? "चालू" : "बंद"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Switch(
                  value: _consentService.hasUserConsent,
                  onChanged: (value) async {
                    if (value) {
                      await _consentService.grantConsent();
                    } else {
                      await _consentService.revokeConsent();
                    }
                    setState(() {});
                  },
                  activeColor: Colors.blue[600],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _consentService.hasUserConsent
                  ? 'आपको प्रासंगिक विज्ञापन दिखाए जाएंगे।'
                  : 'आपको सामान्य विज्ञापन दिखाए जाएंगे।',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
