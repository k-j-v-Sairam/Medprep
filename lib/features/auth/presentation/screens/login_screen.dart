import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  bool _obscure       = true;
  bool _isLoading     = false;
  bool _isSignUp      = false;
  String? _errorMsg;

  late final AnimationController _bgCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _entranceCtrl;

  late final Animation<double> _floatAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    // Background fluid motion
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    
    // Logo floating and breathing
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    
    // Rotating ring around logo
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    
    // Initial entrance staggered animation
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOutSine));
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _entranceSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _spinCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _doAuth() async {
    if (_isLoading) return;
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name     = _nameCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please enter your email and password.');
      return;
    }
    if (_isSignUp && (name.isEmpty || phone.isEmpty)) {
      setState(() => _errorMsg = 'Please provide your name and phone number.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        await authService.signUp(email, password, name, phone);
      } else {
        await authService.signInWithEmailPassword(email, password);
      }
      // Navigation handled by _AuthGate in main.dart via authStateProvider.
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  void _onForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Enter your email address first.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        SnackbarUtils.showSuccess('Password reset email sent — check your inbox.');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ─── 1. Animated Fluid Background ─────────────────────────────
          _buildWanderingOrb(
            color: AppTheme.primary,
            size: 400,
            initialX: -100,
            initialY: -50,
            phase: 0.0,
          ),
          _buildWanderingOrb(
            color: AppTheme.secondary,
            size: 350,
            initialX: size.width - 200,
            initialY: size.height * 0.4,
            phase: 2.0,
          ),
          _buildWanderingOrb(
            color: AppTheme.tertiary,
            size: 300,
            initialX: 50,
            initialY: size.height - 150,
            phase: 4.0,
          ),
          
          // Heavy Glass Blur over the orbs
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: AppTheme.background.withValues(alpha: 0.55),
            ),
          ),

          // ─── 2. Scrollable Content ────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAnimatedLogo(),
                        const SizedBox(height: 48),
                        _buildGlassForm(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background Fluid Orbs ──────────────────────────────────────────────
  Widget _buildWanderingOrb({
    required Color color,
    required double size,
    required double initialX,
    required double initialY,
    required double phase,
  }) {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, _) {
        final dx = math.sin((_bgCtrl.value * 2 * math.pi) + phase) * 80;
        final dy = math.cos((_bgCtrl.value * 2 * math.pi) + phase) * 100;
        return Positioned(
          left: initialX + dx,
          top: initialY + dy,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.35),
            ),
          ),
        );
      },
    );
  }

  // ─── Animated Logo & Title ──────────────────────────────────────────────
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Breathing backdrop glow
              AnimatedBuilder(
                animation: _logoCtrl,
                builder: (_, __) => Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3 * _pulseAnim.value),
                        blurRadius: 40,
                        spreadRadius: 10 * _pulseAnim.value,
                      ),
                    ],
                  ),
                ),
              ),
              // Rotating precision ring
              AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(140, 140),
                  painter: _RingPainter(progress: _spinCtrl.value, color: AppTheme.primary),
                ),
              ),
              // The Logo itself
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.glassBorder, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo_new.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'MedPrep',
            style: AppTheme.displayLg(color: AppTheme.onSurface)
                .copyWith(fontSize: 38, letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Text(
            'Medical Intelligence Platform',
            style: AppTheme.bodyMd(color: AppTheme.primary).copyWith(letterSpacing: 0.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── Glassmorphism Form Card ────────────────────────────────────────────
  Widget _buildGlassForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTabToggle(),
              const SizedBox(height: 32),
              
              if (_isSignUp) ...[
                _textField(
                  id: 'login_name',
                  controller: _nameCtrl,
                  hint: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  keyboard: TextInputType.name,
                ),
                const SizedBox(height: 16),
                _textField(
                  id: 'login_phone',
                  controller: _phoneCtrl,
                  hint: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 16),
              ],

              _textField(
                id: 'login_email',
                controller: _emailCtrl,
                hint: 'Email Address',
                icon: Icons.alternate_email_rounded,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _passwordField(),

              if (!_isSignUp) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _onForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: AppTheme.labelSm(color: AppTheme.primary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              if (_errorMsg != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: AppTheme.labelSm(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              _buildSubmitBtn(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sliding Tab Toggle ─────────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: _isSignUp ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() { _isSignUp = false; _errorMsg = null; });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: AppTheme.titleSm(
                          color: !_isSignUp ? AppTheme.onPrimary : AppTheme.onSurfaceVariant)
                          .copyWith(fontSize: 14),
                      child: const Text('Sign In'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() { _isSignUp = true; _errorMsg = null; });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: AppTheme.titleSm(
                          color: _isSignUp ? AppTheme.onPrimary : AppTheme.onSurfaceVariant)
                          .copyWith(fontSize: 14),
                      child: const Text('Sign Up'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Reusable Text Field ────────────────────────────────────────────────
  Widget _textField({
    required String id,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboard,
  }) {
    return TextField(
      key: Key(id),
      controller: controller,
      keyboardType: keyboard,
      style: AppTheme.bodyMd(color: AppTheme.onSurface),
      cursorColor: AppTheme.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 12),
          child: Icon(icon, color: AppTheme.onSurfaceVariant, size: 22),
        ),
        filled: true,
        fillColor: AppTheme.background.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      key: const Key('login_password'),
      controller: _passwordCtrl,
      obscureText: _obscure,
      style: AppTheme.bodyMd(color: AppTheme.onSurface),
      cursorColor: AppTheme.primary,
      onSubmitted: (_) => _doAuth(),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: AppTheme.bodyMd(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 18, right: 12),
          child: Icon(Icons.lock_outline_rounded, color: AppTheme.onSurfaceVariant, size: 22),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.onSurfaceVariant, size: 22,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        filled: true,
        fillColor: AppTheme.background.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  // ─── CTA Button ─────────────────────────────────────────────────────────
  Widget _buildSubmitBtn() {
    return GestureDetector(
      key: const Key('login_submit'),
      onTap: _isLoading ? null : _doAuth,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isLoading
                  ? [AppTheme.surfaceHigh, AppTheme.surfaceHigh]
                  : [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25 * _pulseAnim.value),
                      blurRadius: 15 + 10 * _pulseAnim.value,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: AppTheme.onPrimary, strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSignUp ? 'Initialize Profile' : 'Access Workspace',
                        style: AppTheme.titleSm(color: AppTheme.onPrimary).copyWith(letterSpacing: 0.5, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, color: AppTheme.onPrimary, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        GestureDetector(
          key: const Key('login_guest'),
          onTap: () async {
            HapticFeedback.selectionClick();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_guest', true);
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/main');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
              color: AppTheme.surfaceContainer.withValues(alpha: 0.2),
            ),
            child: Text(
              'Continue as Guest',
              style: AppTheme.labelSm(color: AppTheme.onSurfaceVariant)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'MedPrep v1.0  ·  Secure Connection',
          style: AppTheme.labelXs(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}

// ─── Custom Painter for Rotating Ring ─────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color,
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.progress != progress;
}
