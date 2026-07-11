import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import '../models/custom_exam.dart';

class UserSettings {
  final bool isFlashcardMode;
  final List<CustomExam> customExams;

  // Keep these for backward compatibility during transition or remove if safe
  final String? customExamName;
  final DateTime? customExamDate;

  const UserSettings({
    this.isFlashcardMode = true,
    this.customExams = const [],
    this.customExamName,
    this.customExamDate,
  });

  UserSettings copyWith({
    bool? isFlashcardMode,
    List<CustomExam>? customExams,
    String? customExamName,
    DateTime? customExamDate,
  }) {
    return UserSettings(
      isFlashcardMode: isFlashcardMode ?? this.isFlashcardMode,
      customExams: customExams ?? this.customExams,
      customExamName: customExamName ?? this.customExamName,
      customExamDate: customExamDate ?? this.customExamDate,
    );
  }
}

class UserSettingsNotifier extends Notifier<UserSettings> {
  SharedPreferences? _prefs;

  String _userIdSuffix = '';

  @override
  UserSettings build() {
    final user = ref.watch(currentUserProvider);
    _userIdSuffix = user != null ? '_${user.uid}' : '';
    _loadPrefs();
    return const UserSettings();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final isFlashcardMode = _prefs!.getBool('isFlashcardMode$_userIdSuffix') ?? true;
    
    // Legacy single exam
    final customExamName = _prefs!.getString('customExamName$_userIdSuffix');
    final customExamDateStr = _prefs!.getString('customExamDate$_userIdSuffix');
    DateTime? customExamDate;
    if (customExamDateStr != null) {
      customExamDate = DateTime.tryParse(customExamDateStr);
    }
    
    // Multiple custom exams
    List<CustomExam> customExams = [];
    final customExamsJson = _prefs!.getString('customExams$_userIdSuffix');
    if (customExamsJson != null) {
      try {
        final List<dynamic> decodedList = json.decode(customExamsJson);
        customExams = decodedList.map((item) => CustomExam.fromMap(item)).toList();
      } catch (e) {
        // Handle error
      }
    } else if (customExamName != null && customExamDate != null) {
      // Migrate legacy custom exam
      customExams.add(CustomExam(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        name: customExamName, 
        date: customExamDate
      ));
      _saveCustomExams(customExams);
    }
    
    state = UserSettings(
      isFlashcardMode: isFlashcardMode,
      customExams: customExams,
      customExamName: customExamName,
      customExamDate: customExamDate,
    );
  }

  void toggleSessionStyle() {
    final newValue = !state.isFlashcardMode;
    state = state.copyWith(isFlashcardMode: newValue);
    _prefs?.setBool('isFlashcardMode$_userIdSuffix', newValue);
  }

  void addCustomExam(String name, DateTime date) {
    final newExam = CustomExam(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      date: date,
    );
    final newList = List<CustomExam>.from(state.customExams)..add(newExam);
    state = state.copyWith(customExams: newList);
    _saveCustomExams(newList);
  }

  void removeCustomExams(List<String> ids) {
    final newList = state.customExams.where((exam) => !ids.contains(exam.id)).toList();
    state = state.copyWith(customExams: newList);
    _saveCustomExams(newList);
  }
  
  void _saveCustomExams(List<CustomExam> exams) {
    final String jsonStr = json.encode(exams.map((e) => e.toMap()).toList());
    _prefs?.setString('customExams$_userIdSuffix', jsonStr);
  }

  // Deprecated: used for single exam backwards compatibility
  void setCustomExam(String name, DateTime date) {
    addCustomExam(name, date);
  }
}

final userSettingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(
  UserSettingsNotifier.new,
);
