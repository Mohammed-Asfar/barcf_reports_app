import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/issue_model.dart';
import 'issue_form_screen.dart';

class IssueDetailScreen extends StatelessWidget {
  final Issue issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Issue #${issue.sno ?? issue.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => IssueFormScreen(issue: issue)),
              );
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: issue.isIssueSorted
                                  ? const Color(0xFF22C55E).withOpacity(0.15)
                                  : const Color(0xFFF59E0B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              issue.isIssueSorted
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: issue.isIssueSorted
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFF59E0B),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  issue.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Employee No: ${issue.empNo}',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(issue.isIssueSorted),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Details Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _buildDetailCard('Problem Description',
                            issue.problem, Icons.report_problem_outlined)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildDetailCard(
                            'Materials Replaced',
                            issue.materialsReplaced!.isEmpty
                                ? 'None'
                                : issue.materialsReplaced!,
                            Icons.build_outlined)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildInfoTile(
                            'Date',
                            DateFormat('MMMM dd, yyyy').format(issue.date),
                            Icons.calendar_today)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildInfoTile('Attended By', issue.attendedBy,
                            Icons.person_outline)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildInfoTile(
                            'S.No', issue.sno?.toString() ?? '-', Icons.tag)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildInfoTile(
                            'Created',
                            issue.createdAt != null
                                ? DateFormat('MMM dd, yyyy HH:mm')
                                    .format(issue.createdAt!)
                                : '-',
                            Icons.access_time)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildInfoTile(
                            'Updated',
                            issue.updatedAt != null
                                ? DateFormat('MMM dd, yyyy HH:mm')
                                    .format(issue.updatedAt!)
                                : '-',
                            Icons.update)),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isResolved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style:
                const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
