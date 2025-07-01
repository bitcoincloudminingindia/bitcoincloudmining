import 'package:bitcoin_cloud_mining/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class FloatingBubbleWidget extends StatefulWidget {
  const FloatingBubbleWidget({super.key});

  @override
  State<FloatingBubbleWidget> createState() => _FloatingBubbleWidgetState();
}

class _FloatingBubbleWidgetState extends State<FloatingBubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for mining effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Bounce animation for tap effect
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Bounce effect
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    if (!_isExpanded) {
      // First tap: expand the bubble
      setState(() {
        _isExpanded = true;
      });
    } else {
      // Second tap: close overlay and bring app to foreground
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
      builder: (context, child) {
        return GestureDetector(
          onTap: _onTap,
          child: Transform.scale(
            scale: _pulseAnimation.value * _bounceAnimation.value,
            child: Container(
              width: _isExpanded ? 120 : 80,
              height: _isExpanded ? 120 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorConstants.primaryColor,
                    ColorConstants.secondaryColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primaryColor
                        .withAlpha((255 * 0.3).toInt()),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isExpanded
                  ? _buildExpandedContent()
                  : _buildCollapsedContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedContent() {
    return const Center(
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('assets/images/app_logo.png'),
        radius: 32,
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          backgroundColor: Colors.transparent,
          backgroundImage: AssetImage('assets/images/app_logo.png'),
          radius: 24,
        ),
        const SizedBox(height: 4),
        const Text(
          'Mining',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
