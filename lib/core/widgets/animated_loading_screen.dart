import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedLoadingScreen extends StatefulWidget {
  final String message;
  
  const AnimatedLoadingScreen({
    super.key,
    this.message = 'Preparing Offline Database...',
  });

  @override
  State<AnimatedLoadingScreen> createState() => _AnimatedLoadingScreenState();
}

class _AnimatedLoadingScreenState extends State<AnimatedLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // We want the rotation to be continuous, so we'll use a separate behavior or just let it reverse.
    // Actually, repeat(reverse: true) makes it rotate back and forth. That might look like a cool scanning effect!
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159265359).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background subtle animated gradients (Plasma effect)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.3,
                      left: MediaQuery.of(context).size.width * 0.1,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.45,
                      right: MediaQuery.of(context).size.width * 0.05,
                      child: Transform.scale(
                        scale: 2.0 - _pulseAnimation.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.secondary.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Glassmorphic Blur to diffuse the glowing orbs
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Abstract Synapse/Brain Spinner
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  AppTheme.primary,
                                  AppTheme.secondary,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.4, 0.6, 1.0],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.background, // Cutout inner circle
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: -_rotationAnimation.value * 1.5,
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.secondary.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Inner glowing icon
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                         return ShaderMask(
                           shaderCallback: (Rect bounds) {
                             return RadialGradient(
                               center: Alignment.center,
                               radius: 1.0,
                               colors: <Color>[
                                 AppTheme.primary,
                                 AppTheme.secondary,
                               ],
                               tileMode: TileMode.mirror,
                             ).createShader(bounds);
                           },
                           child: Opacity(
                             opacity: 0.7 + (0.3 * _controller.value), // Pulse opacity
                             child: const Icon(
                               Icons.psychology_rounded,
                               color: Colors.white,
                               size: 36,
                             ),
                           ),
                         );
                      }
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Loading Text with pulse
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.6 + (0.4 * _controller.value),
                      child: Text(
                        widget.message,
                        style: AppTheme.bodyMd(color: AppTheme.onSurface).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
