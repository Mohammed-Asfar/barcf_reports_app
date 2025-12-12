import 'package:barcf_reports_app/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:barcf_reports_app/core/auth/auth_service.dart';
import '../models/issue_model.dart';
import '../providers/reports_provider.dart';
import 'issue_form_screen.dart';
import '../services/export_service.dart';
import '../../admin/screens/user_management_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Defer loading until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIssues();
    });
  }

  void _loadIssues() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      Provider.of<ReportsProvider>(context, listen: false)
          .fetchIssues(user.id, role: user.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthService>(context);
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    // Filter Logic locally for now
    List<Issue> filteredIssues = reportsProvider.issues.where((issue) {
      final query = _searchQuery.toLowerCase();
      return issue.name.toLowerCase().contains(query) ||
          issue.empNo.toLowerCase().contains(query) ||
          issue.problem.toLowerCase().contains(query) ||
          issue.attendedBy.toLowerCase().contains(query) ||
          (issue.sno?.toString().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('BARCF Reports - ${user.username} (${user.role})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIssues,
            tooltip: 'Refresh',
          ),
          if (user.role == 'superadmin' || user.role == 'admin')
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserManagementScreen()),
                );
              },
              tooltip: 'Manage Users',
            ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () =>
                ExportService.exportToCsv(filteredIssues), // Impl later
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () =>
                ExportService.exportToPdf(filteredIssues, user), // Impl later
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(
                  context, '/'); // Or logic to go back
              // Since we pushed replacement, we might need to recreate LoginScreen or pop
              // For now, main.dart logic doesn't support 'named' routes fully unless defined.
              // Let's just push LoginScreen replacement.
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const LoginScreenStub()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search (Name, EmpNo, Problem...)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const IssueFormScreen()),
                    ).then((_) => _loadIssues());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Issue'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: reportsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredIssues.isEmpty
                      ? const Center(child: Text('No reports found.'))
                      : DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 800,
                          columns: const [
                            DataColumn2(
                                label: Text('S.No'), size: ColumnSize.S),
                            DataColumn2(
                                label: Text('Date'), size: ColumnSize.S),
                            DataColumn2(
                                label: Text('Name'), size: ColumnSize.M),
                            DataColumn2(
                                label: Text('Emp No'), size: ColumnSize.S),
                            DataColumn2(
                                label: Text('Problem'), size: ColumnSize.L),
                            DataColumn2(
                                label: Text('Sorted?'), size: ColumnSize.S),
                            DataColumn2(
                                label: Text('Attended By'), size: ColumnSize.M),
                            DataColumn2(
                                label: Text('Actions'), size: ColumnSize.S),
                          ],
                          rows: filteredIssues.map((issue) {
                            return DataRow(cells: [
                              DataCell(Text(issue.sno?.toString() ?? '-')),
                              DataCell(Text(
                                  DateFormat('yyyy-MM-dd').format(issue.date))),
                              DataCell(Text(issue.name)),
                              DataCell(Text(issue.empNo)),
                              DataCell(Text(issue.problem)),
                              DataCell(
                                Icon(
                                  issue.isIssueSorted
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: issue.isIssueSorted
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              DataCell(Text(issue.attendedBy)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              IssueFormScreen(issue: issue),
                                        ),
                                      ).then((_) => _loadIssues());
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Issue'),
                                          content: const Text(
                                              'Are you sure you want to delete this issue?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await reportsProvider.deleteIssue(
                                            issue.id!, user.id!);
                                      }
                                    },
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Temporary Stub to break circular dependency in navigation for now or just import LoginScreen

class LoginScreenStub extends StatelessWidget {
  const LoginScreenStub({super.key});
  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
