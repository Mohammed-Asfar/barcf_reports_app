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

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
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
          title: Text(widget.issue == null ? 'New Issue' : 'Edit Issue')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _snoController,
                decoration: const InputDecoration(labelText: 'S.No'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _empNoController,
                decoration: const InputDecoration(labelText: 'Emp No'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _problemController,
                decoration: const InputDecoration(labelText: 'Problem'),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Issue Sorted?'),
                value: _isIssueSorted,
                onChanged: (val) => setState(() => _isIssueSorted = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materialsController,
                decoration:
                    const InputDecoration(labelText: 'Materials Replaced'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _attendedByController,
                decoration: const InputDecoration(labelText: 'Attended By'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saveCategory,
                child: Text(
                    widget.issue == null ? 'Create Issue' : 'Update Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
