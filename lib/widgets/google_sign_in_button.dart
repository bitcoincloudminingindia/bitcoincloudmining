import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/color_constants.dart';
import '../utils/backend_failover_debug.dart';

// Custom Google Logo Widget with fallback
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/images/google_logo.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildFallbackLogo(),
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4285F4), // Blue
            Color(0xFF34A853), // Green
            Color(0xFFFBBC05), // Yellow
            Color(0xFFEA4335), // Red
          ],
        ),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final String? buttonText;
  final double? width;
  final double? height;
  final bool? showDebugInfo; // Add debug option

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.buttonText,
    this.width,
    this.height,
    this.showDebugInfo = false, // Default to false for production
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;
  String _backendStatus = 'Backend: Checking...';

  @override
  void initState() {
    super.initState();
    _updateBackendStatus();
  }

  Future<void> _updateBackendStatus() async {
    final status = await BackendFailoverDebug.getBackendStatusString();
    if (mounted) {
      setState(() {
        _backendStatus = status;
      });
    }
  }

  Future<void> _testBackendFailover() async {
    print('🧪 Testing backend failover system...');
    await BackendFailoverDebug.printBackendStatus();
    await BackendFailoverDebug.testFailover();
    await _updateBackendStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Backend status display (only when debug is enabled)
        if (widget.showDebugInfo == true) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _backendStatus,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: _updateBackendStatus,
                  tooltip: 'Refresh backend status',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.bug_report, size: 16),
                  onPressed: _testBackendFailover,
                  tooltip: 'Test failover system',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
        
        // Main Google Sign-In button
        SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 50,
          child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Real Google Logo with fallback
                  const GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  // Button Text with Google Font
                  Text(
                    widget.buttonText ?? 'Continue with Google',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3C4043),
                    ),
                  ),
                ],
              ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.signInWithGoogle(context);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Sign-In successful!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate based on user role or verification status
          final userData = result['data']['user'];
          if (userData != null) {
            // Navigate to appropriate screen
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        if (mounted) {
          // Enhanced error handling with specific messages
          String errorMessage = result['message'] ?? 'Google Sign-In failed';
          String debugInfo = '';
          
          // Add debug information for development
          if (result['debug_info'] != null) {
            final debug = result['debug_info'];
            if (debug['backend_url'] != null) {
              debugInfo = '\nTrying to connect to: ${debug['backend_url']}';
            }
            if (debug['error'] != null) {
              debugInfo += '\nError details: ${debug['error']}';
            }
          }
          
          // Show specific error messages based on error type
          if (result['error'] == 'BACKEND_CONNECTION_FAILED') {
            errorMessage = 'Unable to connect to our servers. Please check your internet connection and try again.';
          } else if (result['error'] == 'SERVER_UNAVAILABLE') {
            errorMessage = 'Our servers are temporarily busy. Please try again in a few minutes.';
          } else if (result['error'] == 'INVALID_JSON_RESPONSE') {
            errorMessage = 'Service temporarily unavailable. Please try again shortly.';
          } else if (result['error'] == 'SIGN_IN_CANCELLED') {
            errorMessage = 'Sign-in was cancelled. Please try again if you want to continue.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage),
                  if (debugInfo.isNotEmpty && result['error'] != 'SIGN_IN_CANCELLED')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        debugInfo,
                        style: const TextStyle(fontSize: 12, opacity: 0.8),
                      ),
                    ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: result['error'] != 'SIGN_IN_CANCELLED' 
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      // Retry the sign-in
                      _handleGoogleSignIn();
                    },
                  )
                : null,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        print('🔴 Unexpected error in Google Sign-In button: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _handleGoogleSignIn();
              },
            ),
          ),
        );
      }
    }
  }
}

// Alternative styled button
class GoogleSignInButtonOutlined extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final String? buttonText;
  final double? width;
  final double? height;

  const GoogleSignInButtonOutlined({
    super.key,
    this.onSuccess,
    this.onError,
    this.buttonText,
    this.width,
    this.height,
  });

  @override
  State<GoogleSignInButtonOutlined> createState() =>
      _GoogleSignInButtonOutlinedState();
}

class _GoogleSignInButtonOutlinedState
    extends State<GoogleSignInButtonOutlined> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primaryColor,
          side: BorderSide(color: ColorConstants.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      ColorConstants.primaryColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Real Google Logo with fallback
                  const GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  // Button Text with Google Font
                  Text(
                    widget.buttonText ?? 'Sign in with Google',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.signInWithGoogle(context);

      if (result['success']) {
        widget.onSuccess?.call();
      } else {
        widget.onError?.call();
      }
    } catch (e) {
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
