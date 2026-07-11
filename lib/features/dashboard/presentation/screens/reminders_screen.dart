import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../study_session/domain/notification_log.dart';

class NotificationHistoryState {
  final List<NotificationLog> logs;
  
  NotificationHistoryState(this.logs);
}

final selectedFilterProvider = StateProvider<String>((ref) => 'All');

final notificationHistoryProvider = FutureProvider<NotificationHistoryState>((ref) async {
  final isar = ref.watch(isarProvider);
  final filter = ref.watch(selectedFilterProvider);
  final now = DateTime.now();

  var query = isar.notificationLogs.filter().timestampLessThan(now);

  if (filter != 'All') {
    query = query.typeEqualTo(filter);
  }

  final logs = await query.sortByTimestampDesc().findAll();

  return NotificationHistoryState(logs);
});

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(notificationHistoryProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Notification History', style: AppTheme.titleSm()),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _buildFilterChip(context, ref, 'All', selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Subject Review', selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Countdown', selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Repetitive Flow', selectedFilter),
              ],
            ),
          ),
          
          Expanded(
            child: stateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (state) {
                if (state.logs.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications found.',
                      style: AppTheme.titleSm(color: AppTheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.logs.length,
                  itemBuilder: (context, index) {
                    final log = state.logs[index];
                    return _buildLogTile(log, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, String selectedFilter) {
    final isSelected = label == selectedFilter;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(selectedFilterProvider.notifier).state = label;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : (Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceHighest.withValues(alpha: 0.3) : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelSm(
            color: isSelected ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
          ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildLogTile(NotificationLog log, BuildContext context) {
    IconData icon;
    Color color;

    switch (log.type) {
      case 'Subject Review':
        icon = Icons.menu_book_rounded;
        color = AppTheme.primary;
        break;
      case 'Countdown':
        icon = Icons.timer_rounded;
        color = AppTheme.secondary;
        break;
      case 'Repetitive Flow':
        icon = Icons.repeat_rounded;
        color = AppTheme.tertiary;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppTheme.onSurfaceVariant;
    }

    final format = DateFormat('MMM d, hh:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  style: AppTheme.titleSm(),
                ),
                const SizedBox(height: 4),
                Text(
                  log.body,
                  style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  format.format(log.timestamp),
                  style: AppTheme.labelXs(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
