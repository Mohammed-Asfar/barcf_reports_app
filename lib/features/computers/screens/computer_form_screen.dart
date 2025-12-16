import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/computer_model.dart';
import '../providers/computers_provider.dart';
import '../../../core/auth/auth_service.dart';

class ComputerFormScreen extends StatefulWidget {
  final Computer? computer;

  const ComputerFormScreen({super.key, this.computer});

  @override
  State<ComputerFormScreen> createState() => _ComputerFormScreenState();
}

class _ComputerFormScreenState extends State<ComputerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _empNoController;
  late TextEditingController _designationController;
  late TextEditingController _sectionController;
  late TextEditingController _roomNoController;
  late TextEditingController _processorController;
  late TextEditingController _ramController;
  late TextEditingController _storageController;
  late TextEditingController _graphicsCardController;
  late TextEditingController _monitorSizeController;
  late TextEditingController _monitorBrandController;
  late TextEditingController _amcCodeController;
  late TextEditingController _purposeController;
  late TextEditingController _ipAddressController;
  late TextEditingController _macAddressController;
  late TextEditingController _printerController;
  late TextEditingController _connectionTypeController;
  late TextEditingController _adminUserController;
  late TextEditingController _printerCartridgeController;
  late TextEditingController _k7Controller;
  late TextEditingController _pcSerialNoController;
  late TextEditingController _monitorSerialNoController;
  late TextEditingController _pcBrandController;
  late TextEditingController _notesController;
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    final c = widget.computer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _empNoController = TextEditingController(text: c?.empNo ?? '');
    _designationController = TextEditingController(text: c?.designation ?? '');
    _sectionController = TextEditingController(text: c?.section ?? '');
    _roomNoController = TextEditingController(text: c?.roomNo ?? '');
    _processorController = TextEditingController(text: c?.processor ?? '');
    _ramController = TextEditingController(text: c?.ram ?? '');
    _storageController = TextEditingController(text: c?.storage ?? '');
    _graphicsCardController =
        TextEditingController(text: c?.graphicsCard ?? '');
    _monitorSizeController = TextEditingController(text: c?.monitorSize ?? '');
    _monitorBrandController =
        TextEditingController(text: c?.monitorBrand ?? '');
    _amcCodeController = TextEditingController(text: c?.amcCode ?? '');
    _purposeController = TextEditingController(text: c?.purpose ?? '');
    _ipAddressController = TextEditingController(text: c?.ipAddress ?? '');
    _macAddressController = TextEditingController(text: c?.macAddress ?? '');
    _printerController = TextEditingController(text: c?.printer ?? '');
    _connectionTypeController =
        TextEditingController(text: c?.connectionType ?? '');
    _adminUserController = TextEditingController(text: c?.adminUser ?? '');
    _printerCartridgeController =
        TextEditingController(text: c?.printerCartridge ?? '');
    _k7Controller = TextEditingController(text: c?.k7 ?? '');
    _pcSerialNoController = TextEditingController(text: c?.pcSerialNo ?? '');
    _monitorSerialNoController =
        TextEditingController(text: c?.monitorSerialNo ?? '');
    _pcBrandController = TextEditingController(text: c?.pcBrand ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
    _status = c?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _empNoController.dispose();
    _designationController.dispose();
    _sectionController.dispose();
    _roomNoController.dispose();
    _processorController.dispose();
    _ramController.dispose();
    _storageController.dispose();
    _graphicsCardController.dispose();
    _monitorSizeController.dispose();
    _monitorBrandController.dispose();
    _amcCodeController.dispose();
    _purposeController.dispose();
    _ipAddressController.dispose();
    _macAddressController.dispose();
    _printerController.dispose();
    _connectionTypeController.dispose();
    _adminUserController.dispose();
    _printerCartridgeController.dispose();
    _k7Controller.dispose();
    _pcSerialNoController.dispose();
    _monitorSerialNoController.dispose();
    _pcBrandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveComputer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthService>(context, listen: false);
      final computersProvider =
          Provider.of<ComputersProvider>(context, listen: false);
      final user = authProvider.currentUser;

      final computer = Computer(
        id: widget.computer?.id,
        name: _nameController.text.trim(),
        empNo: _empNoController.text.trim().isNotEmpty
            ? _empNoController.text.trim()
            : null,
        designation: _designationController.text.trim().isNotEmpty
            ? _designationController.text.trim()
            : null,
        section: _sectionController.text.trim().isNotEmpty
            ? _sectionController.text.trim()
            : null,
        roomNo: _roomNoController.text.trim().isNotEmpty
            ? _roomNoController.text.trim()
            : null,
        processor: _processorController.text.trim().isNotEmpty
            ? _processorController.text.trim()
            : null,
        ram: _ramController.text.trim().isNotEmpty
            ? _ramController.text.trim()
            : null,
        storage: _storageController.text.trim().isNotEmpty
            ? _storageController.text.trim()
            : null,
        graphicsCard: _graphicsCardController.text.trim().isNotEmpty
            ? _graphicsCardController.text.trim()
            : null,
        monitorSize: _monitorSizeController.text.trim().isNotEmpty
            ? _monitorSizeController.text.trim()
            : null,
        monitorBrand: _monitorBrandController.text.trim().isNotEmpty
            ? _monitorBrandController.text.trim()
            : null,
        amcCode: _amcCodeController.text.trim().isNotEmpty
            ? _amcCodeController.text.trim()
            : null,
        purpose: _purposeController.text.trim().isNotEmpty
            ? _purposeController.text.trim()
            : null,
        ipAddress: _ipAddressController.text.trim().isNotEmpty
            ? _ipAddressController.text.trim()
            : null,
        macAddress: _macAddressController.text.trim().isNotEmpty
            ? _macAddressController.text.trim()
            : null,
        printer: _printerController.text.trim().isNotEmpty
            ? _printerController.text.trim()
            : null,
        connectionType: _connectionTypeController.text.trim().isNotEmpty
            ? _connectionTypeController.text.trim()
            : null,
        adminUser: _adminUserController.text.trim().isNotEmpty
            ? _adminUserController.text.trim()
            : null,
        printerCartridge: _printerCartridgeController.text.trim().isNotEmpty
            ? _printerCartridgeController.text.trim()
            : null,
        k7: _k7Controller.text.trim().isNotEmpty
            ? _k7Controller.text.trim()
            : null,
        pcSerialNo: _pcSerialNoController.text.trim().isNotEmpty
            ? _pcSerialNoController.text.trim()
            : null,
        monitorSerialNo: _monitorSerialNoController.text.trim().isNotEmpty
            ? _monitorSerialNoController.text.trim()
            : null,
        pcBrand: _pcBrandController.text.trim().isNotEmpty
            ? _pcBrandController.text.trim()
            : null,
        status: _status,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdByUserId: widget.computer?.createdByUserId ?? user!.id!,
      );

      if (widget.computer == null) {
        await computersProvider.addComputer(computer);
      } else {
        await computersProvider.updateComputer(computer);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.computer == null
                  ? 'Computer added'
                  : 'Computer updated'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.computer != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Computer' : 'Add Computer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Employee Information'),
              Row(children: [
                Expanded(
                    child:
                        _textField(_nameController, 'Name *', required: true)),
                const SizedBox(width: 16),
                Expanded(child: _textField(_empNoController, 'Emp No')),
                const SizedBox(width: 16),
                Expanded(
                    child: _textField(_designationController, 'Designation')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _textField(_sectionController, 'Section')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_roomNoController, 'Room No')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_purposeController, 'Purpose')),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('PC Specifications'),
              Row(children: [
                Expanded(child: _textField(_processorController, 'Processor')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_ramController, 'RAM')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_storageController, 'HDD/SSD')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child:
                        _textField(_graphicsCardController, 'Graphics Card')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_pcBrandController, 'PC Brand')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_pcSerialNoController, 'PC S.No')),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('Monitor'),
              Row(children: [
                Expanded(
                    child: _textField(_monitorSizeController, 'Monitor Size')),
                const SizedBox(width: 16),
                Expanded(
                    child:
                        _textField(_monitorBrandController, 'Monitor Brand')),
                const SizedBox(width: 16),
                Expanded(
                    child:
                        _textField(_monitorSerialNoController, 'Monitor S.No')),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('Network'),
              Row(children: [
                Expanded(child: _textField(_ipAddressController, 'IP Address')),
                const SizedBox(width: 16),
                Expanded(
                    child: _textField(_macAddressController, 'MAC Address')),
                const SizedBox(width: 16),
                Expanded(
                    child: _textField(
                        _connectionTypeController, 'INTRA/INTERNET')),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('Printer & Other'),
              Row(children: [
                Expanded(child: _textField(_printerController, 'Printer')),
                const SizedBox(width: 16),
                Expanded(
                    child: _textField(
                        _printerCartridgeController, 'Printer Cartridge')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_adminUserController, 'Admin/User')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _textField(_k7Controller, 'K7')),
                const SizedBox(width: 16),
                Expanded(child: _textField(_amcCodeController, 'AMC Code')),
                const SizedBox(width: 16),
                Expanded(
                    child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8))),
                  items: ['Active', 'Inactive']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                )),
              ]),
              const SizedBox(height: 16),
              _textField(_notesController, 'Notes', maxLines: 3),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveComputer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isEditing ? 'Update' : 'Save'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor)),
    );
  }

  Widget _textField(TextEditingController controller, String label,
      {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      validator:
          required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }
}
