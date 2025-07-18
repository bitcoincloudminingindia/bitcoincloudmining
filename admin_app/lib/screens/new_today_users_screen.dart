import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewTodayUsersScreen extends StatefulWidget {
  final List<dynamic> users;
  const NewTodayUsersScreen({super.key, required this.users});

  @override
  State<NewTodayUsersScreen> createState() => _NewTodayUsersScreenState();
}

class _NewTodayUsersScreenState extends State<NewTodayUsersScreen> {
  late List<dynamic> todayUsers;

  @override
  void initState() {
    super.initState();
    _filterTodayUsers();
  }

  void _filterTodayUsers() {
    final today = DateTime.now();
    todayUsers = widget.users.where((user) {
      if (user['createdAt'] != null) {
        final createdAt = DateTime.parse(user['createdAt']);
        return createdAt.year == today.year &&
            createdAt.month == today.month &&
            createdAt.day == today.day;
      }
      return false;
    }).toList();
    setState(() {});
  }

  void _removeUser(int index) {
    setState(() {
      todayUsers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Users Today', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF1E293B),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: todayUsers.isEmpty
          ? Center(
              child: Text(
                'No new users today.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: todayUsers.length,
              itemBuilder: (context, index) {
                final user = todayUsers[index];
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      user['userEmail'] ?? user['email'] ?? 'N/A',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    subtitle: Text(
                      user['_id'] ?? user['id'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeUser(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
