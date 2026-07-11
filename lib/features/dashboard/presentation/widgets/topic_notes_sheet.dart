import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/syllabus_state_provider.dart';

class TopicNotesSheet extends ConsumerStatefulWidget {
  final TopicViewModel topic;
  final Color accentColor;

  const TopicNotesSheet({
    super.key,
    required this.topic,
    required this.accentColor,
  });

  @override
  ConsumerState<TopicNotesSheet> createState() => _TopicNotesSheetState();
}

class _TopicNotesSheetState extends ConsumerState<TopicNotesSheet> {
  late TextEditingController _readNotesController;
  late TextEditingController _unreadNotesController;
  late TextEditingController _importantNotesController;

  @override
  void initState() {
    super.initState();
    _readNotesController = TextEditingController(text: widget.topic.readNotes);
    _unreadNotesController = TextEditingController(text: widget.topic.unreadNotes);
    _importantNotesController = TextEditingController(text: widget.topic.importantNotes);
  }

  @override
  void dispose() {
    _readNotesController.dispose();
    _unreadNotesController.dispose();
    _importantNotesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    HapticFeedback.mediumImpact();
    ref.read(syllabusProvider.notifier).updateTopicNotes(
      widget.topic.id,
      _readNotesController.text.trim().isEmpty ? null : _readNotesController.text.trim(),
      _unreadNotesController.text.trim().isEmpty ? null : _unreadNotesController.text.trim(),
      _importantNotesController.text.trim().isEmpty ? null : _importantNotesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: AppTheme.glassHighlight, width: 1.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.topic.name,
                          style: AppTheme.headlineMd(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your personal notes for this topic.',
                    style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Notes fields wrapped in a scrollable area in case of small screens
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            label: 'What I have read',
                            controller: _readNotesController,
                            icon: Icons.menu_book_rounded,
                            accentColor: widget.accentColor,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'What I have not read',
                            controller: _unreadNotesController,
                            icon: Icons.bookmark_border_rounded,
                            accentColor: widget.accentColor,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Important Points',
                            controller: _importantNotesController,
                            icon: Icons.star_rounded,
                            accentColor: widget.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Save Button
                  ElevatedButton(
                    onPressed: _saveNotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Notes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accentColor.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.labelSm(color: accentColor)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTheme.bodyMd(),
          maxLines: null,
          minLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Tap to add notes...',
            hintStyle: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppTheme.surfaceHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
