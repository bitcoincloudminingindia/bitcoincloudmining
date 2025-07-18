import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_api_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String _selectedTarget = 'All Users';
  String _selectedPriority = 'Normal';
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _isScheduled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    Future.delayed(Duration.zero, () {
      final provider = Provider.of<AdminApiProvider>(context, listen: false);
      provider.fetchNotifications();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _targetController.dispose();
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
                _buildNotificationStats(provider),
                const SizedBox(height: 32),
                _buildSendNotificationCard(),
                const SizedBox(height: 32),
                _buildNotificationHistory(provider),
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
              'Notifications',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send push notifications to users',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_active, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Firebase FCM',
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationStats(AdminApiProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Sent Today', '24', Icons.send, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Scheduled',
            '3',
            Icons.schedule,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Delivery Rate',
            '98.5%',
            Icons.trending_up,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Open Rate',
            '67.2%',
            Icons.visibility,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _animationController.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendNotificationCard() {
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
            'Send Notification',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            controller: _titleController,
            label: 'Notification Title',
            hint: 'Enter notification title...',
            icon: Icons.title,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _messageController,
            label: 'Message',
            hint: 'Enter notification message...',
            icon: Icons.message,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Target Audience',
                  _selectedTarget,
                  [
                    'All Users',
                    'By UID',
                    'By Country',
                    'Active Users',
                    'New Users',
                  ],
                  (value) => setState(() => _selectedTarget = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Priority',
                  _selectedPriority,
                  ['Low', 'Normal', 'High', 'Urgent'],
                  (value) => setState(() => _selectedPriority = value!),
                ),
              ),
            ],
          ),
          if (_selectedTarget == 'By UID') ...[
            const SizedBox(height: 16),
            _buildInputField(
              controller: _targetController,
              label: 'User UID',
              hint: 'Enter specific user UID...',
              icon: Icons.person,
            ),
          ],
          if (_selectedTarget == 'By Country') ...[
            const SizedBox(height: 16),
            _buildDropdown('Country', 'India', [
              'India',
              'USA',
              'UK',
              'Canada',
              'Australia',
              'Germany',
              'France',
            ], (value) {}),
          ],
          const SizedBox(height: 16),
          _buildScheduleSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Send Now',
                  Icons.send,
                  Colors.green,
                  () => _sendNotification(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Schedule',
                  Icons.schedule,
                  Colors.blue,
                  () => _scheduleNotification(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Preview',
                  Icons.preview,
                  Colors.orange,
                  () => _previewNotification(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(color: Colors.white),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.white54),
              prefixIcon: Icon(icon, color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            style: GoogleFonts.poppins(color: Colors.white),
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            items: options.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: _isScheduled,
              onChanged: (value) => setState(() => _isScheduled = value),
              activeColor: Colors.blue,
              activeTrackColor: Colors.blue.withOpacity(0.3),
              inactiveTrackColor: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(width: 12),
            Text(
              'Schedule Notification',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (_isScheduled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDatePicker()),
              const SizedBox(width: 16),
              Expanded(child: _buildTimePicker()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _scheduledDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      surface: Color(0xFF1E293B),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _scheduledDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Text(
                  _scheduledDate != null
                      ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                      : 'Select Date',
                  style: GoogleFonts.poppins(
                    color: _scheduledDate != null
                        ? Colors.white
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _scheduledTime ?? TimeOfDay.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      surface: Color(0xFF1E293B),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (time != null) {
              setState(() => _scheduledTime = time);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Text(
                  _scheduledTime != null
                      ? _scheduledTime!.format(context)
                      : 'Select Time',
                  style: GoogleFonts.poppins(
                    color: _scheduledTime != null
                        ? Colors.white
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationHistory(AdminApiProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notification History',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
            itemBuilder: (context, index) {
              return _buildNotificationItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(int index) {
    final data = [
      {
        'title': 'Welcome Bonus!',
        'message': 'Get 0.001 BTC bonus on signup',
        'status': 'Sent',
        'time': '2 min ago',
        'recipients': '1,234',
      },
      {
        'title': 'Mining Update',
        'message': 'New mining algorithm available',
        'status': 'Delivered',
        'time': '1 hour ago',
        'recipients': '5,678',
      },
      {
        'title': 'Withdrawal Ready',
        'message': 'Your withdrawal has been processed',
        'status': 'Failed',
        'time': '3 hours ago',
        'recipients': '890',
      },
      {
        'title': 'Referral Reward',
        'message': 'Earn 0.0005 BTC for each referral',
        'status': 'Scheduled',
        'time': 'Tomorrow 10:00 AM',
        'recipients': '2,345',
      },
      {
        'title': 'App Update',
        'message': 'New features available in v2.1',
        'status': 'Sent',
        'time': '1 day ago',
        'recipients': '12,345',
      },
    ];

    final item = data[index];
    Color statusColor;
    IconData statusIcon;

    switch (item['status']) {
      case 'Sent':
        statusColor = Colors.green;
        statusIcon = Icons.send;
        break;
      case 'Delivered':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'Failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'Scheduled':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Text(
        item['title']!,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['message']!,
            style: GoogleFonts.poppins(color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Recipients: ${item['recipients']}',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item['status']!,
              style: GoogleFonts.poppins(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['time']!,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _sendNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement send notification logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent successfully'),
        backgroundColor: Colors.green,
      ),
    );

    _titleController.clear();
    _messageController.clear();
    _targetController.clear();
  }

  void _scheduleNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isScheduled || _scheduledDate == null || _scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select date and time for scheduling'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement schedule notification logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification scheduled successfully'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _previewNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Notification Preview',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _titleController.text,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Message:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _messageController.text,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Target: $_selectedTarget',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            Text(
              'Priority: $_selectedPriority',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
