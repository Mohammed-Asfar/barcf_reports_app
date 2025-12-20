import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for managing application settings, including database path configuration.
/// Settings are stored in a JSON file in the AppData\Local\BARCF_Reports directory.
class SettingsService {
  static const String _settingsFileName = 'settings.json';
  static const String _dbPathKey = 'database_path';
  static const String _isFirstRunKey = 'is_first_run';

  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  SettingsService._();

  Map<String, dynamic>? _cachedSettings;

  /// Gets the settings directory path (AppData\Local\BARCF_Reports)
  Future<String> _getSettingsDirectory() async {
    final appData = await getApplicationSupportDirectory();
    final settingsDir = path.join(appData.path, 'BARCF_Reports');
    await Directory(settingsDir).create(recursive: true);
    return settingsDir;
  }

  /// Gets the full path to the settings file
  Future<String> _getSettingsFilePath() async {
    final dir = await _getSettingsDirectory();
    return path.join(dir, _settingsFileName);
  }

  /// Loads settings from the JSON file
  Future<Map<String, dynamic>> _loadSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    try {
      final filePath = await _getSettingsFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final contents = await file.readAsString();
        _cachedSettings = json.decode(contents) as Map<String, dynamic>;
        return _cachedSettings!;
      }
    } catch (e) {
      // If there's an error reading settings, return empty map
    }

    _cachedSettings = {};
    return _cachedSettings!;
  }

  /// Saves settings to the JSON file
  Future<void> _saveSettings(Map<String, dynamic> settings) async {
    final filePath = await _getSettingsFilePath();
    final file = File(filePath);
    await file.writeAsString(json.encode(settings));
    _cachedSettings = settings;
  }

  /// Returns the default database path (Documents\BARCF_Reports)
  Future<String> getDefaultDbPath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return path.join(documentsDir.path, 'BARCF_Reports');
  }

  /// Gets the configured database path, or default if not set
  Future<String> getDbPath() async {
    final settings = await _loadSettings();
    final dbPath = settings[_dbPathKey] as String?;

    if (dbPath != null && dbPath.isNotEmpty) {
      return dbPath;
    }

    return await getDefaultDbPath();
  }

  /// Sets the database path
  Future<void> setDbPath(String dbPath) async {
    final settings = await _loadSettings();
    settings[_dbPathKey] = dbPath;
    await _saveSettings(settings);
  }

  /// Checks if this is the first run of the application
  Future<bool> isFirstRun() async {
    final settings = await _loadSettings();
    // If settings file doesn't exist or is_first_run is not set to false, it's first run
    return settings[_isFirstRunKey] != false;
  }

  /// Marks the first run as complete
  Future<void> completeFirstRun() async {
    final settings = await _loadSettings();
    settings[_isFirstRunKey] = false;
    await _saveSettings(settings);
  }

  /// Gets full database file path (directory + filename)
  Future<String> getDbFilePath() async {
    final dbDir = await getDbPath();
    return path.join(dbDir, 'barcf_reports.db');
  }

  /// Clears the cached settings (useful after changing settings)
  void clearCache() {
    _cachedSettings = null;
  }
}
