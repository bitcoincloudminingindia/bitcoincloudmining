import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserSelectionDialog extends StatefulWidget {
  const UserSelectionDialog({Key? key}) : super(key: key);

  @override
  _UserSelectionDialogState createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _users = [];
  List<String> _selectedUserIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getUsers();

      if (response['success']) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response['data']['users']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Users'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return CheckboxListTile(
                          title: Text(user['userEmail'] ?? ''),
                          subtitle: Text(user['userId'] ?? ''),
                          value: _selectedUserIds.contains(user['userId']),
                          onChanged: (selected) {
                            setState(() {
                              if (selected!) {
                                _selectedUserIds.add(user['userId']);
                              } else {
                                _selectedUserIds.remove(user['userId']);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedUserIds),
          child: Text('Select (${_selectedUserIds.length})'),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final email = user['userEmail']?.toString().toLowerCase() ?? '';
      final id = user['userId']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return email.contains(query) || id.contains(query);
    }).toList();
  }
}
