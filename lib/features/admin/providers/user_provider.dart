import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../reports/models/user_model.dart';

import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('users', where: 'deletedAt IS NULL');

    _users = maps.map((e) => User.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addUser(String username, String password, String role,
      int createdByUserId) async {
    final db = await DatabaseHelper.instance.database;
    final hashedPassword =
        sha256.convert(utf8.encode(password)).toString(); // Basic hash

    try {
      await db.insert('users', {
        'username': username,
        'passwordHash': hashedPassword,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdByUserId': createdByUserId,
      });
      await fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteUser(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'users',
      {'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchUsers();
  }

  // Reset Password could be added here
}
