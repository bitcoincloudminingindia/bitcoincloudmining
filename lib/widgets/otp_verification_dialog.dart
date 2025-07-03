import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final bool shouldSendOtp;

  const OtpVerificationDialog({
    super.key,
    required this.email,
    this.shouldSendOtp = true,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '🔄 Initializing OTP verification dialog for email: ${widget.email}');
    if (widget.shouldSendOtp) {
      _sendOtp();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    debugPrint('📧 Sending OTP to email: ${widget.email}');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.post(ApiConfig.sendVerificationOtp, {
        'email': widget.email,
      });

      debugPrint('📧 OTP send result: $result');

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      setState(() {
        _errorMessage = 'An error occurred while sending OTP';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter OTP';
      });
      return;
    }

    debugPrint('🔐 Verifying OTP for email: ${widget.email}');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.post(ApiConfig.verifyOtp, {
        'email': widget.email,
        'otp': _otpController.text,
      });

      debugPrint('🔐 OTP verification result: $result');

      if (result['success'] == true) {
        if (mounted) {
          debugPrint('✅ OTP verification successful');
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Close OTP dialog
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to verify OTP';
        });
      }
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      setState(() {
        _errorMessage = 'An error occurred while verifying OTP';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.blue[900],
      title: const Text(
        'Verify Email',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please enter the OTP sent to ${widget.email}',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              labelText: 'OTP',
              labelStyle: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              floatingLabelStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[900]!.withAlpha(26),
              counterStyle: TextStyle(color: Colors.grey[300]),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[300],
                ),
                child: const Text('Resend OTP'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Verify'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        title: const Text('Disclaimer'),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 60),
              const SizedBox(height: 24),
              const Text(
                'Disclaimer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This app simulates cloud mining. Rewards are virtual and based on ad interactions or in-app activities. It does not perform real Bitcoin mining.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OK',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
