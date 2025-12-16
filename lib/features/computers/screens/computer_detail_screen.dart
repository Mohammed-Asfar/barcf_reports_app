import 'package:flutter/material.dart';
import '../models/computer_model.dart';

class ComputerDetailScreen extends StatelessWidget {
  final Computer computer;
  final bool isAdmin;

  const ComputerDetailScreen({
    super.key,
    required this.computer,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(computer.name),
        actions: [
          // Edit button - visible but disabled for non-admins
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isAdmin ? null : Colors.grey.shade600,
            ),
            onPressed: isAdmin ? () => Navigator.pop(context, 'edit') : null,
            tooltip: isAdmin ? 'Edit' : 'Admin only',
          ),
          // Delete button - visible but disabled for non-admins
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isAdmin ? Colors.redAccent : Colors.grey.shade600,
            ),
            onPressed: isAdmin ? () => Navigator.pop(context, 'delete') : null,
            tooltip: isAdmin ? 'Delete' : 'Admin only',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          computer.name.isNotEmpty
                              ? computer.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(computer.name,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (computer.empNo != null)
                            Text('Employee No: ${computer.empNo}',
                                style: TextStyle(color: Colors.grey.shade400)),
                          if (computer.designation != null)
                            Text(computer.designation!,
                                style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(computer.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildSection('Location', [
                  _detailItem('Section', computer.section),
                  _detailItem('Room No', computer.roomNo),
                  _detailItem('Purpose', computer.purpose),
                ])),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSection('PC Specifications', [
                  _detailItem('Processor', computer.processor),
                  _detailItem('RAM', computer.ram),
                  _detailItem('Storage', computer.storage),
                  _detailItem('Graphics Card', computer.graphicsCard),
                  _detailItem('PC Brand', computer.pcBrand),
                  _detailItem('PC S.No', computer.pcSerialNo),
                ])),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSection('Monitor', [
                  _detailItem('Size', computer.monitorSize),
                  _detailItem('Brand', computer.monitorBrand),
                  _detailItem('Monitor S.No', computer.monitorSerialNo),
                ])),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildSection('Network', [
                  _detailItem('IP Address', computer.ipAddress, isCode: true),
                  _detailItem('MAC Address', computer.macAddress, isCode: true),
                  _detailItem('Connection', computer.connectionType),
                ])),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSection('Printer & Other', [
                  _detailItem('Printer', computer.printer),
                  _detailItem('Printer Cartridge', computer.printerCartridge),
                  _detailItem('Admin/User', computer.adminUser),
                  _detailItem('K7', computer.k7),
                  _detailItem('AMC Code', computer.amcCode),
                ])),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSection('Notes', [
                  if (computer.notes != null && computer.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(computer.notes!,
                          style: const TextStyle(color: Colors.white70)),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No notes',
                          style: TextStyle(color: Colors.grey)),
                    ),
                ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailItem(String label, String? value, {bool isCode = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isCode ? Colors.blue.shade300 : Colors.white,
                fontFamily: isCode ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Active' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
