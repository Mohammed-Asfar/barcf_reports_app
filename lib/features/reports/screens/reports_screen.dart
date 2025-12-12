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
      body: Row(
        children: [
          // SIDEBAR (Permanent on Desktop)
          Container(
            width: 250,
            color: const Color(0xFF0F172A), // Dark Navy
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 20,
                      child: const Text('BR',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'BARCF Reports',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 48),

                // Main Menu
                const Text('Main',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: true, // Currently on Dashboard
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.receipt,
                  label: 'All Reports',
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.description,
                  label: 'My Reports',
                  onTap: () {},
                ),

                const Spacer(),

                // Other
                const Text('Other',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                if (user.role == 'superadmin' || user.role == 'admin')
                  _SidebarItem(
                    icon: Icons.settings,
                    label: 'User Management',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserManagementScreen()),
                      );
                    },
                  ),

                const SizedBox(height: 24),
                _SidebarItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: Colors.white70,
                  onTap: () {
                    authProvider.logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreenStub()),
                    );
                  },
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Container(
              color: const Color(
                  0xFF111827), // Slightly different dark for main area or same? Screenshot looks same-ish or deep teal/green gradient?
              // Screenshot "Dashboard" matches Sidebar background. "Create Invoice" page has dark green background.
              // Let's stick to theme background.
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Top Bar / Search
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: const InputDecoration(
                                hintText: 'Search by report number or name...',
                                border: InputBorder.none,
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Actions
                        IconButton(
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B)),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadIssues,
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const IssueFormScreen()),
                            ).then((_) => _loadIssues());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Report'),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18), // Match input height
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // LIST VIEW
                    Expanded(
                      child: reportsProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredIssues.isEmpty
                              ? const Center(
                                  child: Text('No reports found.',
                                      style: TextStyle(color: Colors.white54)))
                              : ListView.separated(
                                  itemCount: filteredIssues.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final issue = filteredIssues[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: const Color(
                                            0xFF1E293B), // Card color
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 8),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                              Icons.assignment_outlined,
                                              color: Colors.white),
                                        ),
                                        title: Text(
                                          '${issue.sno ?? "N/A"} - ${issue.name}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          issue.problem,
                                          style: const TextStyle(
                                              color: Colors.white54),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: issue.isIssueSorted
                                                    ? Colors.green
                                                        .withOpacity(0.2)
                                                    : Colors.red
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                issue.isIssueSorted
                                                    ? 'Sorted'
                                                    : 'Pending',
                                                style: TextStyle(
                                                  color: issue.isIssueSorted
                                                      ? Colors.greenAccent
                                                      : Colors.redAccent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.chevron_right,
                                                color: Colors.white54),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  IssueFormScreen(issue: issue),
                                            ),
                                          ).then((_) => _loadIssues());
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? color;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // If selected, use Primary color, else use provided color or white54
    final contentColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : (color ?? Colors.white54);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1), // Highlight bg
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, color: contentColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : contentColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
