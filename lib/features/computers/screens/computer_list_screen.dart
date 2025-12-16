import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/computer_model.dart';
import '../providers/computers_provider.dart';
import '../../../core/auth/auth_service.dart';
import 'computer_form_screen.dart';
import 'computer_detail_screen.dart';
import '../widgets/import_computers_dialog.dart';

class ComputerListScreen extends StatefulWidget {
  const ComputerListScreen({super.key});

  @override
  State<ComputerListScreen> createState() => _ComputerListScreenState();
}

class _ComputerListScreenState extends State<ComputerListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sectionFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComputers();
    });
  }

  Future<void> _loadComputers() async {
    final authProvider = Provider.of<AuthService>(context, listen: false);
    final computersProvider =
        Provider.of<ComputersProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      await computersProvider.fetchComputers(user.id, role: user.role);
    }
  }

  List<Computer> _getFilteredComputers(List<Computer> computers) {
    return computers.where((computer) {
      final matchesSearch = _searchQuery.isEmpty ||
          computer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (computer.ipAddress
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          (computer.empNo?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (computer.pcSerialNo
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          (computer.section
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesStatus =
          _statusFilter == 'All' || computer.status == _statusFilter;
      final matchesSection =
          _sectionFilter == 'All' || computer.section == _sectionFilter;

      return matchesSearch && matchesStatus && matchesSection;
    }).toList();
  }

  Future<void> _exportToPDF(List<Computer> computers) async {
    if (computers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No data to export'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Header(
                level: 0,
                child: pw.Text('Computer List Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 10),
            pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: [
                'S.No',
                'Name',
                'Emp No',
                'Section',
                'Room',
                'Purpose',
                'IP',
                'Processor',
                'RAM',
                'PC Brand',
                'Status'
              ],
              data: computers.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return [
                  '${c.sno ?? i + 1}',
                  c.name,
                  c.empNo ?? '-',
                  c.section ?? '-',
                  c.roomNo ?? '-',
                  c.purpose ?? '-',
                  c.ipAddress ?? '-',
                  c.processor ?? '-',
                  c.ram ?? '-',
                  c.pcBrand ?? '-',
                  c.status
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.center,
                10: pw.Alignment.center,
              },
            ),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportToCSV(List<Computer> computers) async {
    final csvData = [
      [
        'S.No',
        'Name',
        'Emp No',
        'Designation',
        'Section',
        'Room No',
        'Processor',
        'RAM',
        'Storage',
        'Graphics Card',
        'Monitor Size',
        'Monitor Brand',
        'AMC Code',
        'Purpose',
        'IP',
        'MAC Address',
        'Printer',
        'Connection',
        'Admin/User',
        'Printer Cartridge',
        'K7',
        'PC S.No',
        'Monitor S.No',
        'PC Brand',
        'Status'
      ],
      ...computers.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        return [
          '${i + 1}',
          c.name,
          c.empNo ?? '',
          c.designation ?? '',
          c.section ?? '',
          c.roomNo ?? '',
          c.processor ?? '',
          c.ram ?? '',
          c.storage ?? '',
          c.graphicsCard ?? '',
          c.monitorSize ?? '',
          c.monitorBrand ?? '',
          c.amcCode ?? '',
          c.purpose ?? '',
          c.ipAddress ?? '',
          c.macAddress ?? '',
          c.printer ?? '',
          c.connectionType ?? '',
          c.adminUser ?? '',
          c.printerCartridge ?? '',
          c.k7 ?? '',
          c.pcSerialNo ?? '',
          c.monitorSerialNo ?? '',
          c.pcBrand ?? '',
          c.status
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file =
        File('${directory.path}/BARCF_Reports/computers_export_$timestamp.csv');
    await file.parent.create(recursive: true);
    await file.writeAsString(csv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported to: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () => Process.run('explorer', [file.parent.path])),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthService>(context);
    final computersProvider = Provider.of<ComputersProvider>(context);
    final user = authProvider.currentUser;
    final isAdmin = user?.role == 'superadmin' || user?.role == 'admin';

    final filteredComputers =
        _getFilteredComputers(computersProvider.computers);
    final statusOptions = ['All', ...computersProvider.uniqueStatuses];
    final sectionOptions = ['All', ...computersProvider.uniqueSections];

    final totalComputers = computersProvider.computers.length;
    final activeCount =
        computersProvider.computers.where((c) => c.status == 'Active').length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(theme, isAdmin),
            const SizedBox(height: 20),
            _buildStatsRow(theme, totalComputers, activeCount),
            const SizedBox(height: 20),
            _buildFiltersRow(
                theme, statusOptions, sectionOptions, filteredComputers),
            const SizedBox(height: 20),
            Expanded(
              child: computersProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredComputers.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildDataTable(
                          theme, filteredComputers, computersProvider, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(ThemeData theme, bool isAdmin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Computer Inventory',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Manage and track all computers',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.textTheme.bodySmall?.color)),
        ]),
        if (isAdmin)
          Row(children: [
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const ImportComputersDialog())
                    .then((_) => _loadComputers()),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ComputerFormScreen()));
                  if (result == true) _loadComputers();
                },
                icon: const Icon(
                  Icons.add,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text('Add Computer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ),
          ]),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, int total, int active) {
    return Row(children: [
      _buildStatCard(theme, 'Total', total.toString(), theme.primaryColor),
      const SizedBox(width: 16),
      _buildStatCard(theme, 'Active', active.toString(), Colors.green),
      const SizedBox(width: 16),
      _buildStatCard(
          theme, 'Inactive', (total - active).toString(), Colors.orange),
    ]);
  }

  Widget _buildStatCard(
      ThemeData theme, String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

  Widget _buildFiltersRow(ThemeData theme, List<String> statusOptions,
      List<String> sectionOptions, List<Computer> filteredComputers) {
    return Row(children: [
      // Search field
      Expanded(
        flex: 2,
        child: Container(
          height: 40,
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon:
                  Icon(Icons.search, color: Colors.grey.shade500, size: 20),
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: const Color(0xFF0F0F14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Status Filter
      _buildFilterDropdown(statusOptions, _statusFilter, (v) {
        if (v != null) setState(() => _statusFilter = v);
      }),
      const SizedBox(width: 12),
      // Section Filter
      if (sectionOptions.length > 1)
        _buildFilterDropdown(sectionOptions, _sectionFilter, (v) {
          if (v != null) setState(() => _sectionFilter = v);
        }),
      const Spacer(),
      // Export buttons
      _buildExportButton(Icons.picture_as_pdf_outlined, 'PDF',
          () => _exportToPDF(filteredComputers)),
      const SizedBox(width: 8),
      _buildExportButton(Icons.table_chart_outlined, 'CSV',
          () => _exportToCSV(filteredComputers)),
    ]);
  }

  Widget _buildFilterDropdown(
      List<String> items, String value, ValueChanged<String?> onChanged) {
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

  Widget _buildExportButton(
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.computer, size: 64, color: theme.disabledColor),
      const SizedBox(height: 16),
      Text('No computers found', style: theme.textTheme.titleLarge),
    ]));
  }

  Widget _buildDataTable(ThemeData theme, List<Computer> computers,
      ComputersProvider provider, dynamic user) {
    final isAdmin = user?.role == 'superadmin' || user?.role == 'admin';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PaginatedDataTable2(
          columnSpacing: 16,
          horizontalMargin: 16,
          minWidth: 1400,
          headingRowHeight: 50,
          dataRowHeight: 52,
          rowsPerPage: 25,
          showCheckboxColumn: false, // Remove checkbox column
          availableRowsPerPage: const [10, 25, 50, 100],
          showFirstLastButtons: true,
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1A24)),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.white70,
          ),
          columns: const [
            DataColumn2(label: Text('S.No'), fixedWidth: 60),
            DataColumn2(label: Text('Name'), size: ColumnSize.L),
            DataColumn2(label: Text('Emp No'), fixedWidth: 90),
            DataColumn2(label: Text('Section'), fixedWidth: 100),
            DataColumn2(label: Text('Room'), fixedWidth: 70),
            DataColumn2(label: Text('IP Address'), fixedWidth: 120),
            DataColumn2(label: Text('Processor'), fixedWidth: 90),
            DataColumn2(label: Text('PC Brand'), fixedWidth: 100),
            DataColumn2(label: Text('Status'), fixedWidth: 90),
            DataColumn2(label: Text('Actions'), fixedWidth: 80),
          ],
          source: _ComputerDataSource(
            computers: computers,
            theme: theme,
            isAdmin: isAdmin,
            provider: provider,
            user: user,
            onView: (computer) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ComputerDetailScreen(
                          computer: computer,
                          isAdmin: isAdmin,
                        )),
              );
              if (result == 'edit') {
                final editResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ComputerFormScreen(computer: computer)),
                );
                if (editResult == true) _loadComputers();
              } else if (result == 'delete') {
                _confirmDelete(computer, provider, user);
              }
            },
            onEdit: (computer) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ComputerFormScreen(computer: computer)),
              );
              if (result == true) _loadComputers();
            },
            onDelete: (computer) => _confirmDelete(computer, provider, user),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      Computer computer, ComputersProvider provider, dynamic user) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete Computer'),
              content: Text('Delete "${computer.name}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await provider.deleteComputer(computer.id!, user.id!);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ));
  }
}

