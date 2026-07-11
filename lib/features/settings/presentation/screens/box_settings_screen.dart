import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';

class BoxSettingsScreen extends ConsumerWidget {
  const BoxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intervals = ref.watch(boxIntervalsProvider);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: AppBar(
        title: const Text('Spaced Repetition'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memory Algorithm',
                    style: AppTheme.displayLg().copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize how frequently you review cards at each stage of your learning journey. Expanding intervals lead to better long-term retention.',
                    style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  _BoxSettingCard(
                    boxNumber: 1,
                    title: 'Learning',
                    subtitle: 'Initial exposure to new concepts',
                    icon: Icons.school_rounded,
                    iconColor: AppTheme.error,
                    currentDays: intervals[0],
                    isLocked: true,
                  ),
                  const SizedBox(height: 16),
                  _BoxSettingCard(
                    boxNumber: 2,
                    title: 'Familiarizing',
                    subtitle: 'Short-term reinforcement',
                    icon: Icons.psychology_alt_rounded,
                    iconColor: Colors.orange,
                    currentDays: intervals[1],
                  ),
                  const SizedBox(height: 16),
                  _BoxSettingCard(
                    boxNumber: 3,
                    title: 'Retaining',
                    subtitle: 'Medium-term memory',
                    icon: Icons.memory_rounded,
                    iconColor: AppTheme.tertiary,
                    currentDays: intervals[2],
                  ),
                  const SizedBox(height: 16),
                  _BoxSettingCard(
                    boxNumber: 4,
                    title: 'Mastering',
                    subtitle: 'Long-term consolidation',
                    icon: Icons.verified_rounded,
                    iconColor: AppTheme.secondary,
                    currentDays: intervals[3],
                  ),
                  const SizedBox(height: 16),
                  _BoxSettingCard(
                    boxNumber: 5,
                    title: 'Expertise',
                    subtitle: 'Permanent knowledge retention',
                    icon: Icons.workspace_premium_rounded,
                    iconColor: AppTheme.primary,
                    currentDays: intervals[4],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxSettingCard extends ConsumerStatefulWidget {
  final int boxNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final int currentDays;
  final bool isLocked;

  const _BoxSettingCard({
    required this.boxNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.currentDays,
    this.isLocked = false,
  });

  @override
  ConsumerState<_BoxSettingCard> createState() => _BoxSettingCardState();
}

class _BoxSettingCardState extends ConsumerState<_BoxSettingCard> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDays.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _save();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _BoxSettingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDays != widget.currentDays && !_focusNode.hasFocus) {
      _controller.text = widget.currentDays.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.isLocked) return;
    final text = _controller.text;
    final days = int.tryParse(text);
    if (days != null && days > 0) {
      if (days != widget.currentDays) {
        ref.read(boxIntervalsProvider.notifier).updateInterval(widget.boxNumber, days);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phase ${widget.boxNumber} interval updated to $days days'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Revert to current days if invalid
      _controller.text = widget.currentDays.toString();
    }
  }

  void _increment() {
    if (widget.isLocked) return;
    final current = int.tryParse(_controller.text) ?? widget.currentDays;
    _controller.text = (current + 1).toString();
    _save();
  }

  void _decrement() {
    if (widget.isLocked) return;
    final current = int.tryParse(_controller.text) ?? widget.currentDays;
    if (current > 1) {
      _controller.text = (current - 1).toString();
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(
        tintColor: widget.iconColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Box ${widget.boxNumber} • ', style: AppTheme.labelSm(color: widget.iconColor)),
                        Expanded(child: Text(widget.title, style: AppTheme.titleSm())),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (widget.isLocked)
                Icon(Icons.lock_outline_rounded, color: AppTheme.onSurfaceVariant, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Review Interval', style: AppTheme.labelSm()),
              if (widget.isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.adaptiveSurfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${widget.currentDays} Day', style: AppTheme.titleSm()),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepperButton(Icons.remove_rounded, _decrement, context),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTheme.titleSm(),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                          filled: true,
                          fillColor: context.adaptiveSurfaceHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: widget.iconColor, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStepperButton(Icons.add_rounded, _increment, context),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap, BuildContext context) {
    return Material(
      color: context.adaptiveSurfaceHigh,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, size: 20, color: AppTheme.onSurface),
        ),
      ),
    );
  }
}
