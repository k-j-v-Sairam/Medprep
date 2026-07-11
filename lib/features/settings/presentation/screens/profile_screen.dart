import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../features/study_session/domain/topic.dart';
import '../../../../features/study_session/domain/activity_log.dart';
import '../../../../features/study_session/domain/notification_log.dart';
import '../../../../features/study_session/domain/subject.dart';
import '../../../../core/providers/syllabus_state_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    
    _email = user.email ?? 'No email';
    _nameCtrl.text = user.displayName ?? '';
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['name'] != null) _nameCtrl.text = data['name'];
        if (data['phone'] != null) _phoneCtrl.text = data['phone'];
      }
    } catch (e) {
      // Offline or error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      SnackbarUtils.showError('Name and phone cannot be empty.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(name, phone);
      if (mounted) {
        SnackbarUtils.showSuccess('Profile updated successfully.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetPassword() async {
    final authService = ref.read(authServiceProvider);
    HapticFeedback.mediumImpact();
    try {
      SnackbarUtils.showSuccess('Sending password reset email...');
      await authService.sendPasswordResetEmail(_email);
      if (mounted) {
        SnackbarUtils.showSuccess('Password reset email sent to $_email.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out', style: AppTheme.labelSm(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Reset all user-specific progress in Isar
        final isar = ref.read(isarProvider);
        await isar.writeTxn(() async {
          await isar.activityLogs.clear();
          await isar.notificationLogs.clear();
          
          // Delete all custom topics (they have timestamp IDs > 1 billion)
          await isar.topics.filter().idGreaterThan(1000000000).deleteAll();

          // Delete the custom 'Self Made' subject and any of its remaining topics
          final selfMade = await isar.subjects.filter().slugEqualTo('self_made').findFirst();
          if (selfMade != null) {
            await isar.topics.filter().subjectIdEqualTo(selfMade.id).deleteAll();
            await isar.subjects.delete(selfMade.id);
          }
          
          // Reset progress for default syllabus topics
          final topics = await isar.topics.where().findAll();
          for (var topic in topics) {
            topic.boxNumber = 0;
            topic.isCompleted = false;
            topic.nextReviewDate = null;
            topic.readNotes = null;
            topic.unreadNotes = null;
            topic.importantNotes = null;
          }
          await isar.topics.putAll(topics);
        });

        // 2. Clear sync preferences so a new login does a full fresh sync
        final prefs = await SharedPreferences.getInstance();
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          await prefs.remove('last_sync_${currentUser.uid}');
          await prefs.remove('last_sync_pull_${currentUser.uid}');
        }
        await prefs.remove('is_guest');
      } catch (e) {
        // Ignore local reset errors to ensure sign out still proceeds
      }

      // 3. Invalidate global Riverpod state to prevent UI ghosting
      ref.invalidate(syllabusProvider);
      ref.invalidate(topicsByBoxProvider);
      ref.invalidate(completedTopicsProvider);
      ref.invalidate(monthlyActivityProvider);

      // 4. Sign out of Firebase
      await ref.read(authServiceProvider).signOut();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile', style: AppTheme.titleSm(color: AppTheme.onSurface)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 24),
                  _buildProfileForm(),
                  const SizedBox(height: 32),
                  _buildActions(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryContainer, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, size: 48, color: AppTheme.onPrimary),
          ),
        ),
        const SizedBox(height: 16),
        Text(_email, style: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildProfileForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCard(borderColor: context.adaptiveGlassBorder)
              .copyWith(color: context.adaptiveSurfaceContainer.withValues(alpha: 0.6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Details', style: AppTheme.titleSm()),
              const SizedBox(height: 16),
              _buildTextField('Full Name', Icons.person_outline_rounded, _nameCtrl),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', Icons.phone_outlined, _phoneCtrl, keyboard: TextInputType.phone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.onPrimary, strokeWidth: 2))
                      : Text('Save Changes', style: AppTheme.labelSm(color: AppTheme.onPrimary).copyWith(letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTheme.labelXs(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: AppTheme.bodyMd(color: AppTheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: context.adaptiveSurfaceHigh.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.adaptiveGlassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.adaptiveGlassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        _buildActionTile(
          title: 'Reset Password',
          subtitle: 'Send a reset link via email',
          icon: Icons.lock_reset_rounded,
          iconColor: AppTheme.secondary,
          onTap: _resetPassword,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          title: 'Sign Out',
          subtitle: 'Securely log out of this device',
          icon: Icons.logout_rounded,
          iconColor: AppTheme.error,
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.adaptiveSurfaceHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.adaptiveGlassBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w600, color: iconColor == AppTheme.error ? AppTheme.error : AppTheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.labelXs(color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
