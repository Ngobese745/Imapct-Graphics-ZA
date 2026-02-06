import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_initialization_service.dart';
import 'dart:math' as math;

class SmoothLoadingScreen extends StatefulWidget {
  const SmoothLoadingScreen({super.key});

  @override
  State<SmoothLoadingScreen> createState() => _SmoothLoadingScreenState();
}

class _SmoothLoadingScreenState extends State<SmoothLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _waveController;
  late AnimationController _glowController;

  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    // Start logo animation
    _logoController.forward();

    // Wait and start text animation
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();

    // Wait and start progress animation
    await Future.delayed(const Duration(milliseconds: 200));
    _progressController.forward();

    // Start fade animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced Animated Background with Multiple Layers
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B0000), // Deep Red
                  Color(0xFFB22222), // Fire Brick
                  Color(0xFFDC143C), // Crimson
                  Color(0xFF8B0000), // Back to Deep Red
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Animated Wave Background
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: WavePainter(_waveAnimation.value),
              );
            },
          ),

          // Floating Particles
          ...List.generate(15, (index) {
            return AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                final progress = (_particleAnimation.value + index * 0.1) % 1.0;
                final size = MediaQuery.of(context).size;
                return Positioned(
                  left: (size.width * 0.2 + index * 50) % size.width,
                  top: size.height - (progress * size.height * 1.2),
                  child: Opacity(
                    opacity: (1.0 - progress) * 0.6,
                    child: Container(
                      width: 3 + (index % 3) * 2,
                      height: 3 + (index % 3) * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index % 2 == 0
                            ? const Color(0xFFFFD700)
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (index % 2 == 0
                                        ? const Color(0xFFFFD700)
                                        : Colors.white)
                                    .withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Rotating Geometric Shapes
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                final angle =
                    (_rotationController.value * 2 * math.pi) +
                    (index * math.pi / 3);
                final radius = 80 + (index * 20);
                final size = MediaQuery.of(context).size;
                return Positioned(
                  left: size.width / 2 + math.cos(angle) * radius - 15,
                  top: size.height / 2 + math.sin(angle) * radius - 15,
                  child: Opacity(
                    opacity: 0.08 + (index * 0.02),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main Content
          SafeArea(
            child: Center(
              child: Consumer<AppInitializationService>(
                builder: (context, initService, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Enhanced Animated Logo with Multiple Effects
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _logoAnimation,
                            _pulseAnimation,
                            _glowAnimation,
                          ]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  _logoAnimation.value * _pulseAnimation.value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    // Enhanced glow effect
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(
                                        alpha: _glowAnimation.value * 0.8,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(
                                        alpha: _glowAnimation.value * 0.4,
                                      ),
                                      blurRadius: 100,
                                      spreadRadius: 20,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Multiple rotating rings
                                    ...List.generate(3, (index) {
                                      return AnimatedBuilder(
                                        animation: _rotationController,
                                        builder: (context, child) {
                                          final rotationSpeed =
                                              1.0 + (index * 0.5);
                                          final ringSize =
                                              190.0 + (index * 15.0);
                                          final opacity = 0.4 - (index * 0.1);
                                          return Transform.rotate(
                                            angle:
                                                _rotationController.value *
                                                2 *
                                                math.pi *
                                                rotationSpeed,
                                            child: Container(
                                              width: ringSize,
                                              height: ringSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFFFD700,
                                                  ).withValues(alpha: opacity),
                                                  width: 1.5 - (index * 0.3),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),

                                    // Main logo container with enhanced styling
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: 160,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFFFFD700,
                                                                ),
                                                                Color(
                                                                  0xFFFFA500,
                                                                ),
                                                                Color(
                                                                  0xFFFF8C00,
                                                                ),
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                      ),
                                                  child: const Icon(
                                                    Icons.brush_outlined,
                                                    size: 80,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),

                                    // Inner glow effect
                                    AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.white.withValues(
                                                  alpha:
                                                      _glowAnimation.value *
                                                      0.1,
                                                ),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 50),

                        // Enhanced Animated Text with Advanced Effects
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _textAnimation,
                            _shimmerAnimation,
                            _glowAnimation,
                          ]),
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                40 * (1 - _textAnimation.value),
                              ),
                              child: Opacity(
                                opacity: _textAnimation.value,
                                child: Column(
                                  children: [
                                    // Main title with enhanced shimmer effect
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700)
                                                .withValues(
                                                  alpha:
                                                      _glowAnimation.value *
                                                      0.3,
                                                ),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            colors: const [
                                              Color(0xFFFFD700),
                                              Colors.white,
                                              Color(0xFFFFD700),
                                              Colors.white,
                                              Color(0xFFFFD700),
                                            ],
                                            stops: const [
                                              0.0,
                                              0.25,
                                              0.5,
                                              0.75,
                                              1.0,
                                            ],
                                            transform: GradientRotation(
                                              _shimmerAnimation.value * math.pi,
                                            ),
                                          ).createShader(bounds);
                                        },
                                        child: const Text(
                                          'IMPACT GRAPHICS ZA',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 3.0,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                offset: Offset(0, 4),
                                                blurRadius: 12,
                                              ),
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(0, 2),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Enhanced tagline with gradient background
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFFFD700,
                                          ).withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        '✨ Creative Design Solutions ✨',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black38,
                                              offset: Offset(0, 2),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Additional branding text
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Professional • Creative • Impactful',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFFFD700),
                                          letterSpacing: 1.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Simple Loading Text without Progress Bar
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _progressAnimation,
                            _glowAnimation,
                          ]),
                          builder: (context, child) {
                            return Opacity(
                              opacity: _progressAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.1),
                                      Colors.white.withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(
                                        alpha: _glowAnimation.value * 0.2,
                                      ),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Simple animated loading dots
                                    AnimatedBuilder(
                                      animation: _rotationController,
                                      builder: (context, child) {
                                        return Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFFFD700),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFFD700,
                                                ).withValues(alpha: 0.6),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      initService.currentStep,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black38,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Wave Painter for animated background
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 60.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x += 1) {
      final y =
          size.height * 0.7 +
          math.sin(
                (x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi),
              ) *
              waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add a second wave layer
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x += 1) {
      final y =
          size.height * 0.8 +
          math.sin(
                (x / waveLength * 1.5 * math.pi) +
                    (animationValue * 1.5 * math.pi),
              ) *
              waveHeight *
              0.6;
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
