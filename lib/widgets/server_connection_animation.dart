import 'dart:async';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServerConnectionAnimation extends StatefulWidget {
  final String serverName;
  final bool isConnecting;
  final bool isConnected;
  final VoidCallback? onConnectionComplete;

  const ServerConnectionAnimation({
    super.key,
    required this.serverName,
    required this.isConnecting,
    required this.isConnected,
    this.onConnectionComplete,
  });

  @override
  State<ServerConnectionAnimation> createState() =>
      _ServerConnectionAnimationState();
}

class _ServerConnectionAnimationState extends State<ServerConnectionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _connectController;
  late AnimationController _pulseController;

  int _currentStep = 0;
  final List<String> _connectionSteps = [
    '🔍 Scanning global network...',
    '🌐 Locating optimal server...',
    '🔐 Establishing secure tunnel...',
    '⚡ Synchronizing blockchain...',
    '✅ Connection established!',
  ];

  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.isConnecting) {
      _startConnectionAnimation();
    }
  }

  void _initializeAnimations() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _connectController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startConnectionAnimation() {
    _currentStep = 0;
    _stepTimer?.cancel();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted && _currentStep < _connectionSteps.length - 1) {
        setState(() {
          _currentStep++;
        });

        if (_currentStep == _connectionSteps.length - 1) {
          timer.cancel();
          _connectController.forward();
          Future.delayed(const Duration(seconds: 1), () {
            widget.onConnectionComplete?.call();
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(ServerConnectionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnecting && !oldWidget.isConnecting) {
      _startConnectionAnimation();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _connectController.dispose();
    _pulseController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isConnecting && !widget.isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withAlpha((0.9 * 255).toInt()),
            Colors.blue.withAlpha((0.2 * 255).toInt()),
            Colors.purple.withAlpha((0.2 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isConnected
              ? Colors.green.withAlpha((0.5 * 255).toInt())
              : Colors.blue.withAlpha((0.5 * 255).toInt()),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isConnected
                ? Colors.green.withAlpha((0.3 * 255).toInt())
                : Colors.blue.withAlpha((0.3 * 255).toInt()),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isConnected ? Colors.green : Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: widget.isConnected
                              ? Colors.green.withAlpha(
                                  (_pulseController.value * 255).toInt())
                              : Colors.blue.withAlpha(
                                  (_pulseController.value * 255).toInt()),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                '🚀 Server Connection',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Connection animation
          if (widget.isConnecting) ...[
            _buildScanningAnimation(),
            const SizedBox(height: 16),
            _buildConnectionSteps(),
          ] else if (widget.isConnected) ...[
            _buildConnectedState(),
          ],
        ],
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scanning circle
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _scanController.value * 2 * pi,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withAlpha((0.6 * 255).toInt()),
                      width: 2,
                    ),
                  ),
                  child: CustomPaint(
                    painter: ScanningPainter(_scanController.value),
                  ),
                ),
              );
            },
          ),

          // Center icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withAlpha((0.3 * 255).toInt()),
            ),
            child: const Icon(
              Icons.satellite_alt,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSteps() {
    return Column(
      children: [
        for (int i = 0; i < _connectionSteps.length; i++) ...[
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= _currentStep
                      ? (i == _currentStep ? Colors.blue : Colors.green)
                      : Colors.grey.withAlpha((0.3 * 255).toInt()),
                ),
                child: i <= _currentStep
                    ? Icon(
                        i == _currentStep ? Icons.sync : Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: i == _currentStep
                    ? AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            _connectionSteps[i],
                            textStyle: GoogleFonts.orbitron(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            speed: const Duration(milliseconds: 80),
                          ),
                        ],
                        totalRepeatCount: 1,
                      )
                    : Text(
                        _connectionSteps[i],
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          color: i < _currentStep ? Colors.green : Colors.grey,
                        ),
                      ),
              ),
            ],
          ),
          if (i < _connectionSteps.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildConnectedState() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _connectController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_connectController.value * 0.2),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withAlpha((0.2 * 255).toInt()),
                  border: Border.all(
                    color: Colors.green,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Connected to ${widget.serverName}',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ready for mining operations',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: Colors.green.withAlpha((0.8 * 255).toInt()),
          ),
        ),
      ],
    );
  }
}

class ScanningPainter extends CustomPainter {
  final double progress;

  ScanningPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withAlpha((0.6 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw scanning arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      progress * 2 * pi,
      false,
      paint,
    );

    // Draw scanning line
    final linePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final angle = -pi / 2 + (progress * 2 * pi);
    final endPoint = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    canvas.drawLine(center, endPoint, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
