import 'dart:async';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart' as form_validators;
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_dialog.dart';
import 'otp_verification_dialog.dart';

class SignUpDialog extends StatefulWidget {
  final String? initialReferralCode;

  const SignUpDialog({
    super.key,
    this.initialReferralCode,
  });

  @override
  State<SignUpDialog> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends State<SignUpDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isCheckingUsername = false;
  bool _isCheckingReferralCode = false;
  String? _usernameError;
  String? _referralCodeError;
  Timer? _usernameDebounce;
  Timer? _referralCodeDebounce;
  final _otpController = TextEditingController();
  bool _isUsernameAvailable = true;
  bool _isReferralCodeValid = true;
  String? _errorMessage;
  String? _referrerName;

  @override
  void initState() {
    super.initState();
    _usernameController
        .addListener(() => _onUsernameChanged(_usernameController.text));
    _referralCodeController.addListener(
        () => _onReferralCodeChanged(_referralCodeController.text));

    // Set initial referral code if provided
    if (widget.initialReferralCode != null &&
        widget.initialReferralCode!.isNotEmpty) {
      _referralCodeController.text = widget.initialReferralCode!;
      _onReferralCodeChanged(widget.initialReferralCode!);
    }

    _checkInitialReferralCode();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _otpController.dispose();
    _usernameDebounce?.cancel();
    _referralCodeDebounce?.cancel();
    _usernameController
        .removeListener(() => _onUsernameChanged(_usernameController.text));
    _referralCodeController.removeListener(
        () => _onReferralCodeChanged(_referralCodeController.text));
    super.dispose();
  }

