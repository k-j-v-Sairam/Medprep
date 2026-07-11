import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akpa/core/providers/database_provider.dart';

class MockIsar extends Mock implements Isar {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

/// Provides standard mock overrides for Riverpod.
List<Override> getTestOverrides({
  Isar? isar,
  SharedPreferences? prefs,
}) {
  return [
    if (isar != null) isarProvider.overrideWithValue(isar),
  ];
}
