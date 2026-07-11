import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/shared_prefs_provider.dart' show sharedPreferencesProvider;
import '../../../../core/providers/auth_provider.dart';
import '../../../study_session/application/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = true;
  List<String> _dailyTimes = [];
  bool _hourlyEnabled = false;
  String _hourlyStart = '09:00';
  String _hourlyEnd = '17:00';
  int _repeatFrequency = 1;
  bool _examCountdownEnabled = false;
  String _examCountdownTime = '06:30';
  String _userIdSuffix = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final user = ref.read(currentUserProvider);
    _userIdSuffix = user != null ? '_${user.uid}' : '';
    
    final timesStr = prefs.getString('notification_daily_times$_userIdSuffix');
    if (timesStr != null) {
      _dailyTimes = List<String>.from(jsonDecode(timesStr));
    } else {
      _dailyTimes = ['06:00', '18:00'];
    }

    _hourlyEnabled = prefs.getBool('notification_hourly_enabled$_userIdSuffix') ?? false;
    _hourlyStart = prefs.getString('notification_hourly_start$_userIdSuffix') ?? '09:00';
    _hourlyEnd = prefs.getString('notification_hourly_end$_userIdSuffix') ?? '17:00';
    _repeatFrequency = prefs.getInt('notification_repeat_frequency$_userIdSuffix') ?? 1;
    _examCountdownEnabled = prefs.getBool('notification_exam_countdown_enabled$_userIdSuffix') ?? false;
    _examCountdownTime = prefs.getString('notification_exam_countdown_time$_userIdSuffix') ?? '06:30';

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('notification_daily_times$_userIdSuffix', jsonEncode(_dailyTimes));
    await prefs.setBool('notification_hourly_enabled$_userIdSuffix', _hourlyEnabled);
    await prefs.setString('notification_hourly_start$_userIdSuffix', _hourlyStart);
    await prefs.setString('notification_hourly_end$_userIdSuffix', _hourlyEnd);
    await prefs.setInt('notification_repeat_frequency$_userIdSuffix', _repeatFrequency);
    await prefs.setBool('notification_exam_countdown_enabled$_userIdSuffix', _examCountdownEnabled);
    await prefs.setString('notification_exam_countdown_time$_userIdSuffix', _examCountdownTime);

    // Reschedule notifications
    await ref.read(notificationServiceProvider).rescheduleAllNotifications(prefs);
  }

  Future<void> _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );
    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (!_dailyTimes.contains(timeStr)) {
        setState(() {
          _dailyTimes.add(timeStr);
        });
        await _saveSettings();
      }
    }
  }

  Future<void> _removeTime(int index) async {
    setState(() {
      _dailyTimes.removeAt(index);
    });
    await _saveSettings();
  }

  Future<void> _selectHourlyTime(bool isStart) async {
    final currentStr = isStart ? _hourlyStart : _hourlyEnd;
    final parts = currentStr.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
    );
    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _hourlyStart = timeStr;
        } else {
          _hourlyEnd = timeStr;
        }
      });
      await _saveSettings();
    }
  }

  Future<void> _selectExamCountdownTime() async {
    final parts = _examCountdownTime.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 6,
        minute: int.tryParse(parts[1]) ?? 30,
      ),
    );
    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        _examCountdownTime = timeStr;
      });
      await _saveSettings();
    }
  }

  String _formatTimeStr(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: hour, minute: minute);
    return tod.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Gradient Background
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryContainer, AppTheme.background],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Ambient Glow
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 100,
                                  spreadRadius: 50,
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          left: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text('Reminders', style: AppTheme.headlineMd(color: AppTheme.primary)),
                              Text('Customize your study schedule', style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      
                      // ── SPECIFIC DAILY TIMES ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Goals', style: AppTheme.titleSm(color: AppTheme.onSurface)),
                          IconButton(
                            onPressed: _addTime,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (_dailyTimes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text('No specific times set.', style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant)),
                          ),
                        )
                      else
                        ..._dailyTimes.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TimeCard(
                              timeStr: _formatTimeStr(entry.value),
                              onDelete: () => _removeTime(entry.key),
                            ),
                          );
                        }),
                        
                      const SizedBox(height: 32),
                      
                      // ── REPETITIVE NOTIFICATIONS ──────────────────────────────
                      Text('Repetitive Flow', style: AppTheme.titleSm(color: AppTheme.onSurface)),
                      const SizedBox(height: 12),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text('Enable Repetitive Flow', style: AppTheme.bodyLg(color: _hourlyEnabled ? AppTheme.primary : AppTheme.onSurface)),
                              subtitle: Text('Receive notifications at set intervals', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
                              activeColor: AppTheme.onPrimary,
                              activeTrackColor: AppTheme.primary,
                              inactiveThumbColor: AppTheme.outlineVariant,
                              inactiveTrackColor: AppTheme.surfaceContainer,
                              value: _hourlyEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _hourlyEnabled = val;
                                });
                                _saveSettings();
                              },
                            ),
                            
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              height: _hourlyEnabled ? null : 0,
                              child: ClipRect(
                                child: _hourlyEnabled ? Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(color: AppTheme.outlineVariant),
                                      const SizedBox(height: 16),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Frequency', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
                                          Text('Every $_repeatFrequency hour${_repeatFrequency > 1 ? 's' : ''}', style: AppTheme.labelSm(color: AppTheme.primary)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Row(
                                          children: [1, 2, 3, 4, 6].map((int value) {
                                            final isSelected = _repeatFrequency == value;
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 12.0),
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (_repeatFrequency != value) {
                                                    setState(() => _repeatFrequency = value);
                                                    _saveSettings();
                                                  }
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? AppTheme.primary : context.adaptiveBackground,
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: isSelected
                                                        ? [
                                                            BoxShadow(
                                                              color: AppTheme.primary.withValues(alpha: 0.3),
                                                              blurRadius: 12,
                                                              offset: const Offset(0, 4),
                                                            )
                                                          ]
                                                        : [],
                                                  ),
                                                  child: Text(
                                                    '$value hr${value > 1 ? 's' : ''}',
                                                    style: AppTheme.titleSm(color: isSelected ? AppTheme.onPrimary : AppTheme.onSurface).copyWith(
                                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: _TimeSelectorCard(
                                              label: 'Start',
                                              timeStr: _formatTimeStr(_hourlyStart),
                                              icon: Icons.wb_sunny_rounded,
                                              onTap: () => _selectHourlyTime(true),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _TimeSelectorCard(
                                              label: 'End',
                                              timeStr: _formatTimeStr(_hourlyEnd),
                                              icon: Icons.nightlight_round,
                                              onTap: () => _selectHourlyTime(false),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ) : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // ── EXAM COUNTDOWNS ───────────────────────────────────────
                      Text('Exam Countdowns', style: AppTheme.titleSm(color: AppTheme.onSurface)),
                      const SizedBox(height: 12),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text('Daily Exam Countdown', style: AppTheme.bodyLg(color: _examCountdownEnabled ? AppTheme.primary : AppTheme.onSurface)),
                              subtitle: Text('Get reminded of remaining days at ${_formatTimeStr(_examCountdownTime)}', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
                              activeColor: AppTheme.onPrimary,
                              activeTrackColor: AppTheme.primary,
                              inactiveThumbColor: AppTheme.outlineVariant,
                              inactiveTrackColor: AppTheme.surfaceContainer,
                              value: _examCountdownEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _examCountdownEnabled = val;
                                });
                                _saveSettings();
                              },
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              height: _examCountdownEnabled ? null : 0,
                              child: ClipRect(
                                child: _examCountdownEnabled ? Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(color: AppTheme.outlineVariant),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _TimeSelectorCard(
                                              label: 'Reminder Time',
                                              timeStr: _formatTimeStr(_examCountdownTime),
                                              icon: Icons.access_time_rounded,
                                              onTap: _selectExamCountdownTime,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ) : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String timeStr;
  final VoidCallback onDelete;

  const _TimeCard({required this.timeStr, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.access_time_filled_rounded, color: AppTheme.primary, size: 20),
        ),
        title: Text(timeStr, style: AppTheme.titleSm(color: AppTheme.onSurface)),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _TimeSelectorCard extends StatelessWidget {
  final String label;
  final String timeStr;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeSelectorCard({required this.label, required this.timeStr, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(label, style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text(timeStr, style: AppTheme.titleSm(color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}
