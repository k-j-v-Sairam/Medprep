import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../../../core/providers/database_provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../../core/widgets/skeleton_loading_widget.dart';
import '../../../study_session/domain/topic.dart';
import '../../../settings/presentation/screens/box_settings_screen.dart';
import '../../../settings/presentation/screens/notification_settings_screen.dart';
import '../../../settings/presentation/screens/profile_screen.dart';
import '../../../study_session/application/notification_service.dart';
import '../../../library/application/library_provider.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(syllabusProvider);
    
    return asyncState.when(
      loading: () => Scaffold(
        backgroundColor: context.adaptiveBackground,
        body: const SkeletonLoadingWidget(),
      ),
      error: (err, st) => Scaffold(
        backgroundColor: context.adaptiveBackground,
        body: Center(child: Text('Error: $err', style: AppTheme.bodyMd())),
      ),
      data: (state) {
        final mastery = (state.globalMastery * 100).round();

        return Scaffold(
          backgroundColor: context.adaptiveBackground,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(syllabusProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // App Bar Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.psychology_outlined, color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text('Vault', style: AppTheme.displayLg().copyWith(fontSize: 28)),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.adaptiveSurfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.adaptiveGlassBorder),
                          ),
                        ),
                        icon: const Icon(Icons.settings_outlined, color: AppTheme.onSurfaceVariant),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const SettingsSheet(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Profile & Streak Header
                  _ProfileAndStreakHeader(streakDays: state.streakDays),
                  const SizedBox(height: 32),

                  // Mastery Overview
                  _MasteryOverview(
                    totalMastered: state.totalMastered,
                    globalAccuracy: mastery,
                    totalReviews: state.totalReviews,
                  ),
                  const SizedBox(height: 32),

                  // Leitner Flux
                  _HorizontalLeitnerFlux(
                    learning: state.totalLearning,
                    reviewing: state.totalReviewing,
                    mastered: state.totalMastered,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE & STREAK HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileAndStreakHeader extends StatelessWidget {
  final int streakDays;

  const _ProfileAndStreakHeader({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.adaptiveSurfaceContainer,
            context.adaptiveSurfaceContainer.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.adaptiveGlassBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryContainer, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.onPrimary, size: 32),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medical Student', style: AppTheme.headlineMd()),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniBadge(label: 'Level 1', color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    _MiniBadge(label: 'Novice', color: AppTheme.primary),
                  ],
                ),
              ],
            ),
          ),
          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: AppTheme.tertiary, size: 28),
                const SizedBox(height: 4),
                Text('$streakDays', style: AppTheme.headlineMd(color: AppTheme.tertiary).copyWith(fontWeight: FontWeight.w800, fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTheme.labelXs(color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MASTERY OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────

class _MasteryOverview extends StatelessWidget {
  final int totalMastered;
  final int globalAccuracy;
  final int totalReviews;

  const _MasteryOverview({
    required this.totalMastered,
    required this.globalAccuracy,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text('Performance Overview', style: AppTheme.headlineMd()),
        ),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Mastered',
                value: '$totalMastered',
                icon: Icons.workspace_premium_rounded,
                color: AppTheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Accuracy',
                value: '$globalAccuracy%',
                icon: Icons.track_changes_rounded,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Reviews',
                value: '$totalReviews',
                icon: Icons.history_edu_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Time Spent',
                value: '${(totalReviews * 0.05).round()}h',
                icon: Icons.timer_outlined,
                color: const Color(0xFFFFB347),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.adaptiveSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.adaptiveGlassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.arrow_outward_rounded, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3), size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: AppTheme.displayLg().copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          Text(title, style: AppTheme.labelSm()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEITNER FLUX
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalLeitnerFlux extends StatelessWidget {
  final int learning;
  final int reviewing;
  final int mastered;

  const _HorizontalLeitnerFlux({
    required this.learning,
    required this.reviewing,
    required this.mastered,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text('Leitner Pipeline', style: AppTheme.headlineMd()),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.adaptiveSurfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.adaptiveGlassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FluxNode(label: 'Learning', count: learning, color: AppTheme.error, icon: Icons.school_rounded),
                  Expanded(child: _FluxConnector(color: AppTheme.outlineVariant)),
                  _FluxNode(label: 'Reviewing', count: reviewing, color: AppTheme.primary, icon: Icons.sync_rounded),
                  Expanded(child: _FluxConnector(color: AppTheme.outlineVariant)),
                  _FluxNode(label: 'Mastered', count: mastered, color: AppTheme.tertiary, icon: Icons.workspace_premium_rounded),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.adaptiveSurfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.adaptiveGlassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Consistent reviews are pushing your knowledge toward mastery.',
                        style: AppTheme.bodyMd().copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FluxNode extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _FluxNode({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 26),
            ),
          ),
          const SizedBox(height: 12),
          Text('$count', style: AppTheme.headlineMd(color: color).copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelXs(), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _FluxConnector extends StatelessWidget {
  final Color color;
  const _FluxConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48), // Shifts the connector up to align with circles
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            color: color.withValues(alpha: 0.3),
            thickness: 2,
            indent: 8,
            endIndent: 8,
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.6), size: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SHEET (Unchanged, slightly refined UI)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Container(
      decoration: BoxDecoration(
        color: context.adaptiveSurfaceHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Settings', style: AppTheme.titleSm()),
              const SizedBox(height: 16),

              Text('Account & Profile', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                title: Text('Profile', style: AppTheme.bodyMd()),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Preferences', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined, color: AppTheme.primary),
                title: Text('Spaced Repetition Settings', style: AppTheme.bodyMd()),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BoxSettingsScreen()),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
                title: Text('Notification Settings', style: AppTheme.bodyMd()),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_rounded, color: AppTheme.error),
                title: Text('Reset All Progress', style: AppTheme.bodyMd(color: AppTheme.error)),
                subtitle: Text('Move all topics to Box 0', style: AppTheme.labelXs()),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: context.adaptiveSurfaceContainer,
                      title: const Text('Reset All Progress?'),
                      content: const Text('This will move all topics back to Box 0 (Not Viewed). This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Reset', style: AppTheme.labelSm(color: AppTheme.error)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final isar = ref.read(isarProvider);
                    final notificationService = ref.read(notificationServiceProvider);
                    await isar.writeTxn(() async {
                      final allTopics = await isar.topics.where().findAll();
                      for (final t in allTopics) {
                        t.boxNumber = 0;
                        t.isCompleted = false;
                        t.nextReviewDate = null;
                        await notificationService.cancelTopicReview(t.id);
                      }
                      await isar.topics.putAll(allTopics);
                    });

                    final user = ref.read(authStateProvider).valueOrNull;
                    if (user != null) {
                      await ref.read(syncServiceProvider).resetAllTopicProgress(user.uid);
                    }

                    ref.invalidate(syllabusProvider);
                    ref.invalidate(topicsByBoxProvider);
                    ref.invalidate(completedTopicsProvider);
                    ref.invalidate(topicsForSubjectProvider);
                    ref.invalidate(libraryReviewProvider);
                    await notificationService.scheduleDailyReviewNotification();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All progress reset to Box 0')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
