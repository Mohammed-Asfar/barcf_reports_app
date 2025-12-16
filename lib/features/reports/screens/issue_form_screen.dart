import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_service.dart';
import '../models/issue_model.dart';
import '../providers/reports_provider.dart';
import '../../computers/providers/computers_provider.dart';
import '../../computers/models/computer_model.dart';
import 'package:intl/intl.dart';

class IssueFormScreen extends StatefulWidget {
  final Issue? issue;

  const IssueFormScreen({super.key, this.issue});

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _empNoController;
  late TextEditingController _purposeController;
  late TextEditingController _problemController;
  late TextEditingController _materialsController;
  late TextEditingController _attendedByController;

  bool _isIssueSorted = false;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  List<Computer> _computers = [];

  // Keys to rebuild autocomplete when value changes externally
  Key _nameAutocompleteKey = UniqueKey();
  Key _empNoAutocompleteKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.issue?.name ?? '');
    _empNoController = TextEditingController(text: widget.issue?.empNo ?? '');
    _purposeController =
        TextEditingController(text: widget.issue?.purpose ?? '');
    _problemController =
        TextEditingController(text: widget.issue?.problem ?? '');
    _materialsController =
        TextEditingController(text: widget.issue?.materialsReplaced ?? '');
    _attendedByController =
        TextEditingController(text: widget.issue?.attendedBy ?? '');
    _isIssueSorted = widget.issue?.isIssueSorted ?? false;
    _selectedDate = widget.issue?.date ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadComputers());
  }

  Future<void> _loadComputers() async {
    final authProvider = Provider.of<AuthService>(context, listen: false);
    final computersProvider =
        Provider.of<ComputersProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      await computersProvider.fetchComputers(user.id, role: user.role);
      setState(() => _computers = computersProvider.computers);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _empNoController.dispose();
    _purposeController.dispose();
    _problemController.dispose();
    _materialsController.dispose();
    _attendedByController.dispose();
    super.dispose();
  }

  Future<void> _saveIssue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) return;

      final issue = Issue(
        id: widget.issue?.id,
        sno: widget.issue?.sno,
        name: _nameController.text,
        empNo: _empNoController.text,
        purpose: _purposeController.text,
        problem: _problemController.text,
        isIssueSorted: _isIssueSorted,
        materialsReplaced: _materialsController.text.isNotEmpty
            ? _materialsController.text
            : null,
        attendedBy: _attendedByController.text,
        date: _selectedDate,
        createdByUserId: widget.issue?.createdByUserId ?? user.id!,
        updatedByUserId: widget.issue != null ? user.id : null,
        createdAt: widget.issue?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<ReportsProvider>(context, listen: false);
      if (widget.issue == null) {
        await provider.addIssue(issue);
      } else {
        await provider.updateIssue(issue);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Get unique names from computers
  List<String> get _nameOptions =>
      _computers.map((c) => c.name).where((n) => n.isNotEmpty).toSet().toList()
        ..sort();

  // Get unique emp numbers from computers
  List<String> get _empNoOptions => _computers
      .where((c) => c.empNo != null && c.empNo!.isNotEmpty)
      .map((c) => c.empNo!)
      .toSet()
      .toList()
    ..sort();

  // Auto-fill emp no and purpose when name is selected
  void _onNameSelected(String name) {
    final computer = _computers.firstWhere(
      (c) => c.name == name,
      orElse: () => Computer(name: '', status: '', createdByUserId: 0),
    );

    // Get purposes available for this employee
    final availablePurposes = _computers
        .where((c) => c.name == name)
        .where((c) => c.purpose != null && c.purpose!.isNotEmpty)
        .map((c) => c.purpose!)
        .toSet()
        .toList();

    setState(() {
      _nameController.text = name;
      if (computer.empNo != null && computer.empNo!.isNotEmpty) {
        _empNoController.text = computer.empNo!;
        _empNoAutocompleteKey = UniqueKey();
      }

      // Reset purpose if current value isn't in available purposes for this employee
      if (!availablePurposes.contains(_purposeController.text)) {
        // Auto-select if only one purpose available, otherwise clear
        _purposeController.text =
            availablePurposes.length == 1 ? availablePurposes.first : '';
      }
    });
  }

  // Auto-fill name and purpose when emp no is selected
  void _onEmpNoSelected(String empNo) {
    final computer = _computers.firstWhere(
      (c) => c.empNo == empNo,
      orElse: () => Computer(name: '', status: '', createdByUserId: 0),
    );

    // Get purposes available for this employee
    final availablePurposes = _computers
        .where((c) => c.empNo == empNo)
        .where((c) => c.purpose != null && c.purpose!.isNotEmpty)
        .map((c) => c.purpose!)
        .toSet()
        .toList();

    setState(() {
      _empNoController.text = empNo;
      if (computer.name.isNotEmpty) {
        _nameController.text = computer.name;
        _nameAutocompleteKey = UniqueKey();
      }

      // Reset purpose if current value isn't in available purposes for this employee
      if (!availablePurposes.contains(_purposeController.text)) {
        // Auto-select if only one purpose available, otherwise clear
        _purposeController.text =
            availablePurposes.length == 1 ? availablePurposes.first : '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.issue != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Issue' : 'New Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Basic Information'),
              Row(children: [
                Expanded(child: _buildNameAutocomplete()),
                const SizedBox(width: 16),
                Expanded(child: _buildEmpNoAutocomplete()),
                const SizedBox(width: 16),
                Expanded(child: _buildPurposeDropdown()),
                const SizedBox(width: 16),
                Expanded(
                    child: _textField(_attendedByController, 'Attended By *',
                        required: true)),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('Problem Details'),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    flex: 2,
                    child: _textField(_problemController, 'Problem *',
                        required: true, maxLines: 3)),
                const SizedBox(width: 16),
                Expanded(
                    child: _textField(
                        _materialsController, 'Materials Replaced',
                        maxLines: 3)),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('Status & Date'),
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF242432),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.grey.shade400, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(_selectedDate),
                                  style: const TextStyle(color: Colors.white)),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down,
                                  color: Colors.grey.shade400),
                            ]),
                          ),
                        ),
                      ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF242432),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_isIssueSorted ? 'Resolved' : 'Pending',
                                style: const TextStyle(color: Colors.white)),
                            value: _isIssueSorted,
                            onChanged: (val) =>
                                setState(() => _isIssueSorted = val),
                          ),
                        ),
                      ]),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ]),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveIssue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'Update' : 'Create Issue'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameAutocomplete() {
    return Autocomplete<String>(
      key: _nameAutocompleteKey,
      initialValue: TextEditingValue(text: _nameController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty)
          return const Iterable<String>.empty();
        return _nameOptions.where((name) =>
            name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: _onNameSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.addListener(() {
          if (_nameController.text != controller.text) {
            _nameController.text = controller.text;
          }
        });
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Name *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.person_search, size: 20),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              decoration: BoxDecoration(
                color: const Color(0xFF242432),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final computer = _computers.firstWhere(
                      (c) => c.name == option,
                      orElse: () =>
                          Computer(name: '', status: '', createdByUserId: 0));
                  return ListTile(
                    dense: true,
                    title: Text(option,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: computer.empNo != null
                        ? Text('Emp: ${computer.empNo}',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12))
                        : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpNoAutocomplete() {
    return Autocomplete<String>(
      key: _empNoAutocompleteKey,
      initialValue: TextEditingValue(text: _empNoController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty)
          return const Iterable<String>.empty();
        return _empNoOptions.where((empNo) =>
            empNo.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: _onEmpNoSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.addListener(() {
          if (_empNoController.text != controller.text) {
            _empNoController.text = controller.text;
          }
        });
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Employee No *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.badge, size: 20),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
              decoration: BoxDecoration(
                color: const Color(0xFF242432),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final computer = _computers.firstWhere(
                      (c) => c.empNo == option,
                      orElse: () =>
                          Computer(name: '', status: '', createdByUserId: 0));
                  return ListTile(
                    dense: true,
                    title: Text(option,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(computer.name,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Get purpose options for the current name/empNo
  List<String> _getPurposeOptionsForEmployee() {
    final name = _nameController.text.trim();
    final empNo = _empNoController.text.trim();

    // Find computers matching the current name or empNo
    final matchingComputers = _computers.where((c) =>
        (name.isNotEmpty && c.name == name) ||
        (empNo.isNotEmpty && c.empNo == empNo));

    // Get unique purposes from matching computers
    final purposes = matchingComputers
        .where((c) => c.purpose != null && c.purpose!.isNotEmpty)
        .map((c) => c.purpose!)
        .toSet()
        .toList();

    return purposes..sort();
  }

  Widget _buildPurposeDropdown() {
    final purposeOptions = _getPurposeOptionsForEmployee();

    // If we have options, show dropdown
    if (purposeOptions.isNotEmpty) {
      // Ensure current value is in options or reset
      if (!purposeOptions.contains(_purposeController.text) &&
          _purposeController.text.isNotEmpty) {
        // Keep the auto-filled value if it matches
      } else if (_purposeController.text.isEmpty &&
          purposeOptions.length == 1) {
        // Auto-select if only one option
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _purposeController.text.isEmpty) {
            setState(() => _purposeController.text = purposeOptions.first);
          }
        });
      }

      return DropdownButtonFormField<String>(
        value: purposeOptions.contains(_purposeController.text)
            ? _purposeController.text
            : null,
        decoration: InputDecoration(
          labelText: 'Purpose *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: purposeOptions
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _purposeController.text = value);
        },
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        dropdownColor: const Color(0xFF242432),
      );
    }

    // No employee selected yet - show regular text field
    return TextFormField(
      controller: _purposeController,
      decoration: InputDecoration(
        labelText: 'Purpose *',
        hintText: 'Select Name/Emp No first',
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label,
      {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator:
          required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }
}
