import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_api_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _maintenanceMode = false;
  bool _autoMiningEnabled = true;
  bool _referralRewardsEnabled = true;
  bool _withdrawalEnabled = true;
  String _selectedMiningAlgorithm = 'SHA-256';
  final String _appVersion = '2.1.0';
  double _miningDifficulty = 0.5;
  double _referralRate = 0.1;
  final _formKey = GlobalKey<FormState>();
  double? _percent;
  int? _days;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    Future.delayed(Duration.zero, () {
      final provider = Provider.of<AdminApiProvider>(context, listen: false);
      provider.fetchSettings();
      _animationController.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = Provider.of<AdminApiProvider>(context, listen: false);
        await provider.fetchReferralSettings();
        setState(() {
          _percent =
              provider.referralSettings['referralDailyPercent']?.toDouble() ??
              1.0;
          _days =
              provider.referralSettings['referralEarningDays']?.toInt() ?? 30;
        });
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminApiProvider>(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSystemStatus(),
                const SizedBox(height: 32),
                _buildMiningSettings(),
                const SizedBox(height: 32),
                _buildAppSettings(),
                const SizedBox(height: 32),
                _buildSecuritySettings(),
                const SizedBox(height: 32),
                _buildAdvancedSettings(),
                const SizedBox(height: 32),
                _buildActionsSection(),
                const SizedBox(height: 32),
                _buildReferralSettings(provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings & Controls',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Configure system settings and controls',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text(
                'All Systems OK',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Mining Server',
                  'Online',
                  Colors.green,
                  Icons.dns,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  'Database',
                  'Online',
                  Colors.green,
                  Icons.storage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  'API Gateway',
                  'Online',
                  Colors.green,
                  Icons.api,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  'Firebase',
                  'Online',
                  Colors.green,
                  Icons.cloud,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String name,
    String status,
    Color statusColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: GoogleFonts.poppins(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiningSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mining Configuration',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingToggle(
            'Auto Mining',
            'Enable automatic mining for users',
            Icons.speed,
            Colors.blue,
            _autoMiningEnabled,
            (value) => setState(() => _autoMiningEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildDropdownSetting(
            'Mining Algorithm',
            'Select the mining algorithm',
            Icons.memory,
            Colors.green,
            _selectedMiningAlgorithm,
            ['SHA-256', 'Scrypt', 'Ethash', 'RandomX'],
            (value) => setState(() => _selectedMiningAlgorithm = value!),
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            'Mining Difficulty',
            'Adjust mining difficulty level',
            Icons.tune,
            Colors.orange,
            _miningDifficulty,
            (value) => setState(() => _miningDifficulty = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingToggle(
            'Maintenance Mode',
            'Enable maintenance mode for app updates',
            Icons.build,
            Colors.orange,
            _maintenanceMode,
            (value) => setState(() => _maintenanceMode = value),
          ),
          const SizedBox(height: 16),
          _buildInfoSetting(
            'App Version',
            'Current app version',
            Icons.info,
            Colors.blue,
            _appVersion,
          ),
          const SizedBox(height: 16),
          _buildSettingToggle(
            'Referral Rewards',
            'Enable referral reward system',
            Icons.share,
            Colors.purple,
            _referralRewardsEnabled,
            (value) => setState(() => _referralRewardsEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildSliderSetting(
            'Referral Rate',
            'Set referral reward percentage',
            Icons.percent,
            Colors.purple,
            _referralRate,
            (value) => setState(() => _referralRate = value),
          ),
          const SizedBox(height: 16),
          _buildSettingToggle(
            'Withdrawals',
            'Enable withdrawal functionality',
            Icons.swap_horiz,
            Colors.green,
            _withdrawalEnabled,
            (value) => setState(() => _withdrawalEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security & Access',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionSetting(
            'Change Admin Password',
            'Update admin account password',
            Icons.lock,
            Colors.red,
            () => _changePassword(),
          ),
          const SizedBox(height: 16),
          _buildActionSetting(
            'Two-Factor Authentication',
            'Configure 2FA for admin access',
            Icons.security,
            Colors.blue,
            () => _configure2FA(),
          ),
          const SizedBox(height: 16),
          _buildActionSetting(
            'Session Management',
            'Manage active admin sessions',
            Icons.devices,
            Colors.green,
            () => _manageSessions(),
          ),
          const SizedBox(height: 16),
          _buildActionSetting(
            'Access Logs',
            'View admin access history',
            Icons.history,
            Colors.orange,
            () => _viewAccessLogs(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionSetting(
            'Remote Config',
            'Update Firebase Remote Config',
            Icons.cloud_sync,
            Colors.blue,
            () => _updateRemoteConfig(),
          ),
          const SizedBox(height: 16),
          _buildActionSetting(
            'Database Backup',
            'Create database backup',
            Icons.backup,
            Colors.green,
            () => _createBackup(),
          ),
          const SizedBox(height: 16),
          _buildActionSetting(
            'Cache Management',
            'Clear system cache',
            Icons.cleaning_services,
            Colors.orange,
            () => _clearCache(),
          ),
          const SizedBox(height: 16),
          _buildActionSetting(
            'System Logs',
            'View system logs',
            Icons.article,
            Colors.purple,
            () => _viewSystemLogs(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              style: GoogleFonts.poppins(color: Colors.white),
              dropdownColor: const Color(0xFF1E293B),
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: options.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    double value,
    Function(double) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            inactiveColor: Colors.white.withOpacity(0.1),
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSetting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Save Settings',
                'Apply all changes',
                Icons.save,
                Colors.green,
                () => _saveSettings(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Reset to Default',
                'Restore default settings',
                Icons.restore,
                Colors.orange,
                () => _resetSettings(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Export Config',
                'Export current settings',
                Icons.download,
                Colors.blue,
                () => _exportConfig(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralSettings(AdminApiProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referral Settings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _percent?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Referral Daily Earning Percentage (%)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (val) {
                final v = double.tryParse(val ?? '');
                if (v == null || v < 0 || v > 100) {
                  return 'Enter a valid percent (0-100)';
                }
                return null;
              },
              onChanged: (val) => _percent = double.tryParse(val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _days?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Referral Earning Duration (days)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                final v = int.tryParse(val ?? '');
                if (v == null || v < 1 || v > 365) {
                  return 'Enter days (1-365)';
                }
                return null;
              },
              onChanged: (val) => _days = int.tryParse(val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() => _loading = true);
                          await provider.updateReferralSettings(
                            _percent ?? 1.0,
                            _days ?? 30,
                          );
                          setState(() => _loading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral settings updated!'),
                            ),
                          );
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _changePassword() {
    // TODO: Implement password change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password change dialog opened'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _configure2FA() {
    // TODO: Implement 2FA configuration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('2FA configuration opened'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _manageSessions() {
    // TODO: Implement session management
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session management opened'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewAccessLogs() {
    // TODO: Implement access logs view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access logs opened'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _updateRemoteConfig() {
    // TODO: Implement remote config update
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Remote config updated'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _createBackup() {
    // TODO: Implement database backup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Database backup created'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearCache() {
    // TODO: Implement cache clearing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cache cleared'), backgroundColor: Colors.orange),
    );
  }

  void _viewSystemLogs() {
    // TODO: Implement system logs view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('System logs opened'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implement settings save
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetSettings() {
    // TODO: Implement settings reset
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings reset to default'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _exportConfig() {
    // TODO: Implement config export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Configuration exported'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