// Efficient DataSource for large datasets
class _ComputerDataSource extends DataTableSource {
  final List<Computer> computers;
  final ThemeData theme;
  final bool isAdmin;
  final ComputersProvider provider;
  final dynamic user;
  final Function(Computer) onView;
  final Function(Computer) onEdit;
  final Function(Computer) onDelete;

  _ComputerDataSource({
    required this.computers,
    required this.theme,
    required this.isAdmin,
    required this.provider,
    required this.user,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= computers.length) return null;
    final c = computers[index];

    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) => onView(c), // Row tap navigates to detail
      cells: [
        DataCell(Text('${index + 1}', // Auto-generated S.No (not from db)
            style: TextStyle(color: Colors.grey.shade400))),
        DataCell(
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.computer,
                size: 18,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ]),
        ),
        DataCell(Text(c.empNo ?? '-')),
        DataCell(Text(c.section ?? '-')),
        DataCell(Text(c.roomNo ?? '-')),
        DataCell(Text(c.ipAddress ?? '-',
            style: TextStyle(
                color: Colors.blue.shade300,
                fontFamily: 'monospace',
                fontSize: 12))),
        DataCell(
            Text(c.processor ?? '-', style: const TextStyle(fontSize: 12))),
        DataCell(Text(c.pcBrand ?? '-')),
        DataCell(_buildStatusBadge(c.status)),
        DataCell(_buildActions(c)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Active' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildActions(Computer c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIcon(
          Icons.edit_outlined,
          isAdmin ? Colors.orange : Colors.grey,
          isAdmin ? () => onEdit(c) : null,
        ),
        const SizedBox(width: 4),
        _actionIcon(
          Icons.delete_outline,
          isAdmin ? Colors.red : Colors.grey,
          isAdmin ? () => onDelete(c) : null,
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback? onPressed) {
    final isDisabled = onPressed == null;
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          foregroundColor: isDisabled
              ? Colors.grey.shade600
              : (color is MaterialColor ? color.shade300 : color),
          backgroundColor: color.withOpacity(isDisabled ? 0.05 : 0.15),
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => computers.length;

  @override
  int get selectedRowCount => 0;
}
