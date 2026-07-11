import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/box_ui_helper.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../../../core/widgets/skeleton_loading_widget.dart';
import 'package:akpa/features/vault/presentation/screens/vault_screen.dart';
import 'topic_box_move_screen.dart';
import '../../application/arena_providers.dart';
import '../../application/topic_controller.dart';
import 'arena_study_screen.dart';

class ArenaTabScreen extends ConsumerStatefulWidget {
  const ArenaTabScreen({super.key});
  @override
  ConsumerState<ArenaTabScreen> createState() => _ArenaTabScreenState();
}

class _ArenaTabScreenState extends ConsumerState<ArenaTabScreen> {
  int _selectedBox = 0;
  final TextEditingController _searchController = TextEditingController();
  
  // Selection mode state
  bool _isSelectionMode = false;
  final Set<int> _selectedTopicIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pushMoveScreen(BuildContext context, TopicWithSubjectViewModel entry) {
    if (_isSelectionMode) {
      _toggleSelection(entry.topic.id);
      return;
    }
    
    HapticFeedback.lightImpact();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => TopicBoxMoveScreen(
        topicId: entry.topic.id,
        topicName: entry.topic.name,
        subjectName: entry.subject.name,
        accentColor: entry.subject.accentColor,
        currentBoxNumber: entry.topic.boxNumber,
        isDirectMove: true,
      ),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  void _toggleSelection(int topicId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTopicIds.contains(topicId)) {
        _selectedTopicIds.remove(topicId);
        if (_selectedTopicIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTopicIds.add(topicId);
      }
    });
  }

  // --- Fast actions ---



  Future<void> _undoMove(int topicId, int oldBox, DateTime? oldDate) async {
    await ref.read(topicControllerProvider).undoMove(topicId, oldBox, oldDate);
  }

  Future<void> _batchMove(int destBox) async {
    final topicsToMove = _selectedTopicIds.toList();
    await ref.read(topicControllerProvider).batchMove(topicsToMove, destBox);
    
    setState(() {
      _isSelectionMode = false;
      _selectedTopicIds.clear();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved ${topicsToMove.length} topics to Box $destBox')),
    );
  }

  void _showBatchMoveDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Move to...', style: AppTheme.headlineMd()),
              ),
              for (int i = 0; i <= 5; i++)
                ListTile(
                  leading: Icon(Icons.inbox, color: i.toBoxColor()),
                  title: Text('Box $i', style: AppTheme.bodyMd()),
                  onTap: () {
                    Navigator.pop(ctx);
                    _batchMove(i);
                  },
                ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicsByBoxAsync = ref.watch(topicsByBoxProvider);
    final filteredTopics = ref.watch(filteredArenaTopicsProvider(_selectedBox));

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      floatingActionButton: topicsByBoxAsync.whenOrNull(
        data: (boxMap) {
          if (_isSelectionMode) return null; // Hide FAB in selection mode
          
          // Calculate due topics
          int dueCount = 0;
          final List<TopicWithSubjectViewModel> dueTopicsList = [];
          for (int b = 1; b <= 5; b++) {
            final topicsInBox = boxMap[b] ?? [];
            for (var t in topicsInBox) {
              if (t.topic.isDueToday) {
                dueCount++;
                dueTopicsList.add(t);
              }
            }
          }
          
          if (dueCount == 0) return null;
          
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, a, __) => ArenaStudyScreen(dueTopics: dueTopicsList),
                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              ));
            },
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.play_arrow_rounded, color: AppTheme.onPrimary),
            label: Text('Study $dueCount Due', style: AppTheme.titleSm(color: AppTheme.onPrimary)),
          );
        }
      ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.surfaceContainer,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: context.adaptiveOnSurfaceVariant),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedTopicIds.clear();
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        '${_selectedTopicIds.length} selected',
                        style: AppTheme.titleSm(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.drive_file_move_rounded, color: AppTheme.primary),
                      label: Text('Move', style: AppTheme.labelSm(color: AppTheme.primary)),
                      onPressed: _showBatchMoveDialog,
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: topicsByBoxAsync.when(
        loading: () => Scaffold(
          backgroundColor: context.adaptiveBackground,
          body: const SafeArea(child: ArenaSkeletonWidget()),
        ),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (boxMap) {
          return Stack(
            children: [
              // Ambient glow
              Positioned(
                top: -80, left: 0, right: 0,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.0,
                      colors: [
                        _selectedBox.toBoxColor().withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(topicsByBoxProvider);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // ── AppBar ────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Arena', style: AppTheme.displayLg()),
                                  Text(
                                    'Leitner Box System',
                                    style: AppTheme.bodyMd(color: context.adaptiveOnSurfaceVariant),
                                  ),
                                ],
                              ),
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
                          ],
                        ),
                      ),
                    ),
                    
                    // ── Arena Stats Header ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _ArenaStatsHeader(boxMap: boxMap),
                      ),
                    ),

                    // ── Box Selector Row ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: _BoxSelectorRow(
                          boxMap: boxMap,
                          selectedBox: _selectedBox,
                          onSelect: (box) {
                             _searchController.clear();
                             ref.read(arenaSearchQueryProvider.notifier).state = '';
                             ref.read(arenaSelectedSubjectsProvider.notifier).state = {};
                             setState(() {
                               _selectedBox = box;
                               _isSelectionMode = false;
                               _selectedTopicIds.clear();
                             });
                          },
                        ),
                      ),
                    ),

                    // ── Subject Filter Row ────────────────────────────────
                    Builder(
                      builder: (context) {
                        final topicsInBox = boxMap[_selectedBox] ?? [];
                        final uniqueSubjects = <SubjectViewModel>[];
                        final seenIds = <int>{};
                        for (final t in topicsInBox) {
                          if (!seenIds.contains(t.subject.id)) {
                            uniqueSubjects.add(t.subject);
                            seenIds.add(t.subject.id);
                          }
                        }

                        if (uniqueSubjects.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                        return SliverToBoxAdapter(
                          child: SizedBox(
                            height: 48,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: uniqueSubjects.length,
                              itemBuilder: (context, index) {
                                final subject = uniqueSubjects[index];
                                final isSelected = ref.watch(arenaSelectedSubjectsProvider).contains(subject.id);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: FilterChip(
                                    label: Text(subject.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      final current = ref.read(arenaSelectedSubjectsProvider);
                                      if (selected) {
                                        ref.read(arenaSelectedSubjectsProvider.notifier).state = {...current, subject.id};
                                      } else {
                                        ref.read(arenaSelectedSubjectsProvider.notifier).state = current.where((id) => id != subject.id).toSet();
                                      }
                                    },
                                    backgroundColor: AppTheme.surfaceContainer,
                                    selectedColor: subject.accentColor.withValues(alpha: 0.2),
                                    checkmarkColor: subject.accentColor,
                                    labelStyle: AppTheme.labelSm(
                                      color: isSelected ? subject.accentColor : context.adaptiveOnSurfaceVariant,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? subject.accentColor : AppTheme.glassBorder,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    ),

                    // ── Search & Sort Bar ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: AppTheme.bodyMd(),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Search topics...',
                                  hintStyle: AppTheme.labelSm(color: context.adaptiveOnSurfaceVariant),
                                  prefixIcon: Icon(Icons.search_rounded, color: context.adaptiveOnSurfaceVariant),
                                  suffixIcon: ref.watch(arenaSearchQueryProvider).isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear_rounded, size: 20, color: context.adaptiveOnSurfaceVariant),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(arenaSearchQueryProvider.notifier).state = '';
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: AppTheme.surfaceContainer.withValues(alpha: 0.5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: AppTheme.glassBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: AppTheme.glassBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: AppTheme.primary),
                                  ),
                                ),
                                onChanged: (val) => ref.read(arenaSearchQueryProvider.notifier).state = val,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: PopupMenuButton<TopicSortMode>(
                                icon: Icon(Icons.sort_rounded, color: context.adaptiveOnSurfaceVariant),
                                tooltip: 'Sort Topics',
                                initialValue: ref.watch(arenaSortModeProvider),
                                color: AppTheme.surfaceContainer,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (mode) => ref.read(arenaSortModeProvider.notifier).state = mode,
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: TopicSortMode.dueSoonest,
                                    child: Text('Due Soonest'),
                                  ),
                                  const PopupMenuItem(
                                    value: TopicSortMode.dueLatest,
                                    child: Text('Due Latest'),
                                  ),
                                  const PopupMenuItem(
                                    value: TopicSortMode.alphabetical,
                                    child: Text('Alphabetical (A-Z)'),
                                  ),
                                  const PopupMenuItem(
                                    value: TopicSortMode.reverseAlphabetical,
                                    child: Text('Reverse Alphabetical (Z-A)'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Selected Box Info Card ────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _BoxInfoCard(boxNumber: _selectedBox),
                      ),
                    ),

                    // ── Topic List for selected box ───────────────────────
                    Builder(builder: (context) {
                      if (filteredTopics.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: _selectedBox.toBoxColor().withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.inbox_outlined,
                                        color: _selectedBox.toBoxColor(), size: 32),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    ref.watch(arenaSearchQueryProvider).isNotEmpty
                                        ? 'No matching topics found'
                                        : 'Box $_selectedBox is empty',
                                    style: AppTheme.headlineMd(),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedBox == 0
                                        ? 'Start studying new topics to move them to higher boxes.'
                                        : _selectedBox == 1
                                            ? 'Complete topics to place them here.'
                                            : 'Review topics in Box ${_selectedBox - 1} to advance them here.',
                                    style: AppTheme.bodyMd(color: context.adaptiveOnSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  if (ref.watch(arenaSearchQueryProvider).isEmpty)
                                    OutlinedButton(
                                      onPressed: () {
                                        if (_selectedBox == 0) {
                                          // Note: Navigating to syllabus could be complex without context of tabs
                                          // Easiest is to show a snackbar or just reset to box 0 if not 0
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Go to Syllabus tab to add topics!'))
                                          );
                                        } else {
                                          setState(() => _selectedBox = 0);
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primary,
                                        side: BorderSide(color: AppTheme.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(_selectedBox == 0 ? 'Go to Syllabus' : 'View Box 0'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final entry = filteredTopics[i];
                              final isSelected = _selectedTopicIds.contains(entry.topic.id);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Dismissible(
                                  key: ValueKey(entry.topic.id),
                                  direction: DismissDirection.horizontal,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Icon(Icons.drive_file_move_rounded, color: AppTheme.primary),
                                  ),
                                  secondaryBackground: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.drive_file_move_rounded, color: AppTheme.primary),
                                  ),
                                  confirmDismiss: (dir) async {
                                    _pushMoveScreen(context, entry);
                                    return false; // Prevent widget dismissal as state update handles it
                                  },
                                  child: GestureDetector(
                                    onTap: () => _pushMoveScreen(context, entry),
                                    onLongPress: () {
                                      HapticFeedback.heavyImpact();
                                      setState(() {
                                        _isSelectionMode = true;
                                        _selectedTopicIds.add(entry.topic.id);
                                      });
                                    },
                                    child: _ArenaTopicTile(
                                      entry: entry,
                                      isSelected: isSelected,
                                      isSelectionMode: _isSelectionMode,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: filteredTopics.length,
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
// ARENA STATS HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ArenaStatsHeader extends StatelessWidget {
  final Map<int, List<TopicWithSubjectViewModel>> boxMap;
  const _ArenaStatsHeader({required this.boxMap});

  @override
  Widget build(BuildContext context) {
    int total = 0;
    for (int i = 0; i <= 5; i++) {
      total += boxMap[i]?.length ?? 0;
    }
    
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mastery Progress', style: AppTheme.labelSm(color: context.adaptiveOnSurfaceVariant)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                for (int i = 0; i <= 5; i++)
                  if ((boxMap[i]?.length ?? 0) > 0)
                    Expanded(
                      flex: boxMap[i]!.length,
                      child: Container(
                        color: i.toBoxColor(),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOX SELECTOR ROW
// ─────────────────────────────────────────────────────────────────────────────

class _BoxSelectorRow extends StatelessWidget {
  final Map<int, List<TopicWithSubjectViewModel>> boxMap;
  final int selectedBox;
  final void Function(int) onSelect;

  const _BoxSelectorRow({
    super.key,
    required this.boxMap,
    required this.selectedBox,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        final box = i;
        final count = boxMap[box]?.length ?? 0;
        final isSelected = box == selectedBox;
        final color = box.toBoxColor();

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(box);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.surfaceContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color.withValues(alpha: 0.6) : AppTheme.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12)]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(box.toBoxEmoji(), style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: AppTheme.headlineMd(
                      color: isSelected ? color : context.adaptiveOnSurface,
                    ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Box $box',
                    style: AppTheme.labelXs(
                      color: isSelected ? color : context.adaptiveOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOX INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BoxInfoCard extends StatelessWidget {
  final int boxNumber;
  const _BoxInfoCard({super.key, required this.boxNumber});

  String get _interval {
    if (boxNumber == 0) return 'Not yet viewed';
    const intervals = ['1 day', '3 days', '7 days', '14 days', '30 days'];
    return intervals[(boxNumber.clamp(1, 5)) - 1];
  }

  String get _description {
    switch (boxNumber) {
      case 0: return 'New topics that you have never viewed.';
      case 1: return 'New or struggling topics — review every day';
      case 2: return 'Building familiarity — review every 3 days';
      case 3: return 'Progressing well — review weekly';
      case 4: return 'Strong retention — review bi-weekly';
      case 5: return 'Mastered — review monthly to maintain';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = boxNumber.toBoxColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_outlined, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review interval: $_interval',
                      style: AppTheme.titleSm(color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _description,
                      style: AppTheme.labelSm(color: context.adaptiveOnSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARENA TOPIC TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ArenaTopicTile extends StatelessWidget {
  final TopicWithSubjectViewModel entry;
  final bool isSelectionMode;
  final bool isSelected;

  const _ArenaTopicTile({required this.entry,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final topic = entry.topic;
    final subject = entry.subject;
    final daysLabel = _daysLabel(topic.daysUntilDue);
    final daysColor = _daysColor(topic.daysUntilDue);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected 
                ? subject.accentColor.withValues(alpha: 0.15) 
                : AppTheme.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? subject.accentColor : AppTheme.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? subject.accentColor : AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
              ] else ...[
                // Subject accent bar
                Container(
                  width: 3, height: 44,
                  decoration: BoxDecoration(
                    color: subject.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Subject icon
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: subject.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(subject.iconData, color: subject.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.description.isNotEmpty && topic.description != topic.name
                          ? '${topic.name} - ${topic.description}'
                          : topic.name,
                      style: AppTheme.titleSm(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: subject.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subject.name,
                        style: AppTheme.labelXs(color: subject.accentColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Due date + review arrow
              if (subject.slug != 'self_made')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(daysLabel, style: AppTheme.labelXs(color: daysColor)),
                    const SizedBox(height: 6),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: subject.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: subject.accentColor, size: 14),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _daysLabel(int days) {
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due today';
    return 'In $days d';
  }

  Color _daysColor(int days) {
    if (days < 0) return AppTheme.error;
    if (days == 0) return const Color(0xFFFFB74D);
    return AppTheme.onSurfaceVariant;
  }
}
