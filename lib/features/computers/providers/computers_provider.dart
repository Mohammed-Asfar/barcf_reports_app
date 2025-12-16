import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../models/computer_model.dart';

class ComputersProvider with ChangeNotifier {
  List<Computer> _computers = [];
  bool _isLoading = false;

  List<Computer> get computers => _computers;
  bool get isLoading => _isLoading;

  Future<void> fetchComputers(int? userId, {String? role}) async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> maps;

    if (role == 'superadmin' || role == 'admin') {
      maps = await db.query(
        'computers',
        where: 'deletedAt IS NULL',
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query(
        'computers',
        where: 'createdByUserId = ? AND deletedAt IS NULL',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );
    }

    _computers = maps.map((e) => Computer.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addComputer(Computer computer) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    // Auto-generate S.No
    final maxSnoResult = await db.rawQuery(
        'SELECT MAX(sno) as maxSno FROM computers WHERE deletedAt IS NULL');
    final currentMax = maxSnoResult.first['maxSno'] as int? ?? 0;
    final newSno = currentMax + 1;

    final computerWithTimestamp = computer.copyWith(
      sno: newSno,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('computers', computerWithTimestamp.toMap());
    notifyListeners();
  }

  Future<void> updateComputer(Computer computer) async {
    final db = await DatabaseHelper.instance.database;
    final computerWithTimestamp = computer.copyWith(
      updatedAt: DateTime.now(),
    );
    await db.update(
      'computers',
      computerWithTimestamp.toMap(),
      where: 'id = ?',
      whereArgs: [computer.id],
    );
    final index = _computers.indexWhere((c) => c.id == computer.id);
    if (index != -1) {
      _computers[index] = computerWithTimestamp;
      notifyListeners();
    }
  }

  Future<void> deleteComputer(int id, int userId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'computers',
      {
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _computers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  List<String> get uniqueSections {
    return _computers
        .where((c) => c.section != null && c.section!.isNotEmpty)
        .map((c) => c.section!)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get uniqueStatuses {
    return _computers.map((c) => c.status).toSet().toList()..sort();
  }
}
