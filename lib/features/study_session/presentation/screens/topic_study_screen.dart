import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:isar_community/isar.dart';
import '../../domain/activity_log.dart';
import '../../domain/topic.dart';
import 'session_complete_screen.dart';

class TopicStudyScreen extends ConsumerStatefulWidget {
  final SubjectViewModel subject;
  
  const TopicStudyScreen({super.key, required this.subject});

  @override
  ConsumerState<TopicStudyScreen> createState() => _TopicStudyScreenState();
}

class _TopicStudyScreenState extends ConsumerState<TopicStudyScreen> {
  List<TopicViewModel> _dueTopics = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  
  int _correctCount = 0;
  int _againCount = 0;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _loadDueTopics();
  }
  
  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadDueTopics() async {
    final topics = await ref.read(topicsForSubjectProvider(widget.subject.id).future);
    setState(() {
      _dueTopics = topics.where((t) => t.isDueToday && t.boxNumber < 5).toList();
      _isLoading = false;
    });
  }

  Future<void> _handleAnswer(bool isCorrect) async {
    if (_currentIndex >= _dueTopics.length) return;
    
    HapticFeedback.lightImpact();
    final topic = _dueTopics[_currentIndex];
    final isar = ref.read(isarProvider);
    
    final dbTopic = await isar.topics.get(topic.id);
    if (dbTopic != null) {
      if (isCorrect) {
        _correctCount++;
        dbTopic.boxNumber = dbTopic.boxNumber == 0 ? 1 : (dbTopic.boxNumber + 1).clamp(1, 5);
      } else {
        _againCount++;
        dbTopic.boxNumber = 1;
      }
      
      final intervals = [1, 3, 7, 14, 30];
      final days = intervals[(dbTopic.boxNumber.clamp(1, 5)) - 1];
      dbTopic.nextReviewDate = DateTime.now().add(Duration(days: days));
      
      await isar.writeTxn(() async {
        await isar.topics.put(dbTopic);
      });
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId != null) {
        ref.read(syncServiceProvider).pushTopic(userId, dbTopic);
      }
    }

    if (_currentIndex < _dueTopics.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishSession();
    }
  }

  Future<void> _finishSession() async {
    _stopwatch.stop();
    
    // Log Activity
    final isar = ref.read(isarProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    await isar.writeTxn(() async {
      var log = await isar.activityLogs.filter().dateEqualTo(today).findFirst();
      if (log != null) {
        log.topicsReviewed += _dueTopics.length;
        await isar.activityLogs.put(log);
      } else {
        log = ActivityLog()
          ..date = today
          ..topicsReviewed = _dueTopics.length;
        await isar.activityLogs.put(log);
      }
    });
    
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId != null) {
      final log = await isar.activityLogs.filter().dateEqualTo(today).findFirst();
      if (log != null) {
        ref.read(syncServiceProvider).pushActivityLog(userId, log);
      }
    }

    ref.invalidate(syllabusProvider);
    ref.invalidate(topicsByBoxProvider);

    if (!mounted) return;
    
    final state = await ref.read(syllabusProvider.future);
    
    final elapsed = _stopwatch.elapsed;
    String timeLabel;
    if (elapsed.inHours > 0) {
      timeLabel = '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m';
    } else if (elapsed.inMinutes > 0) {
      timeLabel = '${elapsed.inMinutes}m ${elapsed.inSeconds.remainder(60)}s';
    } else {
      timeLabel = '${elapsed.inSeconds}s';
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SessionCompleteScreen(
          topicsReviewed: _dueTopics.length,
          correct: _correctCount,
          again: _againCount,
          timeLabel: timeLabel,
          streakDays: state.streakDays,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _quitSession() async {
    _stopwatch.stop();
    if (_currentIndex > 0) {
      final isar = ref.read(isarProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      await isar.writeTxn(() async {
        var log = await isar.activityLogs.filter().dateEqualTo(today).findFirst();
        if (log != null) {
          log.topicsReviewed += _currentIndex;
          await isar.activityLogs.put(log);
        } else {
          log = ActivityLog()
            ..date = today
            ..topicsReviewed = _currentIndex;
          await isar.activityLogs.put(log);
        }
      });
      
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId != null) {
        final log = await isar.activityLogs.filter().dateEqualTo(today).findFirst();
        if (log != null) {
          ref.read(syncServiceProvider).pushActivityLog(userId, log);
        }
      }

      ref.invalidate(syllabusProvider);
      ref.invalidate(topicsByBoxProvider);
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_dueTopics.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 64, color: widget.subject.accentColor),
              const SizedBox(height: 16),
              Text('All caught up!', style: AppTheme.displayLg()),
              const SizedBox(height: 8),
              Text('No topics due for ${widget.subject.name} right now.', style: AppTheme.bodyMd()),
            ],
          ),
        ),
      );
    }

    final currentTopic = _dueTopics[_currentIndex];
    final progress = (_currentIndex + 1) / _dueTopics.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _quitSession();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant),
            onPressed: () => _quitSession(),
          ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: widget.subject.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.subject.name.toUpperCase(),
                style: AppTheme.labelSm(color: widget.subject.accentColor)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppTheme.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation(widget.subject.accentColor),
                ),
              ),
            ),
            
            // Topic Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: widget.subject.accentColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: widget.subject.accentColor.withValues(alpha: 0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.subject.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Box ${currentTopic.boxNumber}',
                            style: AppTheme.labelXs(color: widget.subject.accentColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentTopic.name,
                          style: AppTheme.displayLg(),
                        ),
                        if (currentTopic.description.isNotEmpty && currentTopic.description != currentTopic.name) ...[
                          const SizedBox(height: 24),
                          Text(
                            currentTopic.description,
                            style: AppTheme.bodyLg(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: _StudyButton(
                      label: 'DON\'T KNOW',
                      color: AppTheme.error,
                      icon: Icons.close_rounded,
                      onTap: () => _handleAnswer(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StudyButton(
                      label: 'KNOW',
                      color: AppTheme.tertiary,
                      icon: Icons.check_rounded,
                      onTap: () => _handleAnswer(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _StudyButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StudyButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.titleSm(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
