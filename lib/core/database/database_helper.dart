import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('barcf_reports.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for Windows
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'BARCF_Reports', filePath);

    // Ensure directory exists
    await Directory(dirname(path)).create(recursive: true);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const userTable = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      passwordHash TEXT NOT NULL,
      role TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      createdByUserId INTEGER,
      deletedAt TEXT
    )
    ''';

    const issueTable = '''
    CREATE TABLE issues (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sno INTEGER,
      name TEXT NOT NULL,
      empNo TEXT NOT NULL,
      problem TEXT NOT NULL,
      isIssueSorted INTEGER NOT NULL,
      materialsReplaced TEXT,
      attendedBy TEXT NOT NULL,
      date TEXT NOT NULL,
      createdByUserId INTEGER NOT NULL,
      createdAt TEXT,
      updatedAt TEXT,
      updatedByUserId INTEGER,
      deletedAt TEXT,
      FOREIGN KEY (createdByUserId) REFERENCES users (id)
    )
    ''';

    await db.execute(userTable);
    await db.execute(issueTable);

    // Seed Superadmin - Password: 'admin' (This should be hashed in production logic,
    // but for initial seed we might need a known hash or handle it in AuthService)
    // For now, I will insert a placeholder and let AuthService handle the first login/hashing if needed or seed a known hash.
    // Let's assume we'll handle the hashing in the app, but for "admin" password (sha256 of 'admin'):
    // '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918'

    await db.insert('users', {
      'username': 'superadmin',
      'passwordHash':
          '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918',
      'role': 'superadmin',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
