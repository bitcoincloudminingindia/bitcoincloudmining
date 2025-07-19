import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/admin_api_provider.dart';
import '../services/api_service.dart';
import '../utils/expanded_overflow_fix.dart';
import 'new_today_users_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'Date';

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final provider = Provider.of<AdminApiProvider>(context, listen: false);
      provider.fetchUsers(); // Fetch real user data
    });
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
            child: ExpandFix.column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchAndFilters(),
                _buildUserStats(provider),
                _buildUserList(provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ExpandFix.row(
        children: [
          const Icon(Icons.people, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          ExpandFix.column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Manage all registered users',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ExpandFix.row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by email or UID...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterDropdown(
            'Status',
            _filterStatus,
            ['All', 'Active', 'Suspended'],
            (value) {
              setState(() => _filterStatus = value);
            },
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            'Sort By',
            _sortBy,
            ['Date', 'Name', 'Balance'],
            (value) {
              setState(() => _sortBy = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: (newValue) => onChanged(newValue!),
        style: GoogleFonts.poppins(color: Colors.white),
        dropdownColor: const Color(0xFF1E293B),
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserStats(AdminApiProvider provider) {
    final totalUsers = provider.users.length;
    final activeUsers = provider.users
        .where((user) => user['status'] == 'active')
        .length;
    final suspendedUsers = provider.users
        .where(
          (user) =>
              user['status'] == 'suspended' || user['status'] == 'blocked',
        )
        .length;

    // Calculate new users today
    final today = DateTime.now();
    final newToday = provider.users.where((user) {
      if (user['createdAt'] != null) {
        final createdAt = DateTime.parse(user['createdAt']);
        return createdAt.year == today.year &&
            createdAt.month == today.month &&
            createdAt.day == today.day;
      }
      return false;
    }).length;

    return Container(
      margin: const EdgeInsets.all(24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          _buildStatCard(
            'Total Users',
            totalUsers.toString(),
            Icons.people,
            Colors.blue,
          ),
          _buildStatCard(
            'Active Users',
            activeUsers.toString(),
            Icons.person,
            Colors.green,
          ),
          _buildStatCard(
            'Suspended',
            suspendedUsers.toString(),
            Icons.block,
            Colors.red,
          ),
          _buildStatCard(
            'New Today',
            newToday.toString(),
            Icons.trending_up,
            Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewTodayUsersScreen(users: provider.users),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(AdminApiProvider provider) {
    if (provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    final filteredUsers = provider.users.where((user) {
      final matchesSearch =
          user['userEmail']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true ||
          user['email']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true ||
          user['_id']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true ||
          user['id']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true;

      final matchesStatus =
          _filterStatus == 'All' ||
          (_filterStatus == 'Active' && user['status'] == 'active') ||
          (_filterStatus == 'Suspended' &&
              (user['status'] == 'suspended' || user['status'] == 'blocked'));

      return matchesSearch && matchesStatus;
    }).toList();

    List<Widget> userWidgets = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          'User List (${filteredUsers.length} users)',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
    userWidgets.addAll(
      filteredUsers.map((user) => _buildUserCard(user)).toList(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: userWidgets,
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['status'] == 'active';
    final userEmail = user['userEmail'] ?? user['email'] ?? 'N/A';
    final userId = user['userId'] ?? user['id'] ?? user['_id'] ?? 'N/A';
    final balance = user['balance'] ?? user['wallet']?['balance'] ?? '0';
    final profilePicture =
        user['profilePicture'] ?? user['profileImage'] ?? user['avatar'];
    final imageUrl =
        (profilePicture != null && profilePicture.toString().isNotEmpty)
        ? ApiConfig.proxyImageBase +
              Uri.encodeComponent(profilePicture.toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 140),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ExpandFix.row(
          children: [
            // Profile Picture
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.person,
                            color: isActive ? Colors.green : Colors.red,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.person,
                        color: isActive ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User ID and Email
                  ExpandFix.row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${userId.toString()}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Wallet Balance and Status
                  ExpandFix.row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$balance BTC',
                          style: GoogleFonts.poppins(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: GoogleFonts.poppins(
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            IconButton(
              onPressed: () => _showUserActions(user),
              icon: const Icon(Icons.more_vert, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserActions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              user['status'] == 'active' ? 'Suspend User' : 'Activate User',
              user['status'] == 'active' ? Icons.block : Icons.check_circle,
              user['status'] == 'active' ? Colors.red : Colors.green,
              () {
                Navigator.pop(context);
                _toggleUserStatus(user);
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'View Details',
              Icons.visibility,
              Colors.blue,
              () {
                Navigator.pop(context);
                _viewUserDetails(user);
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton('Update Balance', Icons.edit, Colors.orange, () {
              Navigator.pop(context);
              _showBalanceUpdateDialog(user);
            }),
          ],
        ),
      ),
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) {
    // TODO: Implement user status toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User status updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showBalanceUpdateDialog(Map<String, dynamic> user) {
    final controller = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Update Balance',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New Balance (BTC)',
                labelStyle: GoogleFonts.poppins(color: Colors.white54),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: GoogleFonts.poppins(color: Colors.white54),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim()) ?? 0;
              if (amount == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final userId = user['userId'] ?? user['id'] ?? user['_id'] ?? '';
              final success = await ApiService().adjustWallet(
                userId: userId,
                amount: amount,
                type: 'credit',
                note: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : 'Admin adjustment',
              );
              Navigator.pop(context);
              if (success) {
                await Provider.of<AdminApiProvider>(
                  context,
                  listen: false,
                ).fetchUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Balance updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update balance'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Update',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
    );
  }
}
