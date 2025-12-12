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
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
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

    // Filter Logic
    List<Issue> filteredIssues = reportsProvider.issues.where((issue) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = issue.name.toLowerCase().contains(query) ||
          issue.empNo.toLowerCase().contains(query) ||
          issue.problem.toLowerCase().contains(query) ||
          issue.attendedBy.toLowerCase().contains(query) ||
          (issue.sno?.toString().contains(query) ?? false);

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Resolved' && issue.isIssueSorted) ||
          (_statusFilter == 'Pending' && !issue.isIssueSorted);

      return matchesSearch && matchesStatus;
    }).toList();

    final totalIssues = reportsProvider.issues.length;
    final resolvedCount =
        reportsProvider.issues.where((i) => i.isIssueSorted).length;
    final pendingCount =
        reportsProvider.issues.where((i) => !i.isIssueSorted).length;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(user, authProvider),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(user),
                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        _buildPageHeader(),
                        const SizedBox(height: 24),
                        // Stats Cards
                        _buildStatsRow(
                            totalIssues, resolvedCount, pendingCount),
                        const SizedBox(height: 24),
                        // Report List Section
                        _buildReportListSection(
                            filteredIssues, reportsProvider, user),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(user, AuthService authProvider) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14),
        border:
            Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.article, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'BARCF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          // Navigation Items
          _buildNavItem(Icons.dashboard_outlined, 'Dashboard', true),
          _buildNavItem(Icons.list_alt_outlined, 'All Reports', false),
          if (user.role == 'superadmin' || user.role == 'admin')
            _buildNavItem(Icons.people_outline, 'User Management', false,
                onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()));
            }),
          const Spacer(),
          const Divider(color: Colors.white12),
          // User Profile
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED),
                  radius: 20,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.logout, color: Colors.grey.shade500, size: 20),
                  onPressed: () {
                    authProvider.logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreenStub()),
                    );
                  },
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF7C3AED).withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? const Color(0xFF7C3AED) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isActive ? const Color(0xFF7C3AED) : Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade500,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14),
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          // Breadcrumb
          Row(
            children: [
              Icon(Icons.home_outlined, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text('/', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Text('Report', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(width: 8),
              Text('/', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              const Text('Issue Reports',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          // Actions
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade400),
            onPressed: _loadIssues,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon:
                Icon(Icons.notifications_outlined, color: Colors.grey.shade400),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              const Icon(Icons.assessment, color: Color(0xFF22C55E), size: 32),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Issue Reports',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Auto-updates in 2 min',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(int total, int resolved, int pending) {
    return Row(
      children: [
        _buildStatCard(
            'Total Issues', total.toString(), const Color(0xFF22C55E)),
        const SizedBox(width: 16),
        _buildStatCard(
            'Resolved', resolved.toString(), const Color(0xFF22C55E)),
        const SizedBox(width: 16),
        _buildStatCard('Pending', pending.toString(), const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Mini chart placeholder
                CustomPaint(
                  size: const Size(80, 30),
                  painter: _SparklinePainter(accentColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last 30 days',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportListSection(
      List<Issue> filteredIssues, ReportsProvider reportsProvider, user) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Report List',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Filter Dropdowns
                _buildFilterDropdown(
                    'All Status', ['All', 'Resolved', 'Pending'], _statusFilter,
                    (val) {
                  setState(() => _statusFilter = val!);
                }),
                const SizedBox(width: 12),
                // Search
                SizedBox(
                  width: 200,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey.shade500, size: 20),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: const Color(0xFF0F0F14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                // Export Buttons
                _buildOutlinedButton(
                    Icons.picture_as_pdf_outlined, 'Export PDF', () {
                  ExportService.exportToPdf(filteredIssues, user);
                }),
                const SizedBox(width: 8),
                _buildOutlinedButton(Icons.table_chart_outlined, 'Export Excel',
                    () {
                  ExportService.exportToCsv(filteredIssues);
                }),
                const SizedBox(width: 8),
                // New Issue Button
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const IssueFormScreen()),
                    ).then((_) => _loadIssues());
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Issue'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Data Table
          SizedBox(
            height: 500,
            child: reportsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredIssues.isEmpty
                    ? _buildEmptyState()
                    : _buildDataTable(filteredIssues, reportsProvider, user),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String value,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1A1A24),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(
      IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade400,
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text('No reports found',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDataTable(
      List<Issue> issues, ReportsProvider reportsProvider, user) {
    return DataTable2(
      columnSpacing: 16,
      horizontalMargin: 20,
      headingRowHeight: 52,
      dataRowHeight: 56,
      headingTextStyle: TextStyle(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      columns: const [
        DataColumn2(label: Text('S.No'), size: ColumnSize.S),
        DataColumn2(label: Text('Name'), size: ColumnSize.M),
        DataColumn2(label: Text('Emp No'), size: ColumnSize.S),
        DataColumn2(label: Text('Problem'), size: ColumnSize.L),
        DataColumn2(label: Text('Date'), size: ColumnSize.S),
        DataColumn2(label: Text('Attended By'), size: ColumnSize.M),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
        DataColumn2(label: Text(''), size: ColumnSize.S, numeric: true),
      ],
      rows: issues
          .map((issue) => DataRow(
                cells: [
                  DataCell(Text(issue.sno?.toString() ?? '-',
                      style: const TextStyle(color: Colors.white))),
                  DataCell(Text(issue.name,
                      style: const TextStyle(color: Colors.white))),
                  DataCell(Text(issue.empNo,
                      style: const TextStyle(color: Colors.white))),
                  DataCell(
                    Tooltip(
                      message: issue.problem,
                      child: Text(
                        issue.problem,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  DataCell(Text(DateFormat('dd/MM/yyyy').format(issue.date),
                      style: TextStyle(color: Colors.grey.shade400))),
                  DataCell(Text(issue.attendedBy,
                      style: const TextStyle(color: Colors.white))),
                  DataCell(_buildStatusBadge(issue.isIssueSorted)),
                  DataCell(_buildActionMenu(issue, reportsProvider, user)),
                ],
              ))
          .toList(),
    );
  }

  Widget _buildStatusBadge(bool isResolved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isResolved
            ? const Color(0xFF22C55E).withOpacity(0.15)
            : const Color(0xFFF59E0B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isResolved ? 'Resolved' : 'Pending',
        style: TextStyle(
          color: isResolved ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionMenu(Issue issue, ReportsProvider reportsProvider, user) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
      color: const Color(0xFF1A1A24),
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => IssueFormScreen(issue: issue)),
          ).then((_) => _loadIssues());
        } else if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Issue'),
              content:
                  const Text('Are you sure you want to delete this issue?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await reportsProvider.deleteIssue(issue.id!, user.id!);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 8),
                Text('Edit')
              ],
            )),
        const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.redAccent))
              ],
            )),
      ],
    );
  }
}

// Sparkline painter for mini charts
class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.6);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Temporary Stub
class LoginScreenStub extends StatelessWidget {
  const LoginScreenStub({super.key});
  @override
  Widget build(BuildContext context) => const LoginScreen();
}