  Future<void> _onUsernameChanged(String value) async {
    if (_usernameDebounce?.isActive ?? false) {
      _usernameDebounce!.cancel();
    }

    // Immediate validation for empty value
    if (value.isEmpty) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Start checking animation immediately
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    // Local validation before API call
    if (!_validateUsernameLocally(value)) {
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    // Debounce API call
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Check username availability
        final usernameCheck = await ApiService().checkUsername(
          _usernameController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            if (usernameCheck['success'] == true) {
              _isUsernameAvailable = usernameCheck['isAvailable'] ?? false;
              _usernameError =
                  _isUsernameAvailable ? null : 'Username is already taken';
            } else {
              _isUsernameAvailable = false;
              _usernameError =
                  usernameCheck['message'] ?? 'Failed to check username';
            }
          });
        }
      } catch (e) {
        print('Username check error: $e');
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameAvailable = false;
            _usernameError = 'Connection error, please try again';
          });
        }
      }
    });
  }

  bool _validateUsernameLocally(String value) {
    if (value.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username must be at least 3 characters';
        _isCheckingUsername = false;
      });
      return false;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Only letters, numbers and underscores allowed';
        _isCheckingUsername = false;
      });
      return false;
    }

    return true;
  }

  void _onReferralCodeChanged(String value) {
    if (_referralCodeDebounce?.isActive ?? false) {
      _referralCodeDebounce?.cancel();
    }

    setState(() {
      _isCheckingReferralCode = true;
      _isReferralCodeValid = false;
      _referralCodeError = null;
      _referrerName = null;
    });

    _referralCodeDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final result = await ApiService.post(
            ApiConfig.validateReferralCode, {'code': value.trim()});

        if (mounted) {
          setState(() {
            _isCheckingReferralCode = false;
            if (result['success'] == true) {
              _isReferralCodeValid = true;
              _referralCodeError = null;
              _referrerName = result['data']?['referrerName'];
            } else {
              _isReferralCodeValid = false;
              _referralCodeError = result['message'] ??
                  'Invalid referral code. Please check and try again.';
              _referrerName = null;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingReferralCode = false;
            _isReferralCodeValid = false;
            _referralCodeError =
                'Network error. Please check your connection and try again.';
            _referrerName = null;
          });
        }
      }
    });
  }

  void _checkInitialReferralCode() {
    if (widget.initialReferralCode != null &&
        widget.initialReferralCode!.isNotEmpty) {
      setState(() {
        _referralCodeController.text = widget.initialReferralCode!;
        _onReferralCodeChanged(widget.initialReferralCode!);
      });
    }
  }

  Future<void> _handleSignup({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String? referredByCode,
  }) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📤 Sending signup request');
      print('📝 User data: $fullName, $username, $email');

      final response = await ApiService().signup(
        fullName: _fullNameController.text.trim(),
        userName: _usernameController.text.trim(),
        userEmail: _emailController.text.trim(),
        password: _passwordController.text,
        referredByCode: referredByCode,
      );

      print('📥 Signup response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        // Show OTP verification dialog without closing signup dialog
        final verified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => OtpVerificationDialog(
            email: email.trim(),
          ),
        );

        if (verified == true) {
          // Close both dialogs only after successful verification
          Navigator.of(context).pop(); // Close signup dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const LoginDialog(),
          );
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Signup failed';
        });
      }
    } catch (e) {
      print('❌ Signup error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(26, 35, 126, 0.95),
              Color.fromRGBO(13, 71, 161, 0.95),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_bitcoin,
                    size: 64,
                    color: Colors.amber[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.appTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[400],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.createAccount,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.1),
                      width: 1,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          validator:
                              form_validators.Validators.validateRequired,
                          prefixIcon: Icons.person,
                          prefixIconColor: Colors.grey[300],
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          labelStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          borderColor: Colors.grey[300]!,
                          focusedBorderColor: Colors.grey[400]!,
                          backgroundColor: Colors.grey[900]!.withAlpha(26),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _usernameController,
                          label: 'Username',
                          validator: (value) {
                            if (_usernameError != null) {
                              return _usernameError;
                            }
                            if (value == null || value.isEmpty) {
                              return 'Username is required';
                            }
                            if (!_isUsernameAvailable) {
                              return 'Username is not available';
                            }
                            return form_validators.Validators.validateRequired(
                                value);
                          },
                          prefixIcon: Icons.account_circle,
                          prefixIconColor: Colors.grey[300],
                          suffix: _isCheckingUsername
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white70),
                                  ),
                                )
                              : _usernameController.text.isNotEmpty
                                  ? Icon(
                                      // Reversed the condition here
                                      _isUsernameAvailable
                                          ? Icons
                                              .cancel // Show cancel icon when username is available
                                          : Icons
                                              .check_circle, // Show check icon when username is not available
                                      color: _isUsernameAvailable
                                          ? Colors.red[
                                              400] // Red for available username
                                          : Colors.green[
                                              400], // Green for unavailable username
                                      size: 20,
                                    )
                                  : null,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          labelStyle: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 13,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          borderColor: Colors.grey[300]!,
                          focusedBorderColor: Colors.grey[400]!,
                          backgroundColor: Colors.grey[900]!.withAlpha(26),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: form_validators.Validators.validateEmail,
                          prefixIcon: Icons.email,
                          prefixIconColor: Colors.grey[300],
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          labelStyle: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 13,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          borderColor: Colors.grey[300]!,
                          focusedBorderColor: Colors.grey[400]!,
                          backgroundColor: Colors.grey[900]!.withAlpha(26),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: !_isPasswordVisible,
                          validator:
                              form_validators.Validators.validatePassword,
                          prefixIcon: Icons.lock,
                          prefixIconColor: Colors.grey[300],
                          suffix: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[300],
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          labelStyle: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 13,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          borderColor: Colors.grey[300]!,
                          focusedBorderColor: Colors.grey[400]!,
                          backgroundColor: Colors.grey[900]!.withAlpha(26),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) => form_validators.Validators
                              .validateConfirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          prefixIcon: Icons.lock_outline,
                          prefixIconColor: Colors.grey[300],
                          suffix: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[300],
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          labelStyle: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 13,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          borderColor: Colors.grey[300]!,
                          focusedBorderColor: Colors.grey[400]!,
                          backgroundColor: Colors.grey[900]!.withAlpha(26),
                        ),
                        const SizedBox(height: 12),
                        _buildReferralCodeField(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        CustomButton(
                          onPressed: () => _handleSignup(
                            email: _emailController.text,
                            password: _passwordController.text,
                            fullName: _fullNameController.text,
                            username: _usernameController.text,
                            referredByCode: _referralCodeController.text.trim(),
                          ),
                          text: 'Sign Up',
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.alreadyHaveAccount,
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const LoginDialog(),
                        );
                      },
                      child: const Text(AppStrings.login),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _referralCodeController,
          label: 'Referral Code (Optional)',
          hint: 'Enter referral code if you were referred',
          prefixIcon: Icons.card_giftcard,
          prefixIconColor: Colors.grey[300],
          errorText: _referralCodeError,
          suffix: _isCheckingReferralCode
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
                  ),
                )
              : _isReferralCodeValid
                  ? Icon(Icons.check_circle, color: Colors.green[400], size: 20)
                  : null,
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _isReferralCodeValid = false;
                _referralCodeError = null;
              });
            }
          },
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[300],
            fontSize: 13,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          borderColor: Colors.grey[300]!,
          focusedBorderColor: Colors.grey[400]!,
          backgroundColor: Colors.grey[900]!.withAlpha(26),
        ),
        if (_referrerName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.green[400],
                ),
                const SizedBox(width: 4),
                Text(
                  'Referred by: $_referrerName',
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
