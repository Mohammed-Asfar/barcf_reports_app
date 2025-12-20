import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../settings/settings_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static String? _currentDbPath;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Initialize FFI for Windows
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Get path from SettingsService
    final dbPath = await SettingsService.instance.getDbFilePath();
    _currentDbPath = dbPath;

    // Ensure directory exists
    await Directory(dirname(dbPath)).create(recursive: true);

    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Reinitializes the database with a new path
  /// Used when user changes the database location
  Future<void> reinitialize(String newDbPath) async {
    // Close existing database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Clear cached path
    _currentDbPath = null;

    // Re-initialize will pick up new path from SettingsService
    await database;
  }

  /// Copies the database file from one location to another
  /// Returns true if successful, false otherwise
  Future<bool> copyDatabase(String fromPath, String toPath) async {
    try {
      final sourceFile = File(fromPath);
      if (!await sourceFile.exists()) {
        return false;
      }

      // Ensure target directory exists
      await Directory(dirname(toPath)).create(recursive: true);

      // Copy the database file
      await sourceFile.copy(toPath);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the current database file path
  String? get currentDbPath => _currentDbPath;

  /// Checks if database exists at given path
  Future<bool> databaseExists(String path) async {
    return await File(path).exists();
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
      purpose TEXT NOT NULL DEFAULT '',
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

    const computersTable = '''
    CREATE TABLE computers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sno INTEGER,
      name TEXT NOT NULL,
      empNo TEXT,
      designation TEXT,
      section TEXT,
      roomNo TEXT,
      processor TEXT,
      ram TEXT,
      storage TEXT,
      graphicsCard TEXT,
      monitorSize TEXT,
      monitorBrand TEXT,
      amcCode TEXT,
      purpose TEXT,
      ipAddress TEXT,
      macAddress TEXT,
      printer TEXT,
      connectionType TEXT,
      adminUser TEXT,
      printerCartridge TEXT,
      k7 TEXT,
      pcSerialNo TEXT,
      monitorSerialNo TEXT,
      pcBrand TEXT,
      status TEXT NOT NULL DEFAULT 'Active',
      notes TEXT,
      createdByUserId INTEGER NOT NULL,
      createdAt TEXT,
      updatedAt TEXT,
      deletedAt TEXT,
      FOREIGN KEY (createdByUserId) REFERENCES users (id)
    )
    ''';

    await db.execute(userTable);
    await db.execute(issueTable);
    await db.execute(computersTable);

    // Seed Superadmin - Password: 'admin' (sha256 hash)
    await db.insert('users', {
      'username': 'superadmin',
      'passwordHash':
          '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918',
      'role': 'superadmin',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add purpose column to issues table for version 4
    if (oldVersion < 4) {
      try {
        await db.execute(
            "ALTER TABLE issues ADD COLUMN purpose TEXT NOT NULL DEFAULT ''");
      } catch (e) {
        // Column may already exist
      }
    }

    // Recreate computers table with new schema for any upgrade
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS computers');
      const computersTable = '''
      CREATE TABLE computers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sno INTEGER,
        name TEXT NOT NULL,
        empNo TEXT,
        designation TEXT,
        section TEXT,
        roomNo TEXT,
        processor TEXT,
        ram TEXT,
        storage TEXT,
        graphicsCard TEXT,
        monitorSize TEXT,
        monitorBrand TEXT,
        amcCode TEXT,
        purpose TEXT,
        ipAddress TEXT,
        macAddress TEXT,
        printer TEXT,
        connectionType TEXT,
        adminUser TEXT,
        printerCartridge TEXT,
        k7 TEXT,
        pcSerialNo TEXT,
        monitorSerialNo TEXT,
        pcBrand TEXT,
        status TEXT NOT NULL DEFAULT 'Active',
        notes TEXT,
        createdByUserId INTEGER NOT NULL,
        createdAt TEXT,
        updatedAt TEXT,
        deletedAt TEXT,
        FOREIGN KEY (createdByUserId) REFERENCES users (id)
      )
      ''';
      await db.execute(computersTable);
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _currentDbPath = null;
    }
  }
}
