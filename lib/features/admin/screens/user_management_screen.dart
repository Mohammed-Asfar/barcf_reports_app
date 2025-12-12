import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../core/auth/auth_service.dart';
import '../providers/user_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'user';
    final currentUserRole =
        Provider.of<AuthService>(context, listen: false).currentUser?.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(hintText: 'Username')),
              const SizedBox(height: 16),
              TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                items: [
                  const DropdownMenuItem(value: 'user', child: Text('User')),
                  if (currentUserRole == 'superadmin')
                    const DropdownMenuItem(
                        value: 'admin', child: Text('Admin')),
                ],
                onChanged: (val) => role = val!,
                decoration: const InputDecoration(hintText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final success =
                  await Provider.of<UserProvider>(context, listen: false)
                      .addUser(
                usernameController.text,
                passwordController.text,
                role,
                Provider.of<AuthService>(context, listen: false)
                    .currentUser!
                    .id!,
              );
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: userProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : userProvider.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_outlined,
                                size: 64, color: Colors.grey.shade600),
                            const SizedBox(height: 16),
                            Text('No users found',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      )
                    : DataTable2(
                        headingRowHeight: 56,
                        dataRowHeight: 60,
                        columnSpacing: 16,
                        horizontalMargin: 20,
                        columns: const [
                          DataColumn2(label: Text('ID'), size: ColumnSize.S),
                          DataColumn2(
                              label: Text('Username'), size: ColumnSize.L),
                          DataColumn2(label: Text('Role'), size: ColumnSize.M),
                          DataColumn2(
                              label: Text('Actions'),
                              size: ColumnSize.S,
                              numeric: true),
                        ],
                        rows: userProvider.users.map((u) {
                          return DataRow(cells: [
                            DataCell(Text(u.id.toString())),
                            DataCell(Text(u.username)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: u.role == 'superadmin'
                                      ? Colors.purple.withOpacity(0.15)
                                      : u.role == 'admin'
                                          ? Colors.blue.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  u.role.toUpperCase(),
                                  style: TextStyle(
                                    color: u.role == 'superadmin'
                                        ? Colors.purpleAccent
                                        : u.role == 'admin'
                                            ? Colors.blueAccent
                                            : Colors.grey.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              u.username == 'superadmin'
                                  ? const SizedBox.shrink()
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteUser(
                                          u.id!, u.username, userProvider),
                                      tooltip: 'Delete user',
                                    ),
                            ),
                          ]);
                        }).toList(),
                      ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(
      int userId, String username, UserProvider userProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "$username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await userProvider.deleteUser(userId);
    }
  }
}
