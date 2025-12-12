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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username')),
            TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: role,
              items: [
                const DropdownMenuItem(value: 'user', child: Text('User')),
                if (currentUserRole == 'superadmin')
                  const DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (val) => role = val!,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
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
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : DataTable2(
              columns: const [
                DataColumn2(label: Text('ID'), size: ColumnSize.S),
                DataColumn2(label: Text('Username'), size: ColumnSize.L),
                DataColumn2(label: Text('Role'), size: ColumnSize.M),
                DataColumn2(label: Text('Actions'), size: ColumnSize.S),
              ],
              rows: userProvider.users.map((u) {
                return DataRow(cells: [
                  DataCell(Text(u.id.toString())),
                  DataCell(Text(u.username)),
                  DataCell(Text(u.role)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Prevent deleting self or superadmin if not superadmin?
                      // Generic simple check
                      if (u.username == 'superadmin') return;
                      userProvider.deleteUser(u.id!);
                    },
                  )),
                ]);
              }).toList(),
            ),
    );
  }
}
