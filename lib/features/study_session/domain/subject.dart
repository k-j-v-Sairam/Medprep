import 'package:isar_community/isar.dart';

part 'subject.g.dart';

/// Subject Collection
/// Optimized for: Fast initial retrieval of the syllabus outline.
/// Query pattern: `isar.subjects.where().findAll()` to build the dashboard.
/// Follows a flat-reference design; Topics are linked via their own `subjectId`
/// rather than embedding a list here to prevent excessive memory usage on startup.
@collection
class Subject {
  Id id = Isar.autoIncrement;

  late String name;
  late String slug;
  String? colorCode;
}
