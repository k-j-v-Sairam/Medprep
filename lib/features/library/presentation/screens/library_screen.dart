import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/box_ui_helper.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../application/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final topicsAsync = ref.watch(libraryTopicsProvider);
    final syllabusAsync = ref.watch(syllabusProvider);
    
    final subjects = syllabusAsync.valueOrNull?.subjects ?? [];
    
    final selectedSubject = ref.watch(librarySelectedSubjectProvider);
    final selectedBox = ref.watch(librarySelectedBoxProvider);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glow
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
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Library',
                      style: AppTheme.displayLg(
                        color: context.adaptiveSurfaceContainer == Colors.white 
                            ? Colors.black87 
                            : AppTheme.onSurface,
                      ),
                    ),
                  ),
                ),
                
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      controller: _searchController,
                      style: AppTheme.bodyMd(color: isDark ? AppTheme.onSurface : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search topics...',
                        hintStyle: AppTheme.bodyMd(color: isDark ? AppTheme.onSurfaceVariant.withValues(alpha: 0.7) : Colors.black54),
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary.withValues(alpha: 0.8)),
                        suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 20, color: isDark ? AppTheme.onSurfaceVariant : Colors.black54),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(librarySearchQueryProvider.notifier).state = '';
                          },
                        ) : null,
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
                      onChanged: (val) {
                        ref.read(librarySearchQueryProvider.notifier).state = val;
                      },
                    ),
                  ),
                ),
                
                // Box Filters
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChip(
                          label: 'All Boxes',
                          isSelected: selectedBox == null,
                          onTap: () => ref.read(librarySelectedBoxProvider.notifier).state = null,
                        ),
                        for (int i = 0; i <= 5; i++)
                          _FilterChip(
                            label: 'Box $i',
                            isSelected: selectedBox == i,
                            color: i.toBoxColor(),
                            onTap: () => ref.read(librarySelectedBoxProvider.notifier).state = i,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Subject Filters
                if (subjects.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _FilterChip(
                            label: 'All Subjects',
                            isSelected: selectedSubject == null,
                            onTap: () => ref.read(librarySelectedSubjectProvider.notifier).state = null,
                          ),
                          for (final subject in subjects)
                            _FilterChip(
                              label: subject.name,
                              isSelected: selectedSubject == subject.id,
                              color: subject.accentColor,
                              onTap: () => ref.read(librarySelectedSubjectProvider.notifier).state = subject.id,
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Topics List
                topicsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text('No topics found', style: AppTheme.titleSm(color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            return _LibraryTopicCard(item: item);
                          },
                          childCount: items.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, st) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final activeColor = color ?? AppTheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1) : context.adaptiveSurfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : context.adaptiveGlassBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.labelSm(
              color: isSelected ? (isDark ? activeColor : activeColor.withValues(alpha: 0.8)) : AppTheme.onSurfaceVariant,
            ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }
}

class _LibraryTopicCard extends StatelessWidget {
  final LibraryItemViewModel item;

  const _LibraryTopicCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final topic = item.topic;
    final subject = item.subject;
    final boxColor = topic.boxNumber.toBoxColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.adaptiveSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.adaptiveGlassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Subject Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: subject.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(subject.iconData, color: subject.accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subject.name,
                    style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: topic.isCompleted ? AppTheme.primaryContainer.withValues(alpha: 0.3) : AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: topic.isCompleted ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.error.withValues(alpha: 0.3),
                    )
                  ),
                  child: Text(
                    topic.isCompleted ? 'Completed' : 'New',
                    style: AppTheme.labelSm(
                      color: topic.isCompleted ? AppTheme.primary : AppTheme.error,
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              topic.name,
              style: AppTheme.titleSm(color: AppTheme.onSurface).copyWith(fontSize: 16),
            ),
            if (topic.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                topic.description,
                style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Box Indicator
                Row(
                  children: [
                    Icon(Icons.inbox_rounded, size: 16, color: boxColor),
                    const SizedBox(width: 6),
                    Text(
                      'Box ${topic.boxNumber}',
                      style: AppTheme.labelSm(color: boxColor).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Next Review Date
                if (topic.isCompleted)
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        topic.daysUntilDue <= 0
                            ? 'Due Today'
                            : 'Due in ${topic.daysUntilDue} days',
                        style: AppTheme.labelSm(
                          color: topic.daysUntilDue <= 0 ? AppTheme.error : AppTheme.onSurfaceVariant,
                        ).copyWith(
                          fontWeight: topic.daysUntilDue <= 0 ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

