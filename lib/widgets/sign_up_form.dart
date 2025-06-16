import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/validators.dart';
import 'custom_text_field.dart';
import 'loading_button.dart';

class SignUpForm extends StatefulWidget {
  final Function(String, String, String, String, String, String?) onSignUp;
  final bool isLoading;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController referralCodeController;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final String? usernameError;
  final String? emailError;
  final String? referralCodeError;
  final String? errorMessage;
  final bool isCheckingUsername;
  final bool isCheckingReferralCode;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;

  const SignUpForm({
    super.key,
    required this.onSignUp,
    required this.isLoading,
    required this.formKey,
    required this.fullNameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.referralCodeController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    this.usernameError,
    this.emailError,
    this.referralCodeError,
    this.errorMessage,
    required this.isCheckingUsername,
    required this.isCheckingReferralCode,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
  });

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      widget.onSignUp(
        _fullNameController.text,
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
        _referralCodeController.text.trim().isNotEmpty
            ? _referralCodeController.text.trim()
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          CustomTextField(
            controller: _fullNameController,
            label: AppStrings.name,
            prefix: const Icon(Icons.person, color: Colors.white70),
            validator: Validators.validateRequired,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _usernameController,
            label: AppStrings.username,
            prefix: const Icon(Icons.person, color: Colors.white70),
            suffix: widget.isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  )
                : widget.usernameError == null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error, color: Colors.redAccent),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.required;
              }
              if (value.length < 3) {
                return AppStrings.usernameTooShort;
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Username can only contain letters, numbers and underscores';
              }
              if (widget.usernameError != null) {
                return widget.usernameError;
              }
              return null;
            },
          ),
          if (widget.usernameError != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.usernameError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: AppStrings.email,
            prefix: const Icon(Icons.email, color: Colors.white70),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: AppStrings.password,
            prefix: const Icon(Icons.lock, color: Colors.white70),
            obscureText: !_obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: AppStrings.confirmPassword,
            prefix: const Icon(Icons.lock, color: Colors.white70),
            obscureText: !_obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.required;
              }
              if (value != _passwordController.text) {
                return AppStrings.passwordsDontMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _referralCodeController,
            label: 'Referral Code (Optional)',
            prefix: const Icon(Icons.card_giftcard, color: Colors.white70),
            suffix: widget.isCheckingReferralCode
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  )
                : _referralCodeController.text.isNotEmpty
                    ? widget.referralCodeError == null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.error, color: Colors.redAccent)
                    : null,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  widget.referralCodeError != null) {
                return widget.referralCodeError;
              }
              return null;
            },
          ),
          if (widget.referralCodeError != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.referralCodeError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            text: AppStrings.signUp,
            isLoading: _isLoading,
            onPressed: _signUp,
            color: Colors.amber[400],
            textColor: Colors.black87,
          ),
        ],
      ),
    );
  }
}
