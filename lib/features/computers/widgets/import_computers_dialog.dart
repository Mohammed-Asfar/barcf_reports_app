import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import '../models/computer_model.dart';
import '../providers/computers_provider.dart';
import '../../../core/auth/auth_service.dart';

class ImportComputersDialog extends StatefulWidget {
  const ImportComputersDialog({super.key});

  @override
  State<ImportComputersDialog> createState() => _ImportComputersDialogState();
}

class _ImportComputersDialogState extends State<ImportComputersDialog> {
  List<List<dynamic>> _fileData = [];
  List<String> _detectedColumns = [];
  Map<String, String?> _columnMapping = {};
  bool _isLoading = false;
  String? _fileName;
  bool _hasHeaders = true;
  int _step = 1;

  final List<Map<String, String>> _databaseFields = [
    {'key': 'name', 'label': 'Name *', 'required': 'true'},
    {'key': 'empNo', 'label': 'Emp No', 'required': 'false'},
    {'key': 'designation', 'label': 'Designation', 'required': 'false'},
    {'key': 'section', 'label': 'Section', 'required': 'false'},
    {'key': 'roomNo', 'label': 'Room No', 'required': 'false'},
    {'key': 'processor', 'label': 'Processor', 'required': 'false'},
    {'key': 'ram', 'label': 'RAM', 'required': 'false'},
    {'key': 'storage', 'label': 'HDD/SSD', 'required': 'false'},
    {'key': 'graphicsCard', 'label': 'Graphics Card', 'required': 'false'},
    {'key': 'monitorSize', 'label': 'Monitor Size', 'required': 'false'},
    {'key': 'monitorBrand', 'label': 'Monitor Brand', 'required': 'false'},
    {'key': 'amcCode', 'label': 'AMC Code', 'required': 'false'},
    {'key': 'purpose', 'label': 'Purpose', 'required': 'false'},
    {'key': 'ipAddress', 'label': 'IP Address', 'required': 'false'},
    {'key': 'macAddress', 'label': 'MAC Address', 'required': 'false'},
    {'key': 'printer', 'label': 'Printer', 'required': 'false'},
    {'key': 'connectionType', 'label': 'INTRA/INTERNET', 'required': 'false'},
    {'key': 'adminUser', 'label': 'Admin/User', 'required': 'false'},
    {
      'key': 'printerCartridge',
      'label': 'Printer Cartridge',
      'required': 'false'
    },
    {'key': 'k7', 'label': 'K7', 'required': 'false'},
    {'key': 'pcSerialNo', 'label': 'PC S.No', 'required': 'false'},
    {'key': 'monitorSerialNo', 'label': 'Monitor S.No', 'required': 'false'},
    {'key': 'pcBrand', 'label': 'PC Brand', 'required': 'false'},
  ];

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        _fileName = result.files.single.name;

        if (_fileName!.endsWith('.csv')) {
          await _parseCSV(file);
        } else {
          await _parseExcel(file);
        }

