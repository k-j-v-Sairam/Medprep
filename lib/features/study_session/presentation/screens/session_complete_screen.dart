import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/notification_service.dart';

class SessionCompleteScreen extends ConsumerStatefulWidget {
  final int topicsReviewed;
  final int correct;
  final int again;
  final String timeLabel;
  final int streakDays;

  const SessionCompleteScreen({
    super.key,
    required this.topicsReviewed,
    required this.correct,
    required this.again,
    required this.timeLabel,
    required this.streakDays,
  });

  @override
  ConsumerState<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends ConsumerState<SessionCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _ctrl.forward();
    
    // Reschedule notifications since review counts changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).scheduleDailyReviewNotification();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpGained = widget.correct * 5 + widget.topicsReviewed * 2;
    final xpProgress = (widget.correct / (widget.topicsReviewed.clamp(1, 9999))).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const SizedBox.shrink(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology_outlined, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('MedPrep',
                style: AppTheme.titleSm(color: AppTheme.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Opacity(
              opacity: _fadeIn.value,
              child: Transform.translate(
                offset: Offset(0, _slideUp.value),
                child: child,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    // ── Check Hero ─────────────────────────────────────
                    AnimatedBuilder(
                      animation: _scaleIn,
                      builder: (_, child) =>
                          Transform.scale(scale: _scaleIn.value, child: child),
                      child: Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: AppTheme.primary, size: 44),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Session Complete!',
                        style: AppTheme.displayLg(color: AppTheme.onSurface)),
                    const SizedBox(height: 8),
                    Text(
                      'You reviewed ${widget.topicsReviewed} topics',
                      style: AppTheme.bodyMd(),
                    ),
                    const SizedBox(height: 32),

                    // ── 4-stat grid ────────────────────────────────────
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _StatTile(
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppTheme.tertiary,
                          value: '${widget.correct}',
                          label: 'CORRECT',
                        ),
                        _StatTile(
                          icon: Icons.refresh_rounded,
                          iconColor: AppTheme.error,
                          value: '${widget.again}',
                          label: 'AGAIN',
                        ),
                        _StatTile(
                          icon: Icons.timer_outlined,
                          iconColor: AppTheme.secondary,
                          value: widget.timeLabel,
                          label: 'TIME',
                        ),
                        _StatTile(
                          icon: Icons.local_fire_department_outlined,
                          iconColor: const Color(0xFFFFB347),
                          value: '${widget.streakDays} Days',
                          label: 'STREAK',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── XP Bar ─────────────────────────────────────────
                    _XpBar(xpGained: xpGained, progress: xpProgress),
                    const SizedBox(height: 36),

                    // ── CTA Buttons ────────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryContainer, AppTheme.primary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Continue Studying',
                            style: AppTheme.titleSm(color: AppTheme.onPrimary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // Pop back to syllabus (2 levels: session + topic)
                        Navigator.of(context)
                          ..pop()
                          ..pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Center(
                          child: Text('Back to Syllabus',
                              style: AppTheme.titleSm()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT TILE
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCard(
            tintColor: iconColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const Spacer(),
              Text(value,
                  style: AppTheme.displayLg(color: AppTheme.onSurface)
                      .copyWith(fontSize: 28)),
              const SizedBox(height: 2),
              Text(label, style: AppTheme.labelXs()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  final int xpGained;
  final double progress;
  const _XpBar({required this.xpGained, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: AppTheme.glassCard(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Text('XP GAINED',
                          style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                  Text('+$xpGained',
                      style: AppTheme.headlineMd(color: AppTheme.onSurface)
                          .copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceHighest,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level 14', style: AppTheme.labelSm()),
                  Text('Level 15', style: AppTheme.labelSm()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
