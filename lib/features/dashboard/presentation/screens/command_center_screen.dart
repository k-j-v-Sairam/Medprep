import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../../../core/providers/user_settings_provider.dart';
import 'package:akpa/features/vault/presentation/screens/vault_screen.dart';

import '../../../../core/widgets/skeleton_loading_widget.dart';
import '../../../../core/widgets/synapse_activity_widget.dart';
import 'reminders_screen.dart';
import 'topic_detail_screen.dart';
import 'syllabus_screen.dart';
import '../../../study_session/presentation/screens/topic_study_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMMAND CENTER — Modern Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _neetPGLeft = Duration.zero;
  Map<String, Duration> _customExamsLeft = {};

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // ── Exam target dates
  static final DateTime _neetPGDate = DateTime(2026, 8, 21, 8, 0);

  @override
  void initState() {
    super.initState();
    _updateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdowns();
    });
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  void _updateCountdowns() {
    final now = DateTime.now();
    final customExams = ref.read(userSettingsProvider).customExams;
    setState(() {
      _neetPGLeft = _neetPGDate.difference(now);
      _customExamsLeft.clear();
      for (var exam in customExams) {
        _customExamsLeft[exam.id] = exam.date.difference(now);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _pushFade(BuildContext ctx, Widget page) {
    Navigator.of(ctx).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _pushSlide(BuildContext ctx, Widget page) {
    Navigator.of(ctx).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showAddCustomExamSheet() {
    final nameCtrl = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: context.adaptiveBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Target Exam', style: AppTheme.headlineMd()),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Exam Name (e.g. INICET)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exam Date'),
                    subtitle: Text(selectedDate != null 
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Select a date'),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setSheetState(() => selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty && selectedDate != null) {
                          ref.read(userSettingsProvider.notifier).addCustomExam(nameCtrl.text, selectedDate!);
                          _updateCountdowns();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save Timer'),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showManageCountdownsSheet() {
    final customExams = ref.read(userSettingsProvider).customExams;
    if (customExams.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final List<String> selectedIds = [];
        return StatefulBuilder(
          builder: (context, setSheetState) {
            
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: context.adaptiveBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manage Countdowns', style: AppTheme.headlineMd()),
                      if (selectedIds.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                          onPressed: () {
                            ref.read(userSettingsProvider.notifier).removeCustomExams(selectedIds);
                            _updateCountdowns();
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: customExams.length,
                      itemBuilder: (context, index) {
                        final exam = customExams[index];
                        final isSelected = selectedIds.contains(exam.id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  selectedIds.add(exam.id);
                                } else {
                                  selectedIds.remove(exam.id);
                                }
                              });
                            },
                          ),
                          title: Text(exam.name, style: AppTheme.titleSm()),
                          subtitle: Text(
                            '${exam.date.day}/${exam.date.month}/${exam.date.year}',
                            style: AppTheme.labelSm(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(syllabusProvider);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: asyncState.when(
        loading: () => const Scaffold(backgroundColor: Colors.transparent, body: SkeletonLoadingWidget()),
        error: (err, st) => Center(child: Text('Error loading syllabus: $err')),
        data: (state) {
          final subjects       = state.subjects;
          final missionItems   = subjects.where((s) => s.totalDue > 0).take(3).toList();
          final lapsedCards    = state.totalDueToday;
          final masteryPct     = (state.globalMastery * 100).round();
          final activeSubjects = subjects.where((s) => s.totalDue > 0).length;
          final streakDays     = state.streakDays;

          return Stack(
            children: [
              // ── Ambient top glow ─────────────────────────────────────────
              Positioned(
                top: -100, left: -50, right: -50,
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    height: 350,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [
                          AppTheme.primary.withValues(alpha: _glowAnim.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(syllabusProvider);
                    ref.invalidate(monthlyActivityProvider);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // ── AppBar ────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MedPrep',
                                      style: AppTheme.headlineMd(color: AppTheme.primary).copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      )),
                                  const SizedBox(height: 2),
                                  Text('Ready for today?',
                                      style: AppTheme.labelSm(
                                          color: context.adaptiveOnSurfaceVariant).copyWith(
                                        letterSpacing: 0.2,
                                      )),
                                ],
                              ),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final stateAsync = ref.watch(notificationHistoryProvider);
                                final count = stateAsync.valueOrNull?.logs.where((l) => l.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 1)))).length ?? 0;
                                return Badge(
                                  isLabelVisible: count > 0,
                                  label: Text(count.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppTheme.primary,
                                  offset: const Offset(-6, 6),
                                  child: IconButton(
                                    icon: Icon(Icons.notifications_none_rounded, color: context.adaptiveOnSurfaceVariant),
                                    onPressed: () {
                                      _pushSlide(context, const RemindersScreen());
                                    },
                                  ),
                                );
                              }
                            ),
                            IconButton(
                              icon: Icon(Icons.settings_outlined, color: context.adaptiveOnSurfaceVariant),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const SettingsSheet(),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Countdown Carousel ────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: _CountdownSection(
                          neetPGLeft: _neetPGLeft,
                          customExamsLeft: _customExamsLeft,
                          onAddCustom: _showAddCustomExamSheet,
                          onManageCountdowns: _showManageCountdownsSheet,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // ── Quick Insights ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SectionHeader(
                          title: 'Quick Insights',
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _QuickInsightsGrid(
                          lapsedCards: lapsedCards,
                          masteryPct: masteryPct,
                          activeSubjects: activeSubjects,
                          streakDays: streakDays,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // ── Activity Chart ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SectionHeader(
                          title: 'Activity (Last 7 Days)',
                        ),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Container(
                          height: 220,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.isDark 
                                ? AppTheme.surfaceLowest.withValues(alpha: 0.6) 
                                : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.adaptiveGlassBorder),
                          ),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final activityAsync = ref.watch(monthlyActivityProvider);
                              return activityAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Center(child: Text('Error: $e')),
                                data: (Map<DateTime, int> logs) {
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  
                                  List<BarChartGroupData> barGroups = [];
                                  int maxCards = 10;
                                  
                                  for (int i = 0; i < 7; i++) {
                                    final date = today.subtract(Duration(days: 6 - i));
                                    final cards = (logs[date] ?? 0).toDouble();
                                    
                                    if (cards > maxCards) maxCards = cards.toInt();
                                    
                                    barGroups.add(
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: cards,
                                            color: i == 6 ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.3),
                                            width: 14,
                                            borderRadius: BorderRadius.circular(4),
                                            backDrawRodData: BackgroundBarChartRodData(
                                              show: true,
                                              toY: maxCards.toDouble(),
                                              color: AppTheme.surfaceHighest.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: (maxCards * 1.2).toDouble(),
                                      barTouchData: BarTouchData(enabled: false),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final date = today.subtract(Duration(days: 6 - value.toInt()));
                                              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  days[date.weekday - 1],
                                                  style: AppTheme.labelXs(color: value.toInt() == 6 ? AppTheme.primary : context.adaptiveOnSurfaceVariant),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      gridData: FlGridData(show: false),
                                      borderData: FlBorderData(show: false),
                                      barGroups: barGroups,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // ── Synapse Activity ──────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SectionHeader(
                          title: 'Synapse Activity',
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        child: SynapseActivityWidget(streakDays: streakDays),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNTDOWN SECTION & CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownSection extends ConsumerWidget {
  final Duration neetPGLeft;
  final Map<String, Duration> customExamsLeft;
  final VoidCallback onAddCustom;
  final VoidCallback onManageCountdowns;

  const _CountdownSection({
    required this.neetPGLeft,
    required this.customExamsLeft,
    required this.onAddCustom,
    required this.onManageCountdowns,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final customExams = settings.customExams;
    
    return SizedBox(
      height: 180,
      child: PageView(
        controller: PageController(viewportFraction: 0.90),
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ModernCountdownCard(
              title: 'NEET-PG 2026',
              duration: neetPGLeft,
              color: AppTheme.primary,
            ),
          ),
          for (var exam in customExams)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _ModernCountdownCard(
                title: exam.name,
                duration: customExamsLeft[exam.id] ?? Duration.zero,
                color: AppTheme.secondary,
                onLongPress: onManageCountdowns,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AddCustomExamCard(onTap: onAddCustom),
          ),
        ],
      ),
    );
  }
}

class _ModernCountdownCard extends StatelessWidget {
  final String title;
  final Duration duration;
  final Color color;
  final VoidCallback? onLongPress;

  const _ModernCountdownCard({
    required this.title,
    required this.duration,
    required this.color,
    this.onLongPress,
  });

  Widget _buildCountdownText(BuildContext context, Duration d) {
    if (d.isNegative) {
      return Text('Passed', style: AppTheme.displayLg(color: context.adaptiveOnSurface));
    }
    final days = d.inDays.toString();
    final hrs = (d.inHours % 24).toString().padLeft(2, '0');
    
    return RichText(
      text: TextSpan(
        style: AppTheme.displayLg(color: context.adaptiveOnSurface).copyWith(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        children: [
          TextSpan(text: days, style: TextStyle(color: color)),
          TextSpan(
            text: ' Days  ',
            style: AppTheme.titleSm(color: context.adaptiveOnSurfaceVariant).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          TextSpan(text: hrs, style: TextStyle(color: color)),
          TextSpan(
            text: ' Hrs',
            style: AppTheme.titleSm(color: context.adaptiveOnSurfaceVariant).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = 365;
    final remaining = duration.inDays.clamp(0, totalDays);
    final barProgress = 1.0 - (remaining / totalDays);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.isDark ? AppTheme.surfaceLowest.withValues(alpha: 0.8) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.adaptiveGlassBorder),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: AppTheme.labelSm(color: color).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (onLongPress != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHighest.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_horiz_rounded, size: 16, color: context.adaptiveOnSurfaceVariant),
                  ),
              ],
            ),
          const Spacer(),
          _buildCountdownText(context, duration),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: barProgress,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _AddCustomExamCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCustomExamCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.isDark ? AppTheme.surfaceLowest.withValues(alpha: 0.4) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.adaptiveGlassBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Target Exam',
                style: AppTheme.titleSm(color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your next milestone',
                style: AppTheme.labelXs(color: context.adaptiveOnSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.headlineMd().copyWith(fontWeight: FontWeight.w600)),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!,
                style: AppTheme.labelSm(color: AppTheme.primary).copyWith(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MISSION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final SubjectViewModel subject;
  final VoidCallback onTap;
  final VoidCallback onStudy;

  const _MissionCard({
    required this.subject,
    required this.onTap,
    required this.onStudy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.isDark 
              ? AppTheme.surfaceHighest.withValues(alpha: 0.3) 
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.adaptiveGlassBorder),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: subject.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(subject.iconData,
                  color: subject.accentColor, size: 24),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${subject.name} Review',
                      style: AppTheme.titleSm().copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${subject.totalDue} Topics Due',
                    style: AppTheme.labelSm(
                        color: AppTheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Action
            GestureDetector(
              onTap: onStudy,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppTheme.onPrimary, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK INSIGHTS GRID
// ─────────────────────────────────────────────────────────────────────────────

class _QuickInsightsGrid extends StatelessWidget {
  final int lapsedCards;
  final int masteryPct;
  final int activeSubjects;
  final int streakDays;

  const _QuickInsightsGrid({
    required this.lapsedCards,
    required this.masteryPct,
    required this.activeSubjects,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: _InsightTile(
                topLabel: 'Topics Due',
                topIcon: Icons.library_books_rounded,
                topIconColor: AppTheme.error,
                value: '$lapsedCards',
                footer: 'Needs review',
                accentColor: AppTheme.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InsightTile(
                topLabel: 'Mastery',
                topIcon: Icons.verified_rounded,
                topIconColor: AppTheme.secondary,
                value: '$masteryPct%',
                footer: '🟢 Synced',
                accentColor: AppTheme.secondary,
                isHighlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2
        Row(
          children: [
            Expanded(
              child: _InsightTile(
                topLabel: 'Active Subjects',
                topIcon: Icons.auto_stories_rounded,
                topIconColor: AppTheme.primary,
                value: '$activeSubjects',
                footer: 'In progress',
                accentColor: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InsightTile(
                topLabel: 'Streak',
                topIcon: Icons.local_fire_department_rounded,
                topIconColor: const Color(0xFFFFB347),
                value: '$streakDays',
                footer: 'Days active',
                accentColor: const Color(0xFFFFB347),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INSIGHT TILE
// ─────────────────────────────────────────────────────────────────────────────

class _InsightTile extends StatelessWidget {
  final String topLabel;
  final IconData topIcon;
  final Color topIconColor;
  final String value;
  final String footer;
  final Color accentColor;
  final bool isHighlighted;

  const _InsightTile({
    required this.topLabel,
    required this.topIcon,
    required this.topIconColor,
    required this.value,
    required this.footer,
    required this.accentColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? accentColor.withValues(alpha: 0.08)
            : (context.isDark ? AppTheme.surfaceHighest.withValues(alpha: 0.3) : const Color(0xFFF9FAFB)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted
              ? accentColor.withValues(alpha: 0.2)
              : context.adaptiveGlassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(topIcon, color: topIconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(topLabel,
                    style: AppTheme.labelXs(
                        color: AppTheme.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headlineMd(
              color: isHighlighted
                  ? accentColor
                  : AppTheme.onSurface,
            ).copyWith(fontSize: 28, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(footer,
              style: AppTheme.labelXs(
                  color: isHighlighted
                      ? accentColor.withValues(alpha: 0.8)
                      : AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
