import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../models/issue_model.dart';

class ReportsProvider with ChangeNotifier {
  List<Issue> _issues = [];
  bool _isLoading = false;

  List<Issue> get issues => _issues;
  bool get isLoading => _isLoading;

  Future<void> fetchIssues(int? userId, {String? role}) async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> maps;

    if (role == 'superadmin' || role == 'admin') {
      maps = await db.query('issues', orderBy: 'date DESC');
    } else {
      maps = await db.query(
        'issues',
        where: 'createdByUserId = ? AND deletedAt IS NULL',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
    }

    _issues = maps.map((e) => Issue.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addIssue(Issue issue) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('issues', issue.toMap());
    // Refresh list is handled by UI calling fetchIssues usually, or we can append locally
    // For simplicity, let's just re-fetch or add locally if we knew the ID.
    // Since ID is autoincrement, it's safer to re-fetch or return ID from insert.
    notifyListeners();
  }

  Future<void> updateIssue(Issue issue) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'issues',
      issue.toMap(),
      where: 'id = ?',
      whereArgs: [issue.id],
    );
    // Optimistic update locally
    final index = _issues.indexWhere((i) => i.id == issue.id);
    if (index != -1) {
      _issues[index] = issue;
      notifyListeners();
    }
  }

  Future<void> deleteIssue(int id, int userId) async {
    final db = await DatabaseHelper.instance.database;
    // Soft delete
    await db.update(
      'issues',
      {
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedByUserId': userId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _issues.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
