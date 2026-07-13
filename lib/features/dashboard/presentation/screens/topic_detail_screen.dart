import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/syllabus_state_provider.dart';
import '../../../../core/utils/box_ui_helper.dart';
import '../../../../core/widgets/skeleton_loading_widget.dart';
import 'package:akpa/features/vault/presentation/screens/vault_screen.dart';
import '../widgets/topic_notes_sheet.dart';
import '../../../../core/theme/app_theme.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final SubjectViewModel subject;
  const TopicDetailScreen({super.key, required this.subject});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTopicDialog(BuildContext context, SubjectViewModel subject) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add Custom Topic', style: AppTheme.headlineMd()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: AppTheme.bodyMd(),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Topic Name',
                  labelStyle: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: subject.accentColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: AppTheme.bodyMd(),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: subject.accentColor)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(syllabusProvider.notifier).addTopic(
                    topicName: name,
                    description: desc.isNotEmpty ? desc : null,
                    subjectId: subject.id,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: subject.accentColor,
                foregroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch live state to reflect toggle changes
    final state = ref.watch(syllabusProvider);
    final topicsAsync = ref.watch(topicsForSubjectProvider(widget.subject.id));
    
    final liveSubject = state.valueOrNull?.subjects.where((s) => s.id == widget.subject.id).firstOrNull ?? widget.subject;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTopicDialog(context, liveSubject),
        backgroundColor: liveSubject.accentColor,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded, color: AppTheme.background),
        label: const Text('Add Topic', style: TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.onSurface, size: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: liveSubject.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(liveSubject.name.toUpperCase(),
                    style: AppTheme.labelSm(color: liveSubject.accentColor)),
              ],
            ),
            Text('Topics', style: AppTheme.titleSm()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.onSurfaceVariant),
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
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -60, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    liveSubject.accentColor.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: topicsAsync.when(
              loading: () => const TopicListSkeletonWidget(),
              error: (err, st) => Center(child: Text('Error: $err')),
              data: (topics) {
                if (topics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No topics yet', style: AppTheme.headlineMd()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Search Bar ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: TextField(
                          controller: _searchController,
                          style: AppTheme.bodyMd(),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search topics...',
                            hintStyle: AppTheme.labelSm(color: AppTheme.onSurfaceVariant),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.onSurfaceVariant),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20, color: AppTheme.onSurfaceVariant),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
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
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                    ),
                    Builder(builder: (context) {
                      var filteredTopics = topics;
                      if (_searchQuery.trim().isNotEmpty) {
                        final q = _searchQuery.trim().toLowerCase();
                        filteredTopics = topics.where((t) => t.name.toLowerCase().contains(q)).toList();
                      }

                      if (filteredTopics.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                            child: Center(
                              child: Text(
                                'No topics found.',
                                style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final topic = filteredTopics[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _TopicCard(
                                topic: topic,
                                accentColor: liveSubject.accentColor,
                              ),
                            );
                          },
                          childCount: filteredTopics.length,
                        ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPIC CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final TopicViewModel topic;
  final Color accentColor;

  const _TopicCard({
    required this.topic,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUnviewed = topic.boxNumber == 0;
    final cardColor = isUnviewed ? AppTheme.glassBorder : topic.boxNumber.toBoxColor(defaultColor: accentColor).withValues(alpha: 0.3);
    final shadowColor = isUnviewed ? Colors.transparent : topic.boxNumber.toBoxColor(defaultColor: accentColor).withValues(alpha: 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TopicNotesSheet(
                  topic: topic,
                  accentColor: accentColor,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardColor),
                boxShadow: [
                  if (!isUnviewed)
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 20,
                    )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            topic.description.isNotEmpty && topic.description != topic.name
                                ? '${topic.name} - ${topic.description}'
                                : topic.name,
                            style: AppTheme.headlineMd(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (topic.readNotes != null || topic.unreadNotes != null || topic.importantNotes != null)
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: Icon(Icons.sticky_note_2_outlined, size: 18, color: AppTheme.onSurfaceVariant),
                           ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBoxStatusUI(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxStatusUI() {
    final color = topic.boxNumber.toBoxColor(defaultColor: accentColor);
    final isUnviewed = topic.boxNumber == 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnviewed ? AppTheme.surfaceHighest : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnviewed ? AppTheme.outlineVariant : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUnviewed ? Icons.inbox_outlined : Icons.inbox_rounded,
            color: isUnviewed ? AppTheme.onSurfaceVariant : color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isUnviewed ? 'Unviewed' : (topic.boxNumber == 5 ? 'Mastered' : 'Box ${topic.boxNumber}'),
            style: AppTheme.labelSm(color: isUnviewed ? AppTheme.onSurfaceVariant : color),
          ),
          const Spacer(),
          // 5-segment indicator
          Row(
            children: List.generate(5, (index) {
              int step = index + 1;
              bool isActive = step <= topic.boxNumber;
              return Container(
                margin: const EdgeInsets.only(left: 4),
                height: 6,
                width: 16,
                decoration: BoxDecoration(
                  color: isActive ? step.toBoxColor(defaultColor: accentColor) : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}
