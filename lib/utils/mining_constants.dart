// Mining rates and constants
class MiningConstants {
  // Base mining rates (in satoshi)
  static const double BASE_MINING_RATE = 0.0000000000000005;
  static const double CLOUD_MINING_RATE = 0.000000000000000030;
  static const double BACKGROUND_MINING_RATE = 0.000000000000000015;
  static const double TAP_REWARD_RATE = 0.000000000000005000;
  static const double AUTO_MINING_RATE = 0.0000000000000003;

  // Contract mining rates (in satoshi)
  static const Map<String, double> CONTRACT_RATES = {
    'trial': 0.0000000000464,
    'basic': 0.0000000000312,
    'express': 0.0000000001388,
    'premium': 0.000000000000001668,
    'standard': 0.000000000000000832,
    'intermediate': 0.000000000000003704,
  };

  // Timing constants
  static const int MINING_DURATION_MINUTES = 45;
  static const int POWER_BOOST_DURATION_MINUTES = 45;
  static const int STATE_SAVE_INTERVAL_SECONDS = 60;
  static const int AD_SHOW_INTERVAL_MINUTES = 10;
  static const int AUTO_MINING_DURATION_SECONDS = 30;
  static const int BOOST_DURATION_SECONDS = 30;

  // Power boost constants
  static const double POWER_BOOST_RATE = 4.0;
  static const double BOOST_MULTIPLIER = 3.5;

  // Hash rates (in H/s)
  static const double BASE_HASH_RATE = 10.0;
  static const Map<String, double> CONTRACT_HASH_RATES = {
    'trial': 200.0,
    'basic': 400.0,
    'express': 1200.0,
    'premium': 2000.0,
    'standard': 1000.0,
    'intermediate': 1600.0,
  };

  // Game reward ranges (in satoshi)
  static const List<Map<String, double>> REWARD_RANGES = [
    {'min': 0.000000000000005, 'max': 0.000000000000045},
    {'min': 0.000000000000050, 'max': 0.000000000000450},
    {'min': 0.000000000000500, 'max': 0.000000000004500},
    {'min': 0.000000000005000, 'max': 0.000000000045000},
    {'min': 0.000000000050000, 'max': 0.000000000450000},
  ];

  // Game reward weights
  static const List<int> REWARD_WEIGHTS = [40, 30, 20, 7, 3];
}
