import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class DatabaseInitializer {
  static final DatabaseInitializer _instance = DatabaseInitializer._internal();
  factory DatabaseInitializer() => _instance;
  DatabaseInitializer._internal();

  static bool _isInitialized = false;

  /// Initialize the database when the app starts
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize database helper
      final dbHelper = DatabaseHelper();
      
      // Get database instance to trigger creation if needed
      await dbHelper.database;
      
      _isInitialized = true;
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  /// Check if database is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization status (for testing purposes)
  static void reset() {
    _isInitialized = false;
  }
}