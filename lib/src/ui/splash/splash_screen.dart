// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../home.dart';
import '../../repos/image_prompts_repository.dart';
import '../../repos/phrases_repository.dart';
import '../../repos/settings_repository.dart';
import '../../repos/onboarding_repository.dart';
import '../../repos/uploader.dart';
import '../core/themes/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Master controller drives everything
  late final AnimationController _masterController;

  // Logo: scale bounce + fade
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowOpacity;

  // Word animations
  late final Animation<double> _word1Opacity;
  late final Animation<Offset> _word1Slide;
  late final Animation<double> _word2Opacity;
  late final Animation<Offset> _word2Slide;

  // Divider + tagline
  late final Animation<double> _dividerWidth;
  late final Animation<double> _taglineOpacity;

  // Bottom dots
  late final Animation<double> _dotsOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B1A1C),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Kick off repo loading in the background while the splash plays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<PhrasesRepository>(context, listen: false).initFromAssetFile();
      Provider.of<ImagePromptsRepository>(context, listen: false).initFromAssetFile();
      Provider.of<SettingsRepository>(context, listen: false).initFromPreferences();
      Provider.of<OnboardingRepository>(context, listen: false).initFromPreferences();
      Provider.of<Uploader>(context, listen: false).attachPhrasesRepository(
          Provider.of<PhrasesRepository>(context, listen: false));
    });

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // ── Logo (0%–40%) ─────────────────────────────────────────────
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.00, 0.20, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.00, 0.42, curve: Curves.elasticOut),
      ),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.20, 0.45, curve: Curves.easeInOut),
      ),
    );

    // ── "ATEKER" (30%–60%) ────────────────────────────────────────
    _word1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.30, 0.58, curve: Curves.easeOut),
      ),
    );
    _word1Slide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.30, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    // ── "VOICES" (42%–68%) ────────────────────────────────────────
    _word2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
      ),
    );
    _word2Slide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // ── Divider line (58%–75%) ────────────────────────────────────
    _dividerWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.58, 0.75, curve: Curves.easeInOut),
      ),
    );

    // ── Tagline (65%–82%) ─────────────────────────────────────────
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.65, 0.82, curve: Curves.easeIn),
      ),
    );

    // ── Dots (78%–92%) ────────────────────────────────────────────
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.78, 0.92, curve: Curves.easeIn),
      ),
    );

    _masterController.forward().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const HomeController(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeIn,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1A1C),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C0800), // Deep dark orange
              Color(0xFF3D1A00), // Rich burnt sienna
              Color(0xFF0D3B42), // Deep teal
              Color(0xFF062428), // Near-black teal
            ],
            stops: [0.0, 0.38, 0.68, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative background circles ──────────────────────
            Positioned(
              top: -size.width * 0.35,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(18),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.40,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.85,
                height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withAlpha(22),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.55,
              right: -size.width * 0.15,
              child: Container(
                width: size.width * 0.45,
                height: size.width * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(8),
                ),
              ),
            ),

            // ── Animated arc ring behind logo ──────────────────────
            Positioned(
              top: size.height * 0.22,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _masterController,
                builder: (_, __) {
                  return Opacity(
                    opacity: _glowOpacity.value,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(180, 180),
                        painter: _ArcRingPainter(
                          progress: _masterController.value,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Main content column ────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.04),

                  // Logo with glow circle
                  AnimatedBuilder(
                    animation: _masterController,
                    builder: (_, __) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(18),
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(100),
                                  blurRadius: 48,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: Colors.white.withAlpha(20),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(28),
                            child: Image.asset(
                              'assets/images/atekervoices-logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // "ATEKER"
                  AnimatedBuilder(
                    animation: _masterController,
                    builder: (_, __) {
                      return FadeTransition(
                        opacity: _word1Opacity,
                        child: SlideTransition(
                          position: _word1Slide,
                          child: Text(
                            'ATEKER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 12,
                              height: 1.05,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(100),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // "VOICES"
                  AnimatedBuilder(
                    animation: _masterController,
                    builder: (_, __) {
                      return FadeTransition(
                        opacity: _word2Opacity,
                        child: SlideTransition(
                          position: _word2Slide,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFFFF9A3C),
                                Color(0xFFD06E1A),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'VOICES',
                              style: const TextStyle(
                                color: Colors.white, // masked by shader
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 12,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Animated divider
                  AnimatedBuilder(
                    animation: _masterController,
                    builder: (_, __) {
                      return Align(
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _dividerWidth.value,
                            child: Container(
                              width: 56,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withAlpha(200),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Tagline
                  AnimatedBuilder(
                    animation: _masterController,
                    builder: (_, __) {
                      return Opacity(
                        opacity: _taglineOpacity.value,
                        child: Text(
                          'PRESERVING EVERY VOICE',
                          style: TextStyle(
                            color: Colors.white.withAlpha(160),
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 4.5,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Pulsing dots loader ────────────────────────────────
            Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _masterController,
                builder: (_, __) {
                  return Opacity(
                    opacity: _dotsOpacity.value,
                    child: const _PulsingDots(),
                  );
                },
              ),
            ),

            // ── Version tag ───────────────────────────────────────
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _masterController,
                builder: (_, __) {
                  return Opacity(
                    opacity: _dotsOpacity.value * 0.6,
                    child: Text(
                      'v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(80),
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Arc ring that draws progressively behind the logo
// ──────────────────────────────────────────────────────────────────────────────
class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Faint full ring
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, bgPaint);

    // Animated arc
    final sweepAngle = math.pi * 2 * (progress * 2).clamp(0.0, 1.0);
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: [
          color.withAlpha(0),
          color.withAlpha(200),
          color.withAlpha(80),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => old.progress != progress;
}

// ──────────────────────────────────────────────────────────────────────────────
// Three staggered pulsing dots
// ──────────────────────────────────────────────────────────────────────────────
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scales;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );

    _scales = _controllers.map((c) {
      return Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 220), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _scales[i],
          builder: (_, __) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(
                  (255 * _scales[i].value * 0.75).round(),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(
                      (180 * _scales[i].value).round(),
                    ),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
