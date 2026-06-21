import 'dart:math' as math;

import 'package:flutter/material.dart';

const brandPink = Color(0xFFEC3090);
const brandPinkDeep = Color(0xFFC9156E);
const brandPinkGlow = Color(0xFFFF4DA6);

/// Branded splash animation: logo reveal, gentle pulse, wave loader.
class Menu2GoSplashAnimation extends StatefulWidget {
  const Menu2GoSplashAnimation({super.key});

  static Future<void> playExit(GlobalKey<Menu2GoSplashAnimationState> key) {
    return key.currentState?.playExit() ?? Future.value();
  }

  @override
  State<Menu2GoSplashAnimation> createState() => Menu2GoSplashAnimationState();
}

class Menu2GoSplashAnimationState extends State<Menu2GoSplashAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _pulseController;
  late final AnimationController _loaderController;
  late final AnimationController _exitController;
  late final AnimationController _ambientController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoSlide;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );

    final enterCurve = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0, 1, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.85, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(enterCurve);
    _logoSlide = Tween<double>(begin: 28, end: 0).animate(enterCurve);
    _loaderOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.45, 1, curve: Curves.easeOut),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _enterController.forward();
    _pulseController.repeat(reverse: true);
    _loaderController.repeat();
    _ambientController.repeat();
  }

  Future<void> playExit() async {
    _pulseController.stop();
    _loaderController.stop();
    await _exitController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _pulseController.dispose();
    _loaderController.dispose();
    _exitController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _enterController,
        _pulseController,
        _loaderController,
        _exitController,
        _ambientController,
      ]),
      builder: (context, child) {
        final pulse = 1 + (_pulseController.value * 0.028);
        final ambient = _ambientController.value * 2 * math.pi;

        return Opacity(
          opacity: _exitOpacity.value,
          child: Transform.scale(
            scale: _exitScale.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        math.sin(ambient) * 0.08,
                        math.cos(ambient) * 0.06 - 0.05,
                      ),
                      radius: 1.15,
                      colors: const [
                        brandPinkGlow,
                        brandPink,
                        brandPinkDeep,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                ..._ambientOrbs(ambient),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, _logoSlide.value),
                        child: Transform.scale(
                          scale: _logoScale.value * pulse,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: _LogoGlow(
                              glowStrength: _pulseController.value,
                              child: Image.asset(
                                'assets/branding/app_logo_mark.png',
                                width: 220,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Opacity(
                        opacity: _loaderOpacity.value,
                        child: _WaveLoader(progress: _loaderController.value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _ambientOrbs(double ambient) {
    return [
      _orb(
        alignment: Alignment(
          -0.85 + math.sin(ambient) * 0.04,
          -0.72 + math.cos(ambient * 0.8) * 0.03,
        ),
        size: 180,
        opacity: 0.08,
      ),
      _orb(
        alignment: Alignment(
          0.9 + math.cos(ambient * 0.7) * 0.05,
          0.55 + math.sin(ambient * 0.6) * 0.04,
        ),
        size: 220,
        opacity: 0.06,
      ),
    ];
  }

  Widget _orb({
    required Alignment alignment,
    required double size,
    required double opacity,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _LogoGlow extends StatelessWidget {
  const _LogoGlow({
    required this.glowStrength,
    required this.child,
  });

  final double glowStrength;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18 + glowStrength * 0.12),
            blurRadius: 28 + glowStrength * 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WaveLoader extends StatelessWidget {
  const _WaveLoader({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          final phase = progress * 2 * math.pi + (index * 2 * math.pi / 3);
          final lift = math.sin(phase) * 0.5 + 0.5;
          final scale = 0.75 + lift * 0.35;
          final opacity = 0.45 + lift * 0.55;

          return Transform.translate(
            offset: Offset(0, -lift * 6),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35 * lift),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
