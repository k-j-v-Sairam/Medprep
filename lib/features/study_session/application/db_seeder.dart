import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/subject.dart';
import '../domain/topic.dart';
import '../domain/activity_log.dart';

const _kDatasetVersionKey = 'dataset_version';
const _kCurrentDatasetVersion = 8; // Bumped to trigger NEET PG JSON syllabus upgrade

class SeedResult {
  final int subjects;
  final int topics;
  final bool wasAlreadySeeded;

  const SeedResult({
    required this.subjects,
    required this.topics,
    required this.wasAlreadySeeded,
  });
}

/// Prepares the Isar database before it is globally opened.
/// If this is a first install or an upgrade, it parses `neet_pg_syllabus.json`
/// and populates the database directly. Since the JSON is lightweight, this is fast.
Future<void> prepareDatabaseIfNeeded(String directory) async {
  final prefs = await SharedPreferences.getInstance();
  final currentStoredVersion = prefs.getInt(_kDatasetVersionKey) ?? 0;

  if (currentStoredVersion == _kCurrentDatasetVersion) {
    dev.log('✅ DB already seeded (v$_kCurrentDatasetVersion).', name: 'DbSeeder');
    return;
  }

  final dbPath = '$directory/default.isar';
  final dbFile = File(dbPath);

  if (dbFile.existsSync() && currentStoredVersion > 0) {
    dev.log('⏳ Upgrading database to v$_kCurrentDatasetVersion (Wiping old progress) ...', name: 'DbSeeder');
    
    // Delete old database to ensure a clean slate for the new IDs
    try {
      dbFile.deleteSync();
      final lockFile = File('$directory/default.isar-lck');
      if (lockFile.existsSync()) lockFile.deleteSync();
    } catch (e) {
      dev.log('Error deleting old database: $e', name: 'DbSeeder');
    }
  } else {
    dev.log('⏳ First time setup, reading JSON syllabus ...', name: 'DbSeeder');
  }

  // Read JSON syllabus
  dev.log('Parsing neet_pg_syllabus.json...', name: 'DbSeeder');
  final jsonString = await rootBundle.loadString('assets/neet_pg_syllabus.json');
  final Map<String, dynamic> data = jsonDecode(jsonString);

  final subjectsJson = data['subjects'] as List<dynamic>;
  final topicsJson = data['topics'] as List<dynamic>;

  final subjectsToInsert = <Subject>[];
  for (final s in subjectsJson) {
    final subj = Subject()
      ..id = s['id'] as int
      ..name = s['name'] as String
      ..slug = s['slug'] as String
      ..colorCode = s['colorCode'] as String?;
    subjectsToInsert.add(subj);
  }

  final topicsToInsert = <Topic>[];
  for (final t in topicsJson) {
    final topic = Topic()
      ..id = t['id'] as int
      ..subjectId = t['subjectId'] as int
      ..name = t['name'] as String
      ..description = t['description'] as String?
      ..isCompleted = false
      ..boxNumber = 0
      ..nextReviewDate = DateTime.now();
    topicsToInsert.add(topic);
  }

  // Open temporary Isar instance to insert records
  final newIsar = await Isar.open(
    [ActivityLogSchema, SubjectSchema, TopicSchema],
    directory: directory,
  );

  await newIsar.writeTxn(() async {
    await newIsar.subjects.putAll(subjectsToInsert);
    await newIsar.topics.putAll(topicsToInsert);
  });

  await newIsar.close();

  await prefs.setInt(_kDatasetVersionKey, _kCurrentDatasetVersion);
  dev.log('✅ Database preparation complete. Inserted ${subjectsToInsert.length} subjects and ${topicsToInsert.length} topics.', name: 'DbSeeder');
}

