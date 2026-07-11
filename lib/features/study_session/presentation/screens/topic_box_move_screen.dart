import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:isar_community/isar.dart';
import '../../domain/topic.dart';
import '../../domain/activity_log.dart';

class TopicBoxMoveScreen extends ConsumerStatefulWidget {
  final int topicId;
  final String topicName;
  final String subjectName;
  final Color accentColor;
  final int currentBoxNumber;
  final bool isDirectMove;

  const TopicBoxMoveScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.subjectName,
    required this.accentColor,
    required this.currentBoxNumber,
    this.isDirectMove = true,
  });

  @override
  ConsumerState<TopicBoxMoveScreen> createState() => _TopicBoxMoveScreenState();
}

class _TopicBoxMoveScreenState extends ConsumerState<TopicBoxMoveScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedBox;
  bool _isConfirming = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
late final Animation<double> _slideUp;

  final List<int> _boxIntervals = [1, 3, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _selectedBox = widget.currentBoxNumber;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
_slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _boxColor(int box) {
    switch (box) {
      case 0: return const Color(0xFF9E9E9E);
      case 1: return const Color(0xFFE57373);
      case 2: return const Color(0xFFFFB74D);
      case 3: return const Color(0xFFFFD54F);
      case 4: return const Color(0xFF81C784);
      case 5: return const Color(0xFF4AE176);
      default: return AppTheme.primary;
    }
  }

  String _boxIntervalLabel(int box) {
    if (box == 0) return 'Not viewed';
    final days = _boxIntervals[(box.clamp(1, 5)) - 1];
    return days == 1 ? 'Every day' : 'Every $days days';
  }

  String _boxLabel(int box) {
    switch (box) {
      case 0: return 'New';
      case 1: return 'Learning';
      case 2: return 'Familiar';
      case 3: return 'Known';
      case 4: return 'Proficient';
      case 5: return 'Mastered';
      default: return '';
    }
  }

  Future<void> _confirm() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    HapticFeedback.mediumImpact();

    final isar = ref.read(isarProvider);
    final topic = await isar.topics.get(widget.topicId);
    if (topic != null) {
      topic.boxNumber = _selectedBox;
      if (_selectedBox > 0) {
        final days = _boxIntervals[(_selectedBox.clamp(1, 5)) - 1];
        topic.nextReviewDate = DateTime.now().add(Duration(days: days));
      } else {
        topic.nextReviewDate = null;
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await isar.writeTxn(() async {
        await isar.topics.put(topic);
        var log = await isar.activityLogs.filter().dateEqualTo(today).findFirst();
        if (log != null) {
          log.topicsReviewed += 1;
          await isar.activityLogs.put(log);
        } else {
          log = ActivityLog()
            ..date = today
            ..topicsReviewed = 1;
          await isar.activityLogs.put(log);
        }
      });
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId != null) {
        ref.read(syncServiceProvider).pushTopic(userId, topic);
        final log = await isar.activityLogs.filter().dateEqualTo(today).findFirst();
        if (log != null) {
          ref.read(syncServiceProvider).pushActivityLog(userId, log);
        }
      }
    }

    ref.invalidate(syllabusProvider);
    ref.invalidate(topicsByBoxProvider);
    ref.invalidate(monthlyActivityProvider);

    if (!mounted) return;

    Navigator.of(context).pop(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    widget.accentColor.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Opacity(
              opacity: _fadeIn.value,
              child: Transform.translate(
                offset: Offset(0, _slideUp.value),
                child: child,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.subjectName.toUpperCase(),
                            style: AppTheme.labelXs(color: widget.accentColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage Topic Box',
                      style: AppTheme.displayLg(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.topicName,
                      style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 32),

                    // ── Box Move Section ──────────────────────────────────
                    Row(
                      children: [
                        Text('Move topic to:', style: AppTheme.titleSm()),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Currently Box ${widget.currentBoxNumber}',
                            style: AppTheme.labelXs(color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to change.',
                      style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    ...List.generate(6, (index) {
                      final boxNum = index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildBoxOption(
                          box: boxNum,
                          label: 'Box $boxNum',
                          subtitle: boxNum == 0 
                              ? 'Reset to Not Viewed'
                              : 'Interval: ${_boxIntervalLabel(boxNum)}',
                          icon: Icons.move_to_inbox_rounded,
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // ── Confirm Button ────────────────────────────────────
                    GestureDetector(
                      onTap: _isConfirming ? null : _confirm,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _boxColor(_selectedBox).withValues(alpha: 0.8),
                              _boxColor(_selectedBox),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _boxColor(_selectedBox).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isConfirming
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Confirm — Place in Box $_selectedBox',
                                  style: AppTheme.titleSm(color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Next review info
                    Center(
                      child: Text(
                        '${_boxIntervalLabel(_selectedBox)} · ${_boxLabel(_selectedBox)}',
                        style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxOption({
    required int box,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedBox == box;
    final color = _boxColor(box);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedBox = box);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppTheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : AppTheme.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.titleSm(
                      color: isSelected ? color : AppTheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked_rounded, color: color, size: 20)
            else
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: AppTheme.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
