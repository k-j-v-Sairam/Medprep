import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/syllabus_state_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SYNAPSE ACTIVITY WIDGET (shared)
//
// 28-day activity heatmap grid + streak badge.
// Extracted from MasteryScreen so it can be used on the Dashboard too.
// ─────────────────────────────────────────────────────────────────────────────

class SynapseActivityWidget extends ConsumerWidget {
  final int streakDays;
  const SynapseActivityWidget({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(monthlyActivityProvider);

    return activityAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (Map<DateTime, int> logs) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        int maxCards = 1;
        for (final count in logs.values) {
          if (count > maxCards) maxCards = count;
        }

        final activityData = List.generate(28, (i) {
          final date = today.subtract(Duration(days: 27 - i));
          final cards = logs[date] ?? 0;
          if (cards == 0) return 0;
          return (cards / maxCards * 3).ceil().clamp(0, 3) + 1; // 1 to 4
        });
        final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Synapse Activity', style: AppTheme.titleSm()),
                          Text('Past 28 Days', style: AppTheme.labelSm()),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_outlined,
                                color: Color(0xFFFFB347), size: 14),
                            const SizedBox(width: 4),
                            Text('$streakDays Day Streak',
                                style: AppTheme.labelSm(color: AppTheme.onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Day labels
                  Row(
                    children: dayLabels.map((d) {
                      return Expanded(
                        child: Center(
                          child: Text(d, style: AppTheme.labelXs()),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: 28,
                    itemBuilder: (_, i) {
                      final intensity = activityData[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: _intensityColor(intensity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('REST', style: AppTheme.labelXs()),
                      const SizedBox(width: 6),
                      ...List.generate(4, (i) => Container(
                        width: 12, height: 12,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          color: _intensityColor(i),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                      const SizedBox(width: 6),
                      Text('PEAK', style: AppTheme.labelXs()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _intensityColor(int level) {
    switch (level) {
      case 0: return AppTheme.surfaceHighest;
      case 1: return AppTheme.primary.withValues(alpha: 0.25);
      case 2: return AppTheme.primary.withValues(alpha: 0.45);
      case 3: return AppTheme.primary.withValues(alpha: 0.70);
      case 4: return AppTheme.primary;
      default: return AppTheme.surfaceHighest;
    }
  }
}
