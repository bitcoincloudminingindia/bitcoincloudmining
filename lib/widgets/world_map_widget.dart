import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorldMapWidget extends StatefulWidget {
  final String serverLocation;
  final bool isConnected;
  final VoidCallback? onTap;

  const WorldMapWidget({
    super.key,
    required this.serverLocation,
    required this.isConnected,
    this.onTap,
  });

  @override
  State<WorldMapWidget> createState() => _WorldMapWidgetState();
}

class _WorldMapWidgetState extends State<WorldMapWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;

  // Server coordinates (simplified world map positions)
  final Map<String, Offset> _serverCoordinates = {
    'California': const Offset(0.15, 0.35),
    'China': const Offset(0.75, 0.40),
    'USA': const Offset(0.20, 0.35),
    'India': const Offset(0.65, 0.50),
    'Moscow': const Offset(0.55, 0.25),
    'Huawei': const Offset(0.70, 0.45),
    'Canada': const Offset(0.25, 0.20),
    'Dubai': const Offset(0.60, 0.45),
    'Singapore': const Offset(0.70, 0.60),
    'Germany': const Offset(0.50, 0.30),
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverPosition =
        _serverCoordinates[widget.serverLocation] ?? const Offset(0.5, 0.5);

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withAlpha((0.8 * 255).toInt()),
            Colors.blue.withAlpha((0.1 * 255).toInt()),
            Colors.purple.withAlpha((0.1 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isConnected
              ? Colors.green.withAlpha((0.5 * 255).toInt())
              : Colors.orange.withAlpha((0.5 * 255).toInt()),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // World map background (simplified)
          _buildWorldMapBackground(),

          // Server location indicator
          Positioned(
            left: serverPosition.dx * (MediaQuery.of(context).size.width - 64),
            top: serverPosition.dy * 200,
            child: _buildServerIndicator(),
          ),

          // Connection lines (optional)
          if (widget.isConnected) _buildConnectionLines(serverPosition),

          // Title
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              '🌍 Global Network',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Server info
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.6 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isConnected
                      ? Colors.green.withAlpha((0.3 * 255).toInt())
                      : Colors.orange.withAlpha((0.3 * 255).toInt()),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              widget.isConnected ? Colors.green : Colors.orange,
                          boxShadow: [
                            BoxShadow(
                              color: widget.isConnected
                                  ? Colors.green.withAlpha(
                                      (_pulseController.value * 255).toInt())
                                  : Colors.orange.withAlpha(
                                      (_pulseController.value * 255).toInt()),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connected to ${widget.serverLocation} Server',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color:
                            widget.isConnected ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldMapBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: WorldMapPainter(),
    );
  }

  Widget _buildServerIndicator() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isConnected ? Colors.green : Colors.orange,
            boxShadow: [
              BoxShadow(
                color: widget.isConnected
                    ? Colors.green
                        .withAlpha((_glowController.value * 0.8 * 255).toInt())
                    : Colors.orange
                        .withAlpha((_glowController.value * 0.8 * 255).toInt()),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionLines(Offset serverPosition) {
    return CustomPaint(
      size: Size.infinite,
      painter: ConnectionLinesPainter(
        serverPosition: serverPosition,
        glowController: _glowController,
      ),
    );
  }
}

class WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withAlpha((0.1 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw simplified continents
    final path = Path();

    // North America
    path.moveTo(size.width * 0.15, size.height * 0.25);
    path.lineTo(size.width * 0.35, size.height * 0.25);
    path.lineTo(size.width * 0.35, size.height * 0.45);
    path.lineTo(size.width * 0.15, size.height * 0.45);
    path.close();

    // Europe
    path.moveTo(size.width * 0.45, size.height * 0.25);
    path.lineTo(size.width * 0.55, size.height * 0.25);
    path.lineTo(size.width * 0.55, size.height * 0.35);
    path.lineTo(size.width * 0.45, size.height * 0.35);
    path.close();

    // Asia
    path.moveTo(size.width * 0.60, size.height * 0.30);
    path.lineTo(size.width * 0.85, size.height * 0.30);
    path.lineTo(size.width * 0.85, size.height * 0.60);
    path.lineTo(size.width * 0.60, size.height * 0.60);
    path.close();

    // Africa
    path.moveTo(size.width * 0.50, size.height * 0.40);
    path.lineTo(size.width * 0.60, size.height * 0.40);
    path.lineTo(size.width * 0.60, size.height * 0.70);
    path.lineTo(size.width * 0.50, size.height * 0.70);
    path.close();

    // South America
    path.moveTo(size.width * 0.25, size.height * 0.50);
    path.lineTo(size.width * 0.35, size.height * 0.50);
    path.lineTo(size.width * 0.35, size.height * 0.80);
    path.lineTo(size.width * 0.25, size.height * 0.80);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectionLinesPainter extends CustomPainter {
  final Offset serverPosition;
  final AnimationController glowController;

  ConnectionLinesPainter({
    required this.serverPosition,
    required this.glowController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
          .withAlpha(((0.3 + (glowController.value * 0.4)) * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw connection lines from center to server
    final center = Offset(size.width / 2, size.height / 2);
    final serverPoint = Offset(
      serverPosition.dx * (size.width - 64),
      serverPosition.dy * 200,
    );

    canvas.drawLine(center, serverPoint, paint);

    // Draw small connection dots along the line
    final dotPaint = Paint()
      ..color = Colors.green.withAlpha((0.6 * 255).toInt())
      ..style = PaintingStyle.fill;

    for (int i = 1; i < 5; i++) {
      final t = i / 5.0;
      final dotPosition = Offset.lerp(center, serverPoint, t)!;
      canvas.drawCircle(dotPosition, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
