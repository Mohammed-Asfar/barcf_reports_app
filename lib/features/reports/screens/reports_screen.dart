import 'package:barcf_reports_app/core/theme/app_theme.dart';
import 'package:barcf_reports_app/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:barcf_reports_app/core/auth/auth_service.dart';
import '../models/issue_model.dart';
import '../providers/reports_provider.dart';
import 'issue_form_screen.dart';
import 'issue_detail_screen.dart';
import '../services/export_service.dart';
import '../../admin/providers/user_provider.dart';
import '../../computers/screens/computer_list_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _attendedByFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Sidebar navigation
  String _activeSection = 'dashboard'; // 'dashboard', 'computers', 'users'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIssues();
      _loadUsers();
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

  void _loadUsers() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null && (user.role == 'superadmin' || user.role == 'admin')) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    }
  }

  List<Issue> _getFilteredIssues(List<Issue> issues) {
    return issues.where((issue) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = issue.name.toLowerCase().contains(query) ||
          issue.empNo.toLowerCase().contains(query) ||
          issue.problem.toLowerCase().contains(query) ||
          issue.attendedBy.toLowerCase().contains(query) ||
          (issue.sno?.toString().contains(query) ?? false);

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Resolved' && issue.isIssueSorted) ||
          (_statusFilter == 'Pending' && !issue.isIssueSorted);

      final matchesAttendedBy =
          _attendedByFilter == 'All' || issue.attendedBy == _attendedByFilter;

      final matchesDateRange = (_fromDate == null ||
              issue.date
                  .isAfter(_fromDate!.subtract(const Duration(days: 1)))) &&
          (_toDate == null ||
              issue.date.isBefore(_toDate!.add(const Duration(days: 1))));

      return matchesSearch &&
          matchesStatus &&
          matchesAttendedBy &&
          matchesDateRange;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _statusFilter = 'All';
      _attendedByFilter = 'All';
      _fromDate = null;
      _toDate = null;
    });
  }

  // Show date range picker for export and filter data accordingly
  Future<void> _showExportWithDateRange(String exportType, dynamic user) async {
    final reportsProvider =
        Provider.of<ReportsProvider>(context, listen: false);

    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A24),
              onSurface: Colors.white,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: child!,
            ),
          ),
        );
      },
    );

    if (range != null) {
      // Filter issues by selected date range
      final filteredForExport = reportsProvider.issues.where((issue) {
        return issue.date
                .isAfter(range.start.subtract(const Duration(days: 1))) &&
            issue.date.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();

      if (exportType == 'pdf') {
        await ExportService.exportToPdf(filteredForExport, user);
      } else {
        await ExportService.exportToCsv(filteredForExport);
      }
    }
  }

  // Show date range picker for filtering table data
  Future<void> _showDateRangeFilter() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A24),
              onSurface: Colors.white,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: child!,
            ),
          ),
        );
      },
    );

    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
    }
  }

  // Build date range filter button widget
  Widget _buildDateRangeFilterButton() {
    final hasDateFilter = _fromDate != null && _toDate != null;
    return InkWell(
      onTap: _showDateRangeFilter,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, color: Colors.grey.shade500, size: 16),
            const SizedBox(width: 8),
            Text(
              hasDateFilter
                  ? '${DateFormat('dd/MM/yy').format(_fromDate!)} - ${DateFormat('dd/MM/yy').format(_toDate!)}'
                  : 'Date Range',
              style: TextStyle(
                  color: hasDateFilter ? Colors.white : Colors.grey.shade500,
                  fontSize: 14),
            ),
            if (hasDateFilter) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _fromDate = null;
                    _toDate = null;
                  });
                },
                child: Icon(Icons.close, color: Colors.grey.shade500, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthService>(context);
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final filteredIssues = _getFilteredIssues(reportsProvider.issues);
    final totalIssues = reportsProvider.issues.length;
    final resolvedCount =
        reportsProvider.issues.where((i) => i.isIssueSorted).length;
    final pendingCount =
        reportsProvider.issues.where((i) => !i.isIssueSorted).length;

    // Get unique attendedBy values for filter
    final attendedByList = [
      'All',
      ...reportsProvider.issues.map((i) => i.attendedBy).toSet()
    ];

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
                  child: _activeSection == 'users'
                      ? _buildUserManagementContent()
                      : _activeSection == 'computers'
                          ? const ComputerListScreen()
                          : _buildReportsContent(
                              filteredIssues,
                              reportsProvider,
                              user,
                              totalIssues,
                              resolvedCount,
                              pendingCount,
                              attendedByList,
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
            child: Column(
              children: [
                Image.asset(
                  'assets/icon.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 12),
                const Text(
                  'BARCF PC Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          // Navigation Items
          _buildNavItem(Icons.dashboard_outlined, 'Dashboard',
              _activeSection == 'dashboard', () {
            setState(() => _activeSection = 'dashboard');
          }),
          _buildNavItem(Icons.computer_outlined, 'Computer List',
              _activeSection == 'computers', () {
            setState(() => _activeSection = 'computers');
          }),
          if (user.role == 'superadmin' || user.role == 'admin')
            _buildNavItem(Icons.people_outline, 'User Management',
                _activeSection == 'users', () {
              setState(() => _activeSection = 'users');
            }),
          const Spacer(),
          const Divider(color: Colors.white12),
          // User Profile
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryAccent,
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

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryAccent.withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color:
                      isActive ? AppTheme.primaryAccent : Colors.grey.shade500,
                  size: 20),
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
          Row(
            children: [
              Icon(Icons.home_outlined, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text('/', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Text(
                _activeSection == 'users'
                    ? 'User Management'
                    : _activeSection == 'computers'
                        ? 'Computer List'
                        : 'Issue Reports',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade400),
            onPressed: () {
              _loadIssues();
              _loadUsers();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent(
    List<Issue> filteredIssues,
    ReportsProvider reportsProvider,
    user,
    int totalIssues,
    int resolvedCount,
    int pendingCount,
    List<String> attendedByList,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 24),
          _buildStatsRow(totalIssues, resolvedCount, pendingCount),
          const SizedBox(height: 24),
          _buildReportListSection(
              filteredIssues, reportsProvider, user, attendedByList),
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
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text('Auto-updates in 2 min',
                style: TextStyle(color: Colors.grey.shade500)),
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
            Text(title,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                CustomPaint(
                    size: const Size(80, 30),
                    painter: _SparklinePainter(accentColor)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Last 30 days',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportListSection(List<Issue> filteredIssues,
      ReportsProvider reportsProvider, user, List<String> attendedByList) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Filters
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Report List',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const IssueFormScreen()))
                            .then((_) => _loadIssues());
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Issue'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filters Row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Status Filter
                    _buildFilterDropdown(
                        'Status', ['All', 'Resolved', 'Pending'], _statusFilter,
                        (val) {
                      setState(() => _statusFilter = val!);
                    }),
                    // Attended By Filter
                    _buildFilterDropdown(
                        'Attended By', attendedByList, _attendedByFilter,
                        (val) {
                      setState(() => _attendedByFilter = val!);
                    }),
                    // Date Range Filter
                    _buildDateRangeFilterButton(),
                    // Clear Filters
                    if (_statusFilter != 'All' ||
                        _attendedByFilter != 'All' ||
                        _fromDate != null ||
                        _toDate != null ||
                        _searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear Filters'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade400),
                      ),
                    // Search
                    SizedBox(
                      width: 200,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
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
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1))),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    // Export Buttons
                    _buildOutlinedButton(
                        Icons.picture_as_pdf_outlined, 'Export PDF', () async {
                      await _showExportWithDateRange('pdf', user);
                    }),
                    _buildOutlinedButton(
                        Icons.table_chart_outlined, 'Export Excel', () async {
                      await _showExportWithDateRange('excel', user);
                    }),
                  ],
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
      height: 40,
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
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade400,
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
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
          if (_statusFilter != 'All' ||
              _attendedByFilter != 'All' ||
              _fromDate != null ||
              _toDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                  onPressed: _clearFilters, child: const Text('Clear Filters')),
            ),
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
      showCheckboxColumn: false,
      headingTextStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w600,
          fontSize: 13),
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
                  DataCell(
                      Text(issue.sno?.toString() ?? '-',
                          style: const TextStyle(color: Colors.white)),
                      onTap: () => _navigateToDetail(issue)),
                  DataCell(
                      Text(issue.name,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () => _navigateToDetail(issue)),
                  DataCell(
                      Text(issue.empNo,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () => _navigateToDetail(issue)),
                  DataCell(
                      Tooltip(
                          message: issue.problem,
                          child: Text(issue.problem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white))),
                      onTap: () => _navigateToDetail(issue)),
                  DataCell(
                      Text(DateFormat('dd/MM/yyyy').format(issue.date),
                          style: TextStyle(color: Colors.grey.shade400)),
                      onTap: () => _navigateToDetail(issue)),
                  DataCell(
                      Text(issue.attendedBy,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () => _navigateToDetail(issue)),
                  DataCell(_buildStatusBadge(issue.isIssueSorted),
                      onTap: () => _navigateToDetail(issue)),
                  DataCell(_buildActionMenu(issue, reportsProvider, user)),
                ],
              ))
          .toList(),
    );
  }

  void _navigateToDetail(Issue issue) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)));
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
        if (value == 'view') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => IssueDetailScreen(issue: issue)));
        } else if (value == 'edit') {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => IssueFormScreen(issue: issue)))
              .then((_) => _loadIssues());
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
                    child: const Text('Delete')),
              ],
            ),
          );
          if (confirm == true)
            await reportsProvider.deleteIssue(issue.id!, user.id!);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'view',
            child: Row(children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 8),
              Text('View Details')
            ])),
        const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Edit')
            ])),
        const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.redAccent))
            ])),
      ],
    );
  }

  // User Management Content (Inline)
  Widget _buildUserManagementContent() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.people,
                        color: AppTheme.primaryAccent, size: 32),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Management',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Manage users and their roles',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showAddUserDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add User'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Users Table
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: userProvider.isLoading
                    ? const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()))
                    : userProvider.users.isEmpty
                        ? SizedBox(
                            height: 300,
                            child: Center(
                                child: Text('No users found',
                                    style: TextStyle(
                                        color: Colors.grey.shade500))))
                        : SizedBox(
                            height: 500,
                            child: DataTable2(
                              headingRowHeight: 52,
                              dataRowHeight: 56,
                              columnSpacing: 16,
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn2(
                                    label: Text('ID'), size: ColumnSize.S),
                                DataColumn2(
                                    label: Text('Username'),
                                    size: ColumnSize.L),
                                DataColumn2(
                                    label: Text('Role'), size: ColumnSize.M),
                                DataColumn2(
                                    label: Text('Actions'),
                                    size: ColumnSize.S,
                                    numeric: true),
                              ],
                              rows: userProvider.users.map((u) {
                                final currentUser = Provider.of<AuthService>(
                                        context,
                                        listen: false)
                                    .currentUser;
                                // Superadmin can reset all, admin can reset users only
                                final canResetPassword =
                                    currentUser?.role == 'superadmin' ||
                                        (currentUser?.role == 'admin' &&
                                            u.role == 'user');
                                // Cannot delete the default superadmin account
                                final canDelete = u.username != 'superadmin';

                                return DataRow(cells: [
                                  DataCell(Text(u.id.toString(),
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(u.username,
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(_buildRoleBadge(u.role)),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (canResetPassword)
                                        IconButton(
                                          icon: const Icon(Icons.lock_reset,
                                              color: Colors.blueAccent),
                                          onPressed: () =>
                                              _showResetPasswordDialog(u.id!,
                                                  u.username, userProvider),
                                          tooltip: 'Reset password',
                                        ),
                                      if (canDelete)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent),
                                          onPressed: () => _confirmDeleteUser(
                                              u.id!, u.username, userProvider),
                                          tooltip: 'Delete user',
                                        ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    if (role == 'superadmin') {
      color = Colors.purple;
    } else if (role == 'admin') {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(role.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'user';
    final currentUserRole =
        Provider.of<AuthService>(context, listen: false).currentUser?.role;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add User'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    )),
                const SizedBox(height: 16),
                TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
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
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => role = val);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                // Validation
                if (usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Username is required'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password is required'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }

                final success =
                    await Provider.of<UserProvider>(context, listen: false)
                        .addUser(
                  usernameController.text.trim(),
                  passwordController.text,
                  role,
                  Provider.of<AuthService>(context, listen: false)
                      .currentUser!
                      .id!,
                );
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'User added successfully'
                          : 'Failed to add user'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
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
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) await userProvider.deleteUser(userId);
  }

  // Show reset password dialog
  void _showResetPasswordDialog(
      int userId, String username, UserProvider userProvider) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for "$username"'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  hintText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  hintText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password cannot be empty')),
                );
                return;
              }
              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              final success = await userProvider.resetPassword(
                  userId, passwordController.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Password reset successfully'
                        : 'Failed to reset password'),
                  ),
                );
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }
}

// Sparkline painter
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
