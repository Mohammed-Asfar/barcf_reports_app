import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../../features/reports/models/user_model.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND passwordHash = ? AND deletedAt IS NULL',
      whereArgs: [username, hashedPassword],
    );

    if (maps.isNotEmpty) {
      _currentUser = User.fromMap(maps.first);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> createUser(String username, String password, String role) async {
    if (_currentUser == null) return false;
    // Basic RBAC check
    if (_currentUser!.role == 'user') return false;
    if (_currentUser!.role == 'admin' && role == 'superadmin') return false;

    final db = await DatabaseHelper.instance.database;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    try {
      await db.insert('users', {
        'username': username,
        'passwordHash': hashedPassword,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdByUserId': _currentUser!.id,
      });
      return true;
    } catch (e) {
      // Typically uniqueness constraint violation
      return false;
    }
  }
}
