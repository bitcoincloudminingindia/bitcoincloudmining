import 'dart:async';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:bitcoin_cloud_mining/providers/network_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NetworkStatusWidget extends StatefulWidget {
  final bool isMining;
  final double hashRate;
  final VoidCallback? onServerChange;

  const NetworkStatusWidget({
    super.key,
    required this.isMining,
    required this.hashRate,
    this.onServerChange,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _typingController;

  String _currentServer = '';
  String _connectionStatus = 'Initializing...';
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isReconnecting = false;

  final List<String> _servers = [
    'California',
    'China',
    'USA',
    'India',
    'Moscow',
    'Huawei',
    'Canada',
    'Dubai',
    'Singapore',
    'Germany',
  ];

  final List<String> _connectionSteps = [
    '🔍 Searching for global mining node...',
    '🌐 Connecting to server...',
    '🔐 Secure tunnel established.',
    '✅ Connected successfully.',
  ];

  Timer? _statusTimer;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectRandomServer();
    _startConnectionSimulation();
    _setupConnectivityListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NetworkProvider>(context, listen: false).currentServer =
            _currentServer;
      }
    });
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

    _typingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  void _selectRandomServer() {
    final random = Random();
    _currentServer = _servers[random.nextInt(_servers.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NetworkProvider>(context, listen: false).currentServer =
            _currentServer;
      }
    });
  }

  void _startConnectionSimulation() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = _connectionSteps[0];
    });

    for (int i = 0; i < _connectionSteps.length; i++) {
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
      if (mounted) {
        setState(() {
          _connectionStatus = _connectionSteps[i];
        });
      }
    }

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _connectionStatus = '✅ Connected to $_currentServer Server';
      });
    }

    _startStatusUpdates();
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isConnected) {
        setState(() {
          // Update status with random mining info
          final random = Random();
          final statuses = [
            '⛏️ Mining in progress...',
            '🔒 Secure connection maintained',
            '🌍 Global node synchronized',
            '⚡ Hashrate optimized',
            '🔐 Blockchain verified',
          ];
          _connectionStatus = statuses[random.nextInt(statuses.length)];
        });
      }
    });
  }

  void _setupConnectivityListener() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result == ConnectivityResult.none) {
        _handleDisconnection();
      } else if (_isReconnecting) {
        _handleReconnection();
      }
    });
  }

  void _handleDisconnection() {
    setState(() {
      _isConnected = false;
      _isReconnecting = true;
      _connectionStatus = '⚠️ Connection lost. Reconnecting...';
    });

    // Auto reassign to new server after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _selectRandomServer();
        _startConnectionSimulation();
        widget.onServerChange?.call();
      }
    });
  }

  void _handleReconnection() {
    setState(() {
      _isReconnecting = false;
      _isConnected = true;
      _connectionStatus = '✅ Reconnected to $_currentServer Server';
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _typingController.dispose();
    _statusTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          color: _isConnected
              ? Colors.green.withAlpha((255 * 0.5).toInt())
              : Colors.orange.withAlpha((255 * 0.5).toInt()),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isConnected
                ? Colors.green.withAlpha((255 * 0.3).toInt())
                : Colors.orange.withAlpha((255 * 0.3).toInt()),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with server info
          Row(
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? Colors.green : Colors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: _isConnected
                              ? Colors.green.withAlpha(
                                  (_glowController.value * 255).toInt())
                              : Colors.orange.withAlpha(
                                  (_glowController.value * 255).toInt()),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🌍 Global Mining Network',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Server connection status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withAlpha((0.3 * 255).toInt()),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dns,
                      color: _isConnected ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Server: $_currentServer',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected ? Colors.green : Colors.orange,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isConnecting || _isReconnecting
                          ? AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  _connectionStatus,
                                  textStyle: GoogleFonts.orbitron(
                                    fontSize: 12,
                                    color: _isConnected
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  speed: const Duration(milliseconds: 100),
                                ),
                              ],
                              totalRepeatCount: 1,
                            )
                          : Text(
                              _connectionStatus,
                              style: GoogleFonts.orbitron(
                                fontSize: 12,
                                color:
                                    _isConnected ? Colors.green : Colors.orange,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Network info
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  '🔌 Network',
                  _isConnected ? 'Online' : 'Offline',
                  _isConnected ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  '🔐 Tunnel',
                  'Encrypted',
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha((255 * 0.3).toInt()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple network status indicator widget
class NetworkIndicator extends StatelessWidget {
  final bool isConnected;
  final double size;

  const NetworkIndicator({
    super.key,
    required this.isConnected,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: size,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
