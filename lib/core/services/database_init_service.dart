import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for initialising the local Isar database.
///
/// This service ensures that the offline-first database is ready before the
/// application starts. It uses a pre-built Isar database file to avoid parsing
/// any JSON at runtime, ensuring blazing-fast cold starts regardless of dataset size.
///
/// How the offline pre-built .isar asset is generated:
/// A separate one-time seed script (e.g., a CLI tool or a developer-only Flutter
/// app mode) parses the raw JSON datasets (Subjects, Topics, Flashcards), opens
/// an Isar instance locally, writes all records using the exact schema, and closes
/// the instance. The resulting `default.isar` file is then copied into this project's
/// `assets/` directory and bundled with the release app.
class DatabaseInitService {
  static const String _assetPath = 'assets/default.isar';
  static const String _dbName = 'default.isar';

  /// Prepares the Isar database.
  /// 
  /// Checks if the database file already exists in the application documents directory.
  /// If it does not exist, copies the pre-built `.isar` file from the app's assets.
  /// If it does exist, skips the copy.
  /// 
  /// Throws an exception if the copy fails (e.g., corrupted asset, disk full),
  /// ensuring we don't silently proceed with a missing or empty database.
  static Future<String> initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File('${dir.path}/$_dbName');

    if (await dbFile.exists()) {
      // Database already exists, skip copy
      return dir.path;
    }

    try {
      final byteData = await rootBundle.load(_assetPath);
      final buffer = byteData.buffer;
      
      final bgFile = File(dbFile.path);
      await bgFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
      
      return dir.path;
    } catch (e) {
      // Handle copy failure: delete the potentially corrupted/partial file if it was created
      if (await dbFile.exists()) {
        try {
          await dbFile.delete();
        } catch (_) {
          // Ignore deletion errors
        }
      }
      throw Exception('Failed to initialise offline database from assets: $e');
    }
  }
}
