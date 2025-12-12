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
      // Background handled by theme
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.issue == null ? 'Create Report' : 'Edit Report',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF111827), // Darker button
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                      onPressed:
                          _saveCategory, // Should probably be "Preview" to match UI but let's just save for now
                      child: const Text('Save Report'), // Or 'Preview'
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Stepper Visual
                Row(
                  children: [
                    _StepIndicator(
                        number: '1',
                        label: 'Details',
                        subLabel: 'Enter Report details',
                        isActive: true),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    _StepIndicator(
                        number: '2',
                        label: 'Preview',
                        subLabel: 'Preview and Print',
                        isActive: false),
                  ],
                ),
                const SizedBox(height: 48),

                // Content Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Report Details Section
                        _SectionHeader(title: 'Report Details'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _ModernInput(
                                    controller: _snoController,
                                    label: 'Report Number',
                                    icon: Icons.numbers)),
                            const SizedBox(width: 24),
                            // Date Picker Mock-up Input
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                child: IgnorePointer(
                                  child: _ModernInput(
                                    controller: TextEditingController(
                                        text: DateFormat('yyyy-MM-dd')
                                            .format(_selectedDate)),
                                    label: 'Issued Date',
                                    icon: Icons.calendar_today,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Employee Details Section
                        _SectionHeader(title: 'Employee Details'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _ModernInput(
                                    controller: _nameController,
                                    label: 'Employee Name',
                                    icon: Icons.person)),
                            const SizedBox(width: 24),
                            Expanded(
                                child: _ModernInput(
                                    controller: _empNoController,
                                    label: 'Employee No.',
                                    icon: Icons.badge)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Problem Section
                        _SectionHeader(title: 'Problem Description'),
                        const SizedBox(height: 16),
                        _ModernInput(
                            controller: _problemController,
                            label: 'Problem',
                            icon: Icons.report_problem,
                            maxLines: 3),

                        const SizedBox(height: 32),

                        // Action/Status Section
                        _SectionHeader(title: 'Resolution Details'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _ModernInput(
                                    controller: _attendedByController,
                                    label: 'Attended By',
                                    icon: Icons.engineering)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Is Sorted?',
                                      style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold)),
                                  value: _isIssueSorted,
                                  activeColor:
                                      Theme.of(context).colorScheme.primary,
                                  onChanged: (val) =>
                                      setState(() => _isIssueSorted = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ModernInput(
                            controller: _materialsController,
                            label: 'Materials Replaced',
                            icon: Icons.build),

                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widgets for modern look
class _StepIndicator extends StatelessWidget {
  final String number;
  final String label;
  final String subLabel;
  final bool isActive;

  const _StepIndicator(
      {required this.number,
      required this.label,
      required this.subLabel,
      required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? Theme.of(context).colorScheme.primary : Colors.grey;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: TextStyle(
                    color: isActive ? Colors.white : color,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(subLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _ModernInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _ModernInput(
      {required this.controller,
      required this.label,
      required this.icon,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            hintText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (val) => val != null && val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