        if (_fileData.isNotEmpty) {
          _detectColumns();
          _autoMapColumns();
          setState(() => _step = 2);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _parseExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) throw Exception('No sheets found');
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet != null && sheet.rows.isNotEmpty) {
      _fileData = sheet.rows
          .map((row) =>
              row.map((cell) => cell?.value?.toString() ?? '').toList())
          .toList();
    }
  }

  Future<void> _parseCSV(File file) async {
    String content;
    try {
      content = await file.readAsString();
    } catch (e) {
      final bytes = await file.readAsBytes();
      content = String.fromCharCodes(bytes);
    }
    _fileData = const CsvToListConverter().convert(content);
  }

  void _detectColumns() {
    if (_fileData.isNotEmpty) {
      _detectedColumns = _fileData.first.map((e) => e.toString()).toList();
    }
  }

  void _autoMapColumns() {
    _columnMapping = {};
    for (var field in _databaseFields) {
      _columnMapping[field['key']!] = null;
    }

    for (int i = 0; i < _detectedColumns.length; i++) {
      final col = _detectedColumns[i].toLowerCase().trim();

      if (col == 'name' ||
          col == 'employee name' ||
          col.contains('emp') && col.contains('name'))
        _columnMapping['name'] = _detectedColumns[i];
      else if (col == 'emp no' || col == 'empno' || col == 'employee no')
        _columnMapping['empNo'] = _detectedColumns[i];
      else if (col.contains('designation'))
        _columnMapping['designation'] = _detectedColumns[i];
      else if (col.contains('section'))
        _columnMapping['section'] = _detectedColumns[i];
      else if (col.contains('room'))
        _columnMapping['roomNo'] = _detectedColumns[i];
      else if (col.contains('processor'))
        _columnMapping['processor'] = _detectedColumns[i];
      else if (col == 'ram')
        _columnMapping['ram'] = _detectedColumns[i];
      else if (col.contains('hdd') ||
          col.contains('ssd') ||
          col.contains('storage'))
        _columnMapping['storage'] = _detectedColumns[i];
      else if (col.contains('graphics'))
        _columnMapping['graphicsCard'] = _detectedColumns[i];
      else if (col.contains('monitor') &&
          !col.contains('brand') &&
          !col.contains('s.no') &&
          !col.contains('serial'))
        _columnMapping['monitorSize'] = _detectedColumns[i];
      else if (col.contains('moniter brand') || col.contains('monitor brand'))
        _columnMapping['monitorBrand'] = _detectedColumns[i];
      else if (col.contains('amc'))
        _columnMapping['amcCode'] = _detectedColumns[i];
      else if (col.contains('purpose'))
        _columnMapping['purpose'] = _detectedColumns[i];
      else if (col == 'ip' || col.contains('ip address'))
        _columnMapping['ipAddress'] = _detectedColumns[i];
      else if (col.contains('mac'))
        _columnMapping['macAddress'] = _detectedColumns[i];
      else if (col == 'printer' && !col.contains('cartridge'))
        _columnMapping['printer'] = _detectedColumns[i];
      else if (col.contains('intra') || col.contains('internet'))
        _columnMapping['connectionType'] = _detectedColumns[i];
      else if (col.contains('admin') || col.contains('user'))
        _columnMapping['adminUser'] = _detectedColumns[i];
      else if (col.contains('cartridge'))
        _columnMapping['printerCartridge'] = _detectedColumns[i];
      else if (col == 'k7')
        _columnMapping['k7'] = _detectedColumns[i];
      else if (col.contains('pc s.no') || col.contains('pc serial'))
        _columnMapping['pcSerialNo'] = _detectedColumns[i];
      else if (col.contains('moniter s.no') ||
          col.contains('monitor s.no') ||
          col.contains('monitor serial'))
        _columnMapping['monitorSerialNo'] = _detectedColumns[i];
      else if (col.contains('pc brand'))
        _columnMapping['pcBrand'] = _detectedColumns[i];
    }
  }

  Future<void> _importData() async {
    if (_columnMapping['name'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name mapping is required'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthService>(context, listen: false);
      final computersProvider =
          Provider.of<ComputersProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final startIndex = _hasHeaders ? 1 : 0;
      int successCount = 0, errorCount = 0;

      for (int i = startIndex; i < _fileData.length; i++) {
        final row = _fileData[i];
        try {
          String? getValue(String key) {
            final col = _columnMapping[key];
            if (col != null) {
              final idx = _detectedColumns.indexOf(col);
              if (idx >= 0 && idx < row.length) {
                final val = row[idx]?.toString().trim();
                return (val?.isEmpty ?? true) ? null : val;
              }
            }
            return null;
          }

          final name = getValue('name');
          if (name == null || name.isEmpty) {
            errorCount++;
            continue;
          }

          final computer = Computer(
            name: name,
            empNo: getValue('empNo'),
            designation: getValue('designation'),
            section: getValue('section'),
            roomNo: getValue('roomNo'),
            processor: getValue('processor'),
            ram: getValue('ram'),
            storage: getValue('storage'),
            graphicsCard: getValue('graphicsCard'),
            monitorSize: getValue('monitorSize'),
            monitorBrand: getValue('monitorBrand'),
            amcCode: getValue('amcCode'),
            purpose: getValue('purpose'),
            ipAddress: getValue('ipAddress'),
            macAddress: getValue('macAddress'),
            printer: getValue('printer'),
            connectionType: getValue('connectionType'),
            adminUser: getValue('adminUser'),
            printerCartridge: getValue('printerCartridge'),
            k7: getValue('k7'),
            pcSerialNo: getValue('pcSerialNo'),
            monitorSerialNo: getValue('monitorSerialNo'),
            pcBrand: getValue('pcBrand'),
            status: 'Active',
            createdByUserId: user.id!,
          );
          await computersProvider.addComputer(computer);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      await computersProvider.fetchComputers(user.id, role: user.role);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Imported: $successCount, Skipped: $errorCount'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.upload_file,
                  color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(width: 12),
              Text('Import Computers',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 16),
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStepContent()),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(children: [
      _stepCircle(1, 'Select File'),
      _stepLine(1),
      _stepCircle(2, 'Map Columns'),
      _stepLine(2),
      _stepCircle(3, 'Import'),
    ]);
  }

  Widget _stepCircle(int step, String label) {
    final isActive = _step >= step;
    return Expanded(
        child: Column(children: [
      Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade700),
          child: Center(
              child: isActive && _step > step
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text('$step',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: isActive ? Colors.white : Colors.grey)),
    ]));
  }

  Widget _stepLine(int after) {
    return Expanded(
        child: Container(
            height: 2,
            color: _step > after
                ? Theme.of(context).primaryColor
                : Colors.grey.shade700,
            margin: const EdgeInsets.only(bottom: 24)));
  }

  Widget _buildStepContent() {
    if (_step == 1) return _buildFileSelection();
    if (_step == 2) return _buildColumnMapping();
    return _buildPreview();
  }

  Widget _buildFileSelection() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey.shade500),
      const SizedBox(height: 16),
      const Text('Select Excel (.xlsx) or CSV file'),
      const SizedBox(height: 24),
      ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open, color: Colors.white),
          label: const Text('Browse Files')),
    ]));
  }

  Widget _buildColumnMapping() {
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(Icons.description, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_fileName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_fileData.length} rows',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
                const Spacer(),
                const Text('First row is header'),
                Switch(
                    value: _hasHeaders,
                    onChanged: (v) => setState(() => _hasHeaders = v)),
              ]))),
      const SizedBox(height: 16),
      const Text('Map columns:', style: TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      ..._databaseFields.map((f) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 150, child: Text(f['label']!)),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
                child: DropdownButtonFormField<String>(
              value: _columnMapping[f['key']],
              decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  hintText: 'Select'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('— Not mapped —')),
                ..._detectedColumns
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              ],
              onChanged: (v) => setState(() => _columnMapping[f['key']!] = v),
            )),
          ]))),
    ]));
  }

  Widget _buildPreview() {
    final total = _hasHeaders ? _fileData.length - 1 : _fileData.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Preview ($total records):',
          style: TextStyle(color: Colors.grey.shade400)),
      const SizedBox(height: 12),
      Expanded(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                  child: DataTable(
                columns: _databaseFields
                    .where((f) => _columnMapping[f['key']] != null)
                    .map((f) => DataColumn(label: Text(f['label']!)))
                    .toList(),
                rows: (_hasHeaders ? _fileData.skip(1) : _fileData)
                    .take(5)
                    .map((row) => DataRow(
                          cells: _databaseFields
                              .where((f) => _columnMapping[f['key']] != null)
                              .map((f) {
                            final col = _columnMapping[f['key']];
                            final idx = col != null
                                ? _detectedColumns.indexOf(col)
                                : -1;
                            return DataCell(Text(idx >= 0 && idx < row.length
                                ? row[idx]?.toString() ?? ''
                                : ''));
                          }).toList(),
                        ))
                    .toList(),
              )))),
      const SizedBox(height: 12),
      Card(
          color: Colors.blue.shade900.withOpacity(0.3),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Text('Ready to import $total computers',
                    style: const TextStyle(color: Colors.blue)),
              ]))),
    ]);
  }

  Widget _buildFooter() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (_step > 1)
        SizedBox(
          height: 44,
          child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Back')),
        ),
      const SizedBox(width: 12),
      if (_step == 2)
        SizedBox(
          height: 44,
          child: ElevatedButton(
              onPressed: _columnMapping['name'] != null
                  ? () => setState(() => _step = 3)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Next')),
        ),
      if (_step == 3)
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
              onPressed: _importData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              icon: const Icon(Icons.upload),
              label: const Text('Import')),
        ),
    ]);
  }
}
