import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_service.dart';
import '../models/issue_model.dart';
import '../providers/reports_provider.dart';
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
  late TextEditingController _problemController;
  late TextEditingController _materialsController;
  late TextEditingController _attendedByController;
  late TextEditingController _snoController;

  bool _isIssueSorted = false;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _snoController =
        TextEditingController(text: widget.issue?.sno?.toString() ?? '');
    _nameController = TextEditingController(text: widget.issue?.name ?? '');
    _empNoController = TextEditingController(text: widget.issue?.empNo ?? '');
    _problemController =
        TextEditingController(text: widget.issue?.problem ?? '');
    _materialsController =
        TextEditingController(text: widget.issue?.materialsReplaced ?? '');
    _attendedByController =
        TextEditingController(text: widget.issue?.attendedBy ?? '');
    _isIssueSorted = widget.issue?.isIssueSorted ?? false;
    _selectedDate = widget.issue?.date ?? DateTime.now();
  }

  Future<void> _saveIssue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) return;

      final issue = Issue(
        id: widget.issue?.id,
        sno: int.tryParse(_snoController.text),
        name: _nameController.text,
        empNo: _empNoController.text,
        problem: _problemController.text,
        isIssueSorted: _isIssueSorted,
        materialsReplaced: _materialsController.text,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issue == null ? 'New Issue' : 'Edit Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  const Text(
                    'Issue Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the information below to ${widget.issue == null ? 'create a new' : 'update the'} issue.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  _buildLabel('S.No (Optional)'),
                  TextFormField(
                    controller: _snoController,
                    decoration:
                        const InputDecoration(hintText: 'Enter serial number'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Name *'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Enter name'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Employee No *'),
                  TextFormField(
                    controller: _empNoController,
                    decoration: const InputDecoration(
                        hintText: 'Enter employee number'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Problem *'),
                  TextFormField(
                    controller: _problemController,
                    decoration:
                        const InputDecoration(hintText: 'Describe the problem'),
                    maxLines: 3,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Materials Replaced'),
                  TextFormField(
                    controller: _materialsController,
                    decoration: const InputDecoration(
                        hintText: 'List materials replaced (if any)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Attended By *'),
                  TextFormField(
                    controller: _attendedByController,
                    decoration: const InputDecoration(
                        hintText: 'Enter name of attendee'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Date'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242432),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242432),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Issue Resolved',
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        _isIssueSorted
                            ? 'This issue has been sorted'
                            : 'This issue is still pending',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                      value: _isIssueSorted,
                      onChanged: (val) => setState(() => _isIssueSorted = val),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveIssue,
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.issue == null
                                  ? 'Create Issue'
                                  : 'Update Issue',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
