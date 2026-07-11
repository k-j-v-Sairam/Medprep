import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../../../core/utils/box_ui_helper.dart';
import 'topic_detail_screen.dart';

import '../../../../core/widgets/skeleton_loading_widget.dart';
import 'package:akpa/features/vault/presentation/screens/vault_screen.dart';

class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(syllabusProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      extendBodyBehindAppBar: true,
      body: asyncState.when(
        loading: () => Scaffold(
          backgroundColor: context.adaptiveBackground,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: const SyllabusSkeletonWidget(),
        ),
        error: (err, st) => Center(child: Text('Error loading syllabus: $err')),
        data: (state) {
          final subjects = state.subjects;

          return Stack(
            children: [
              // Subtle top gradient glow for atmosphere
              Positioned(
                top: -100,
                left: -50,
                right: -50,
                child: Container(
                  height: 350,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.8,
                      colors: [
                        AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(syllabusProvider);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // ── Header (Hero Card) ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Dashboard', style: AppTheme.displayLg(color: context.adaptiveSurfaceContainer == Colors.white ? Colors.black87 : AppTheme.onSurface)),
                                IconButton(
                                  icon: Icon(Icons.settings_outlined, color: isDark ? AppTheme.onSurfaceVariant : Colors.black54),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const SettingsSheet(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Hero Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryContainer,
                                    AppTheme.primary.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.25),
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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ready to crush it?',
                                              style: AppTheme.headlineMd(color: Colors.white),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Keep up the great momentum!',
                                              style: AppTheme.bodyMd(color: Colors.white.withValues(alpha: 0.9)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text('🚀', style: TextStyle(fontSize: 24)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  Row(
                                    children: [
                                      _HeroStat(
                                        label: 'Daily Streak',
                                        value: '${state.streakDays} Days',
                                        icon: Icons.local_fire_department_rounded,
                                        color: Colors.orangeAccent,
                                      ),
                                      const SizedBox(width: 32),
                                      _HeroStat(
                                        label: 'Due Today',
                                        value: '${state.totalDueToday} Topics',
                                        icon: Icons.assignment_turned_in_rounded,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Search Bar ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: TextField(
                          controller: _searchController,
                          style: AppTheme.bodyMd(color: isDark ? AppTheme.onSurface : Colors.black87),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'What do you want to study?',
                            hintStyle: AppTheme.bodyMd(color: isDark ? AppTheme.onSurfaceVariant.withValues(alpha: 0.7) : Colors.black54),
                            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary.withValues(alpha: 0.8)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, size: 20, color: isDark ? AppTheme.onSurfaceVariant : Colors.black54),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: context.adaptiveSurfaceHigh,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5),
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                    ),

                    // ── Subject Cards ────────────────────────────────────
                    Builder(builder: (context) {
                      var filteredSubjects = subjects;
                      if (_searchQuery.trim().isNotEmpty) {
                        final q = _searchQuery.trim().toLowerCase();
                        filteredSubjects = subjects.where((s) => s.name.toLowerCase().contains(q)).toList();
                      }

                      if (filteredSubjects.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                            child: Center(
                              child: Text(
                                'No subjects found.',
                                style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final subject = filteredSubjects[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _SubjectCard(
                                  subject: subject,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (_, a, __) => TopicDetailScreen(subject: subject),
                                        transitionsBuilder: (_, anim, __, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1, 0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: anim,
                                              curve: Curves.easeOutCubic,
                                            )),
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 350),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: filteredSubjects.length,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO STAT WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTheme.titleSm(color: Colors.white).copyWith(fontSize: 18, height: 1.1)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.labelSm(color: Colors.white.withValues(alpha: 0.8)).copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODERN SUBJECT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final SubjectViewModel subject;
  final VoidCallback onTap;
  const _SubjectCard({required this.subject, required this.onTap});

  Widget _buildBoxStat(int box, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: AppTheme.labelSm(color: color).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.adaptiveSurfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.adaptiveGlassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Smooth Squircle Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: subject.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(subject.iconData, color: subject.accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: AppTheme.titleSm(color: isDark ? AppTheme.onSurface : Colors.black87).copyWith(fontSize: 18, letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${subject.totalTopics} Topics • ${subject.totalDue} Due',
                          style: AppTheme.bodyMd(color: isDark ? AppTheme.onSurfaceVariant : Colors.black54).copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Minimal chevron
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceHighest : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppTheme.onSurfaceVariant : Colors.black54,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (subject.totalTopics > 0) ...[
                const SizedBox(height: 20),
                Wrap(
                  children: List.generate(6, (index) {
                    return _buildBoxStat(index, subject.boxCounts[index], index.toBoxColor());
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

