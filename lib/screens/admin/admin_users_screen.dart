import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;

  // Mock users data
  final List<Map<String, dynamic>> _users = [
    {
      'id': 'u1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': UserRole.customer,
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      'status': 'active',
    },
    {
      'id': 'u2',
      'name': 'Jane Smith',
      'email': 'jane@venue.com',
      'role': UserRole.venueOwner,
      'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      'status': 'active',
    },
    {
      'id': 'u3',
      'name': 'Admin User',
      'email': 'admin@wherethevibesat.com',
      'role': UserRole.admin,
      'createdAt': DateTime.now().subtract(const Duration(days: 365)),
      'status': 'active',
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = List<Map<String, dynamic>>.from(_users);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedRoleFilter != null) {
      filtered = filtered.where((u) => u['role'] == _selectedRoleFilter).toList();
    }

    return filtered;
  }

  void _changeUserRole(String userId, UserRole newRole) {
    setState(() {
      final user = _users.firstWhere((u) => u['id'] == userId);
      user['role'] = newRole;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User role changed to ${newRole.displayName}'),
      ),
    );
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This action cannot be undone. All associated data will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _users.removeWhere((u) => u['id'] == userId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedRoleFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRoleFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...UserRole.values.map((role) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(role.displayName),
                              selected: _selectedRoleFilter == role,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedRoleFilter = selected ? role : null;
                                });
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final role = user['role'] as UserRole;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: role.color.withOpacity(0.2),
                            child: Icon(
                              role.icon,
                              color: role.color,
                            ),
                          ),
                          title: Text(
                            user['name'],
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(user['email']),
                              Text(
                                '${role.displayName} • Joined ${DateFormat('MMM y').format(user['createdAt'])}',
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit User'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.swap_horiz, size: 20),
                                    SizedBox(width: 8),
                                    Text('Change Role'),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    _showRoleChangeDialog(user['id'], role);
                                  });
                                },
                              ),
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                onTap: () => _deleteUser(user['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeDialog(String userId, UserRole currentRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(role.displayName),
              subtitle: Text(role.description),
              value: role,
              groupValue: currentRole,
              onChanged: (value) {
                if (value != null) {
                  _changeUserRole(userId, value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

