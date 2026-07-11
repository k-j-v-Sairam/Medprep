import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shared_prefs_provider.dart' show sharedPreferencesProvider;

/// A service to manage application settings, specifically Leitner box intervals.
class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  /// Key prefix for box intervals.
  static const String _boxIntervalKeyPrefix = 'box_interval_';

  /// Default intervals for boxes 1 to 5.
  /// Box 1 is fixed at 1 day.
  static const List<int> defaultIntervals = [1, 2, 4, 7, 14];

  /// Returns the configured intervals for boxes 1 to 5.
  List<int> getBoxIntervals() {
    return List.generate(5, (index) {
      if (index == 0) return 1; // Box 1 is always 1 day
      final key = '$_boxIntervalKeyPrefix${index + 1}';
      return _prefs.getInt(key) ?? defaultIntervals[index];
    });
  }

  /// Sets the interval in days for a specific box.
  /// Note: [boxNumber] is 1-indexed. Modifying box 1 is ignored.
  Future<void> setBoxInterval(int boxNumber, int days) async {
    if (boxNumber <= 1 || boxNumber > 5) return;
    final key = '$_boxIntervalKeyPrefix$boxNumber';
    await _prefs.setInt(key, days);
  }
}

/// Provider for the SettingsService.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

/// A notifier that exposes the list of intervals and allows updating them,
/// causing dependent providers to rebuild.
class BoxIntervalsNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    final service = ref.watch(settingsServiceProvider);
    return service.getBoxIntervals();
  }

  Future<void> updateInterval(int boxNumber, int days) async {
    final service = ref.read(settingsServiceProvider);
    await service.setBoxInterval(boxNumber, days);
    // Rebuild the state
    state = service.getBoxIntervals();
  }
}

/// Provider that exposes the current list of box intervals and allows updates.
final boxIntervalsProvider = NotifierProvider<BoxIntervalsNotifier, List<int>>(
  BoxIntervalsNotifier.new,
);
