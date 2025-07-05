import 'dart:async';

import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key});

  @override
  _ContractScreenState createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final AdService _adService = AdService();
  double totalEarnedBTC = 0.0;
  TextEditingController btcAddressController = TextEditingController();
  TextEditingController withdrawAmountController = TextEditingController();
  List<String> withdrawalHistory = [];
  Timer? _uiUpdateTimer;

  List<Map<String, dynamic>> contracts = [
    {
      'title': '5 Days Contract (Trial)',
      'hashRate': 50.0,
      'duration': 5,
      'adsRequired': 50,
      'earnings': 0.000005,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.0000000000116,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '7 Days Contract (Basic)',
      'hashRate': 100.0,
      'duration': 7,
      'adsRequired': 100,
      'earnings': 0.0000009,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.0000000000078,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '10 Days Contract (Express)',
      'hashRate': 300.0,
      'duration': 10,
      'adsRequired': 120,
      'earnings': 0.0000015,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.0000000000347,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '15 Days Contract (Premium)',
      'hashRate': 500.0,
      'duration': 15,
      'adsRequired': 150,
      'earnings': 0.000002,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.000000000000000417,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '30 Days Contract (Standard)',
      'hashRate': 250.0,
      'duration': 30,
      'adsRequired': 200,
      'earnings': 0.0000025,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.000000000000000208,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '45 Days Contract (Intermediate)',
      'hashRate': 400.0,
      'duration': 45,
      'adsRequired': 220,
      'earnings': 0.000005,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.000000000000000926,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '60 Days Contract (Pro)',
      'hashRate': 750.0,
      'duration': 60,
      'adsRequired': 250,
      'earnings': 0.0000065,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.000000000000000926,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '90 Days Contract (Advanced)',
      'hashRate': 1000.0,
      'duration': 90,
      'adsRequired': 300,
      'earnings': 0.000009,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.000000000000001388,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '120 Days Contract (Elite)',
      'hashRate': 1500.0,
      'duration': 120,
      'adsRequired': 500,
      'earnings': 0.00001,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.00000000000002893,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '180 Days Contract (Ultimate)',
      'hashRate': 2000.0,
      'duration': 180,
      'adsRequired': 600,
      'earnings': 0.00002,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.00000000000463,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '300 Days Contract (Exclusive)',
      'hashRate': 2500.0,
      'duration': 300,
      'adsRequired': 1000,
      'earnings': 0.00005,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.0000000000005787,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
    {
      'title': '365 Days Contract (Legendary)',
      'hashRate': 5000.0,
      'duration': 365,
      'adsRequired': 1500,
      'earnings': 0.0000899,
      'currentEarnings': 0.0,
      'earningsPerSecond': 0.00000000000008197,
      'isMining': false,
      'adsWatched': 0,
      'timer': null,
    },
  ];

  DateTime? _lastAdWatchTime;
  Timer? _adCooldownTimer;
  int _remainingCooldownSeconds = 0;
  bool _isAdInitialized = false;

  // Banner ad futures for 1 position only
  Future<Widget?>? _bannerAdFuture1;

  // Dedicated banner ad load functions
  void _loadBannerAd1() {
    setState(() {
      _bannerAdFuture1 = _adService.getBannerAdWidget();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _initializeAdService();
    _loadWatchAdsCounts();
    _loadEarnings();
    _restoreContractStates();
    _startUiUpdateTimer();
    _loadNativeAd();
    // Banner ad future
    _loadBannerAd1();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiUpdateTimer?.cancel();
    _adCooldownTimer?.cancel();
    for (var contract in contracts) {
      contract['timer']?.cancel();
    }
    _tabController.dispose();
    _saveEarnings();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is going to background
      for (int i = 0; i < contracts.length; i++) {
        if (contracts[i]['isMining']) {
          _saveContractState(i);
          // Don't pause the timer
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // App has come to foreground
      _restoreContractStates();
      // Banner ad reload karo
      if (mounted) {
        setState(_loadBannerAd1);
      }
    }
  }

  Future<void> _initializeAdService() async {
    try {
      await _adService.initialize();
      setState(() {
        _isAdInitialized = true;
      });
    } catch (e) {
      // Retry after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _initializeAdService();
        }
      });
    }
  }

  Future<void> _loadWatchAdsCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < contracts.length; i++) {
        contracts[i]['adsWatched'] =
            prefs.getInt('adsWatched_contract_$i') ?? 0;
      }
    });
  }

  Future<void> _saveWatchAdsCount(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'adsWatched_contract_$index', contracts[index]['adsWatched']);
  }

  Future<void> _loadEarnings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < contracts.length; i++) {
        contracts[i]['currentEarnings'] =
            prefs.getDouble('currentEarnings_$i') ?? 0.0;
      }
      totalEarnedBTC = prefs.getDouble('totalEarnedBTC') ?? 0.0;
    });
  }

  Future<void> _saveEarnings() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < contracts.length; i++) {
      await prefs.setDouble(
          'currentEarnings_$i', contracts[i]['currentEarnings']);
    }
    await prefs.setDouble('totalEarnedBTC', totalEarnedBTC);
  }

  Future<void> _restoreContractStates() async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < contracts.length; i++) {
      final contract = contracts[i];

      // First check if contract is already completed
      final isCompleted = prefs.getBool('contract_completed_$i') ?? false;
      if (isCompleted) {
        setState(() {
          contract['isCompleted'] = true;
          contract['isMining'] = false;
          contract['currentEarnings'] = contract['earnings'];
        });
        continue;
      }

      final wasMining = prefs.getBool('contract_is_mining_$i') ?? false;
      final miningStartTimeStr =
          prefs.getString('contract_mining_start_time_$i');

      if (wasMining && miningStartTimeStr != null) {
        final miningStartTime = DateTime.parse(miningStartTimeStr);
        final now = DateTime.now();
        final elapsedSeconds = now.difference(miningStartTime).inSeconds;
        final potentialEarnings =
            elapsedSeconds * contract['earningsPerSecond'];

        if (potentialEarnings + contract['currentEarnings'] >=
            contract['earnings']) {
          await _completeContract(i);
        } else {
          setState(() {
            contract['isMining'] = true;
            contract['currentEarnings'] =
                contract['currentEarnings'] + potentialEarnings;
          });
          _startContractMining(i); // Restart mining
        }
      }
    }
  }

  Future<void> _saveContractState(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contract = contracts[index];

      if (contract['isMining']) {
        await prefs.setString(
            'contract_mining_start_time_$index',
            DateTime.now()
                .subtract(Duration(
                    seconds: (contract['currentEarnings'] /
                            contract['earningsPerSecond'])
                        .floor()))
                .toIso8601String());
        await prefs.setDouble(
            'contract_current_earnings_$index', contract['currentEarnings']);
        await prefs.setBool('contract_is_mining_$index', true);
      } else {
        await prefs.remove('contract_mining_start_time_$index');
        await prefs.remove('contract_current_earnings_$index');
        await prefs.remove('contract_is_mining_$index');
      }
    } catch (e) {}
  }

  Future<void> _completeContract(int index) async {
    try {
      final contract = contracts[index];
      final earnings = contract['currentEarnings'] as double;
      if (earnings > 0) {
        // Add earnings to wallet
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.addEarning(
          earnings,
          type: 'mining',
          description: 'Contract Complete: ${contract['title']}',
        );

        // Update contract state
        setState(() {
          contract['isMining'] = false;
          contract['isCompleted'] = true;
          contract['currentEarnings'] = 0.0;
          contract['adsWatched'] = 0; // Reset ads watched count
          contract['timer']?.cancel();
          contract['timer'] = null;
        });

        // Save contract state and ads watched count
        await _saveContractState(index);
        await _saveWatchAdsCount(index);

        // Show completion message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contract completed! Earned $earnings BTC'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {}
  }

  void _startContractMining(int index) {
    final contract = contracts[index];
    if (contract['adsWatched'] >= contract['adsRequired'] &&
        !contract['isMining'] &&
        !(contract['isCompleted'] ?? false)) {
      // Cancel existing timer if any
      contract['timer']?.cancel();

      setState(() {
        contract['isMining'] = true;
        contract['timer'] = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final double potential =
              contract['currentEarnings'] + contract['earningsPerSecond'];
          if (potential >= contract['earnings']) {
            _completeContract(index);
            timer.cancel();
          } else {
            setState(() {
              contract['currentEarnings'] = potential;
              totalEarnedBTC += contract['earningsPerSecond'];
            });
            // Save state periodically
            if (contract['currentEarnings'] % 0.0000001 <
                contract['earningsPerSecond']) {
              _saveContractState(index);
            }
          }
        });
      });
      _saveContractState(index);
    }
  }

  void stopMining(int index) {
    final contract = contracts[index];
    if (contract['isMining'] && contract['timer'] != null) {
      contract['timer'].cancel();
      setState(() {
        contract['isMining'] = false;
        contract['timer'] = null;
      });
      _saveContractState(index);
    }
    Workmanager().cancelByUniqueName('mining_periodic_task_$index');
  }

  bool _canWatchAd() {
    if (_lastAdWatchTime == null) return true;
    final difference = DateTime.now().difference(_lastAdWatchTime!);
    return difference.inSeconds >= 60;
  }

  void _startAdCooldown() {
    _lastAdWatchTime = DateTime.now();
    _remainingCooldownSeconds = 60;

    _adCooldownTimer?.cancel();
    _adCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingCooldownSeconds > 0) {
          _remainingCooldownSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> watchAd(int index) async {
    if (!_isAdInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad service is not ready. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_canWatchAd()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please wait $_remainingCooldownSeconds seconds before watching another ad'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await _adService.showRewardedAd(
        onRewarded: (double amount) async {
          final contract = contracts[index];
          setState(() {
            if (contract['adsWatched'] < contract['adsRequired']) {
              contract['adsWatched']++;
            }
          });
          _saveWatchAdsCount(index);
          _startAdCooldown();
        },
        onAdDismissed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Watch the full ad to claim earnings.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to show ad. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startUiUpdateTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadNativeAd() async {
    try {
      await _adService.loadNativeAd();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 93, 144, 219),
        leading: IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications not available!')),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.currency_bitcoin, size: 30, color: Colors.amber),
            const SizedBox(width: 10),
            Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return Text(
                  walletProvider.btcBalance.toStringAsFixed(18),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                );
              },
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromARGB(255, 12, 69, 168),
          tabs: const [
            Tab(icon: Icon(Icons.monetization_on), text: 'Free Contracts'),
            Tab(icon: Icon(Icons.engineering), text: 'Paid Contracts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFreeContractsView(),
          _buildPaidContractsView(),
        ],
      ),
    );
  }

  Widget _buildFreeContractsView() {
    return StatefulBuilder(
      builder: (context, setState) {
        // Update UI every second
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {});
          }
        });

        // 1 native ad position: after 1st contract
        final nativeAdPositions = <int>{1};
        // 1 banner ad position: top
        final bannerAdPositions = <int>{};

        final totalItems = contracts.length +
            nativeAdPositions.length +
            bannerAdPositions.length +
            1; // +1 for top banner ad

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // Sabse upar banner ad
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: FutureBuilder<Widget?>(
                  future: _bannerAdFuture1,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      return snapshot.data!;
                    } else {
                      return const SizedBox(height: 50);
                    }
                  },
                ),
              );
            }

            // Index adjust karo (kyunki ek banner ad upar aa gaya)
            final adjustedIndex = index - 1;

            // Native ad position: after 1st contract
            if (adjustedIndex == 1) {
              return Container(
                height: 250,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: _adService.isNativeAdLoaded
                    ? _adService.getNativeAd()
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.ads_click,
                                  color: Colors.grey, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'Ad Loading...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              );
            }

            // Contract index nikalna (ads ke hisab se adjust kar ke)
            int contractIndex = adjustedIndex;
            if (adjustedIndex > 1) contractIndex--; // Native ad ke liye adjust
            if (contractIndex >= contracts.length) {
              return const SizedBox.shrink();
            }
            final contract = contracts[contractIndex];
            final bool isCompleted = contract['isCompleted'] ?? false;
            final bool canWatchAd = _canWatchAd() && _isAdInitialized;

            return ContractCard(
              contract: contract,
              onWatchAd: canWatchAd ? () => watchAd(contractIndex) : null,
              onStartMining: isCompleted
                  ? null
                  : () => _startContractMining(contractIndex),
              onStopMining: () => stopMining(contractIndex),
              remainingCooldown: _remainingCooldownSeconds,
              isAdServiceReady: _isAdInitialized,
            );
          },
        );
      },
    );
  }

  Widget _buildPaidContractsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.update, size: 50, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Paid Contracts Not Available!',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ContractCard extends StatelessWidget {
  final Map<String, dynamic> contract;
  final VoidCallback? onWatchAd;
  final VoidCallback? onStartMining;
  final VoidCallback onStopMining;
  final int remainingCooldown;
  final bool isAdServiceReady;

  const ContractCard({
    super.key,
    required this.contract,
    required this.onWatchAd,
    this.onStartMining,
    required this.onStopMining,
    this.remainingCooldown = 0,
    this.isAdServiceReady = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress based on target earnings.
    final double progress = contract['earnings'] > 0
        ? (contract['currentEarnings'] / contract['earnings']).clamp(0.0, 1.0)
        : 0.0;

    final bool isCompleted = contract['isCompleted'] ?? false;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          if (contract['isMining'])
            const Positioned.fill(child: MiningBackground()),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isCompleted
                    ? [
                        const Color.fromARGB(255, 64, 128, 64),
                        const Color.fromARGB(255, 128, 192, 128)
                      ]
                    : [
                        const Color.fromARGB(255, 8, 65, 112),
                        const Color.fromARGB(255, 164, 180, 72)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with percentage indicator at the top right.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          contract['title'],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  const Color.fromRGBO(255, 255, 255, 0.1),
                              color: Colors.green,
                              strokeWidth: 6,
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hash Rate: ${contract['hashRate']} TH/s',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'Duration: ${contract['duration']} days',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Earnings: ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${contract['earnings']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.currency_bitcoin,
                        size: 20,
                        color: Color.fromARGB(255, 211, 174, 8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Current Earnings: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 211, 198, 11),
                        ),
                      ),
                      Text(
                        '${contract['currentEarnings'].toStringAsFixed(18)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 196, 146, 9),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.currency_bitcoin,
                        size: 20,
                        color: Color.fromARGB(255, 211, 163, 7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ads Watched: ${contract['adsWatched']} / ${contract['adsRequired']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCompleted) ...[
                        ElevatedButton.icon(
                          onPressed: onWatchAd,
                          icon: const Icon(Icons.play_circle_fill, size: 16),
                          label: Text(!isAdServiceReady
                              ? 'Loading Ads...'
                              : remainingCooldown > 0
                                  ? 'Wait ${remainingCooldown}s'
                                  : 'Watch Ad'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !isAdServiceReady || remainingCooldown > 0
                                    ? Colors.grey
                                    : Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                        ),
                        contract['isMining']
                            ? ElevatedButton.icon(
                                onPressed: onStopMining,
                                icon: const Icon(Icons.stop_circle, size: 16),
                                label: const Text('Stop Mining'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: (contract['adsWatched'] >=
                                            contract['adsRequired'] &&
                                        onStartMining != null)
                                    ? onStartMining
                                    : null,
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('Start Mining'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                ),
                              ),
                      ] else ...[
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Contract Completed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                ],
              ),
            ),
          ),
          if (isCompleted)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
}

class MiningBackground extends StatefulWidget {
  const MiningBackground({super.key});

  @override
  _MiningBackgroundState createState() => _MiningBackgroundState();
}

class _MiningBackgroundState extends State<MiningBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(
        Tween<double>(begin: 0.3, end: 0.6),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 0, 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
