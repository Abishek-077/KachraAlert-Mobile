import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:smart_waste_app/app/theme/app_colors.dart';
import 'package:smart_waste_app/core/motion/app_motion.dart';
import 'package:smart_waste_app/core/motion/motion_profile.dart';
import 'package:smart_waste_app/core/widgets/floating_particles.dart';

import '../../../settings/presentation/providers/settings_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  late final PageController _page;
  late final AnimationController _sceneController;
  late final AnimationController _pulseController;
  late final AnimationController _ctaController;
  int _index = 0;
  bool _isFinishing = false;
  MotionProfile? _lastProfile;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    )..repeat(reverse: true);
    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _page.dispose();
    _sceneController.dispose();
    _pulseController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.motionProfile;
    if (_lastProfile == profile) return;
    _lastProfile = profile;

    _sceneController.duration = profile.scaleMs(18000);
    _pulseController.duration = profile.scaleMs(4400);
    _ctaController.duration = profile.scaleMs(1800);

    if (profile.reduceMotion) {
      _sceneController.stop();
      _pulseController.stop();
      _ctaController.stop();
      _sceneController.value = 0.5;
      _pulseController.value = 0.5;
      _ctaController.value = 0.5;
    } else {
      if (!_sceneController.isAnimating) {
        _sceneController.repeat();
      }
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      if (!_ctaController.isAnimating) {
        _ctaController.repeat(reverse: true);
      }
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    await ref.read(settingsProvider.notifier).setOnboarded();
    if (!mounted) return;
    context.go('/auth/login');
  }

  Future<void> _continue(List<_OnboardData> pages) async {
    if (_isFinishing) return;
    if (_index < pages.length - 1) {
      await _page.nextPage(
        duration: AppMotion.scaled(context.motionProfile, AppMotion.long),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final profile = context.motionProfile;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _sceneController,
          _pulseController,
          _ctaController,
          _page,
        ]),
        builder: (context, _) {
          final pageValue = _page.hasClients
              ? (_page.page ?? _index.toDouble())
              : _index.toDouble();
          final sceneValue =
              profile.reduceMotion ? 0.5 : _sceneController.value;
          final pulseValue =
              profile.reduceMotion ? 0.5 : _pulseController.value;
          final ctaValue = profile.reduceMotion ? 0.5 : _ctaController.value;
          final scenePalette = _ScenePalette.lerp(pages, pageValue, theme);

          return Stack(
            fit: StackFit.expand,
            children: [
              _CinematicBackground(
                palette: scenePalette,
                sceneValue: sceneValue,
                pulseValue: pulseValue,
                isDark: isDark,
              ),
              if (!profile.reduceMotion)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: isDark ? 0.35 : 0.5,
                      child: FloatingParticles(
                        particleCount: 38,
                        minSize: 1.8,
                        maxSize: 6,
                        color: scenePalette.primary.withValues(
                          alpha: isDark ? 0.85 : 0.55,
                        ),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                      child: Row(
                        children: [
                          _BrandPulsePill(
                            sceneValue: sceneValue,
                            isDark: isDark,
                            accent: scenePalette.primary,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _isFinishing ? null : _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: cs.onSurfaceVariant,
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _page,
                        itemCount: pages.length,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (context, i) {
                          final p = pages[i];
                          return _OnboardingSlide(
                            data: p,
                            pageOffset: (pageValue - i).clamp(-1.0, 1.0),
                            sceneValue: sceneValue,
                            pulseValue: pulseValue,
                            colorScheme: cs,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                    _KineticPageIndicator(
                      count: pages.length,
                      pageValue: pageValue,
                      activeColor: scenePalette.primary,
                      passiveColor: cs.outlineVariant.withValues(
                        alpha: isDark ? 0.4 : 0.55,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SmoothPageIndicator(
                      controller: _page,
                      count: pages.length,
                      effect: WormEffect(
                        spacing: 7,
                        dotHeight: 6,
                        dotWidth: 6,
                        radius: 100,
                        activeDotColor: scenePalette.primary,
                        dotColor: scenePalette.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: _LiquidCtaButton(
                        onTap: _isFinishing ? null : () => _continue(pages),
                        label: _index == pages.length - 1
                            ? 'Enter The Experience'
                            : 'Next Scene',
                        icon: _index == pages.length - 1
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        primary: scenePalette.primary,
                        secondary: scenePalette.secondary,
                        pulse: ctaValue,
                        loading: _isFinishing,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CinematicBackground extends StatelessWidget {
  const _CinematicBackground({
    required this.palette,
    required this.sceneValue,
    required this.pulseValue,
    required this.isDark,
  });

  final _ScenePalette palette;
  final double sceneValue;
  final double pulseValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final phase = sceneValue * math.pi * 2;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.background,
            ),
          ),
        ),
        CustomPaint(
          painter: _AuroraPainter(
            primary: palette.primary,
            secondary: palette.secondary,
            progress: sceneValue,
            pulse: pulseValue,
            isDark: isDark,
          ),
        ),
        Positioned(
          right: -90 + math.sin(phase) * 25,
          top: -60 + math.cos(phase * 1.4) * 16,
          child: _GlowOrb(
            size: 250,
            colors: [
              palette.secondary.withValues(alpha: isDark ? 0.32 : 0.28),
              Colors.transparent,
            ],
          ),
        ),
        Positioned(
          left: -120 + math.cos(phase * 0.7) * 18,
          bottom: -70 + math.sin(phase * 1.2) * 20,
          child: _GlowOrb(
            size: 300,
            colors: [
              palette.primary.withValues(alpha: isDark ? 0.36 : 0.32),
              Colors.transparent,
            ],
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.06),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.data,
    required this.pageOffset,
    required this.sceneValue,
    required this.pulseValue,
    required this.colorScheme,
    required this.isDark,
  });

  final _OnboardData data;
  final double pageOffset;
  final double sceneValue;
  final double pulseValue;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final focus = (1 - pageOffset.abs()).clamp(0.0, 1.0);
    final phase = sceneValue * math.pi * 2;
    final heroLift = math.sin(phase + data.motionSeed) * 14;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            flex: 11,
            child: Transform.translate(
              offset: Offset(pageOffset * 42, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _OrbitRing(
                    color: data.accent,
                    pulse: pulseValue,
                    sceneValue: sceneValue,
                  ),
                  ...data.orbits.map(
                    (orbit) => _OrbitingObject(
                      orbit: orbit,
                      sceneValue: sceneValue,
                      colorA: data.accent,
                      colorB: data.accentSecondary,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, heroLift * focus),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(pageOffset * -0.36)
                        ..rotateX(
                          math.sin(phase * 1.05 + data.motionSeed) * 0.09,
                        )
                        ..rotateZ(
                          math.sin(phase * 0.65 + data.motionSeed) * 0.04,
                        ),
                      child: _MorphingHeroCard(
                        data: data,
                        pulseValue: pulseValue,
                        sceneValue: sceneValue,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    child: _TagPill(
                      text: data.tag,
                      accent: data.accent,
                      isDark: isDark,
                      colorScheme: colorScheme,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 84,
                    child: _FloatingBadge(
                      icon: Icons.speed_rounded,
                      label: data.badgeLeft,
                      accent: data.accent,
                      delay: 0.0,
                      sceneValue: sceneValue,
                      isDark: isDark,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 50,
                    child: _FloatingBadge(
                      icon: Icons.auto_awesome_rounded,
                      label: data.badgeRight,
                      accent: data.accentSecondary,
                      delay: 1.3,
                      sceneValue: sceneValue,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Transform.translate(
            offset: Offset(pageOffset * 20, 0),
            child: _StoryPanel(
              data: data,
              isDark: isDark,
              colorScheme: colorScheme,
              pulseValue: pulseValue,
            ),
          ),
          const SizedBox(height: 14),
          _MetricsRow(
            metrics: data.metrics,
            accent: data.accent,
            accentSecondary: data.accentSecondary,
            sceneValue: sceneValue,
            isDark: isDark,
            colorScheme: colorScheme,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _BrandPulsePill extends StatelessWidget {
  const _BrandPulsePill({
    required this.sceneValue,
    required this.isDark,
    required this.accent,
  });

  final double sceneValue;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final phase = sceneValue * math.pi * 2;
    final shine = (math.sin(phase) + 1) / 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface.withValues(alpha: isDark ? 0.88 : 0.92),
            accent.withValues(alpha: isDark ? 0.2 : 0.15 + shine * 0.1),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.waves_rounded,
            size: 16,
            color: accent.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 6),
          Text(
            'KACHRA ALERT',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MorphingHeroCard extends StatelessWidget {
  const _MorphingHeroCard({
    required this.data,
    required this.pulseValue,
    required this.sceneValue,
    required this.isDark,
  });

  final _OnboardData data;
  final double pulseValue;
  final double sceneValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final phase = sceneValue * math.pi * 2;
    final bloom = 0.4 + pulseValue * 0.6;

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 30),
            child: Container(
              width: 190,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.16),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: data.accent.withValues(alpha: 0.22 + bloom * 0.18),
                    blurRadius: 35,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.18,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(58),
                border: Border.all(
                  color: data.accentSecondary.withValues(alpha: 0.35),
                  width: 1.3,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.accent.withValues(alpha: 0.16),
                    data.accentSecondary.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 208,
            height: 208,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surface.withValues(alpha: isDark ? 0.88 : 0.93),
                  cs.surface.withValues(alpha: isDark ? 0.66 : 0.86),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
                  blurRadius: 30,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.accent.withValues(alpha: 0.98),
                    data.accentSecondary.withValues(alpha: 0.88),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.accent.withValues(alpha: 0.42),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HeroShimmerPainter(
                        progress: sceneValue,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: phase * 0.25,
                    child: Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.34),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -phase * 0.42,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.1,
                        ),
                      ),
                    ),
                  ),
                  Icon(data.icon, color: Colors.white, size: 58),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryPanel extends StatelessWidget {
  const _StoryPanel({
    required this.data,
    required this.isDark,
    required this.colorScheme,
    required this.pulseValue,
  });

  final _OnboardData data;
  final bool isDark;
  final ColorScheme colorScheme;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: isDark ? 0.82 : 0.92),
            colorScheme.surface.withValues(alpha: isDark ? 0.65 : 0.82),
          ],
        ),
        border: Border.all(
          color: data.accent.withValues(alpha: 0.35 + pulseValue * 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              letterSpacing: -0.6,
              color: colorScheme.onSurface,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.4,
              height: 1.52,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.metrics,
    required this.accent,
    required this.accentSecondary,
    required this.sceneValue,
    required this.isDark,
    required this.colorScheme,
  });

  final List<_MetricData> metrics;
  final Color accent;
  final Color accentSecondary;
  final double sceneValue;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(metrics.length, (index) {
        final metric = metrics[index];
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: index == metrics.length - 1 ? 0 : 8),
            child: _MetricCard(
              data: metric,
              accent: accent,
              accentSecondary: accentSecondary,
              sceneValue: sceneValue + index * 0.17,
              isDark: isDark,
              colorScheme: colorScheme,
            ),
          ),
        );
      }),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.data,
    required this.accent,
    required this.accentSecondary,
    required this.sceneValue,
    required this.isDark,
    required this.colorScheme,
  });

  final _MetricData data;
  final Color accent;
  final Color accentSecondary;
  final double sceneValue;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final phase = sceneValue * math.pi * 2;
    final lift = math.sin(phase) * 4;

    return Transform.translate(
      offset: Offset(0, lift),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withValues(alpha: isDark ? 0.8 : 0.9),
              colorScheme.surface.withValues(alpha: isDark ? 0.62 : 0.8),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: accentSecondary.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.95),
                    accentSecondary.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Icon(data.icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              data.value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10.3,
                color: colorScheme.onSurfaceVariant,
                height: 1.22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.text,
    required this.accent,
    required this.isDark,
    required this.colorScheme,
  });

  final String text;
  final Color accent;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface.withValues(alpha: isDark ? 0.84 : 0.95),
            accent.withValues(alpha: isDark ? 0.16 : 0.11),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.2,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.accent,
    required this.delay,
    required this.sceneValue,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final double delay;
  final double sceneValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final phase = (sceneValue + delay) * math.pi * 2;
    final lift = math.sin(phase) * 9;

    return Transform.translate(
      offset: Offset(0, lift),
      child: Transform.rotate(
        angle: math.sin(phase * 0.7) * 0.05,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cs.surface.withValues(alpha: isDark ? 0.84 : 0.92),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KineticPageIndicator extends StatelessWidget {
  const _KineticPageIndicator({
    required this.count,
    required this.pageValue,
    required this.activeColor,
    required this.passiveColor,
  });

  final int count;
  final double pageValue;
  final Color activeColor;
  final Color passiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final delta = (pageValue - i).abs().clamp(0.0, 1.0);
        final t = 1 - delta;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10 + t * 28,
          height: 8 + t * 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                Color.lerp(passiveColor, activeColor, t * 0.92)!,
                Color.lerp(
                    passiveColor, activeColor.withValues(alpha: 0.7), t)!,
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LiquidCtaButton extends StatelessWidget {
  const _LiquidCtaButton({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.pulse,
    required this.loading,
  });

  final VoidCallback? onTap;
  final String label;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final double pulse;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shimmerShift = pulse * 1.3 - 0.65;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment(-1 + shimmerShift, -1),
                end: Alignment(1 + shimmerShift, 1.2),
                colors: [
                  primary.withValues(alpha: 0.95),
                  Color.lerp(primary, secondary, 0.5)!,
                  secondary.withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.46),
                  blurRadius: 22 + pulse * 10,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: _LiquidFlowPainter(
                        color: Colors.white.withValues(alpha: 0.18),
                        progress: pulse,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.onPrimary,
                              ),
                            ),
                          )
                        : Icon(icon, color: cs.onPrimary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({
    required this.color,
    required this.pulse,
    required this.sceneValue,
  });

  final Color color;
  final double pulse;
  final double sceneValue;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: sceneValue * math.pi * 0.7,
      child: CustomPaint(
        size: const Size(320, 320),
        painter: _OrbitRingPainter(color: color, pulse: pulse),
      ),
    );
  }
}

class _OrbitingObject extends StatelessWidget {
  const _OrbitingObject({
    required this.orbit,
    required this.sceneValue,
    required this.colorA,
    required this.colorB,
  });

  final _OrbitSpec orbit;
  final double sceneValue;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    final angle = orbit.phase + sceneValue * math.pi * 2 * orbit.speed;
    final dx = math.cos(angle) * orbit.radius;
    final dy = math.sin(angle) * orbit.radius * 0.5;
    final depth = (math.sin(angle) + 1) / 2;
    final scale = 0.72 + depth * 0.6;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0013)
            ..rotateY(math.sin(angle) * 0.6)
            ..rotateX(math.cos(angle) * 0.3),
          child: Opacity(
            opacity: 0.35 + depth * 0.55,
            child: Container(
              width: orbit.size,
              height: orbit.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorA.withValues(alpha: 0.95),
                    colorB.withValues(alpha: 0.82),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorA.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Icon(orbit.icon,
                  size: orbit.size * 0.46, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.2),
          colors: colors,
        ),
      ),
    );
  }
}

class _HeroShimmerPainter extends CustomPainter {
  _HeroShimmerPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shift = size.width * (progress * 2.3 - 0.65);
    final rect = Offset.zero & size;
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.16),
        Colors.transparent,
      ],
      stops: const [0.34, 0.5, 0.66],
      transform: GradientRotation(-0.55),
    ).createShader(rect.shift(Offset(shift, 0)));

    final paint = Paint()..shader = shader;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_HeroShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _LiquidFlowPainter extends CustomPainter {
  _LiquidFlowPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()..color = color;
    final wavePath = Path()..moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.72 +
          math.sin((x / size.width * math.pi * 2) + progress * math.pi * 2) * 4;
      wavePath.lineTo(x, y);
    }
    wavePath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(_LiquidFlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.primary,
    required this.secondary,
    required this.progress,
    required this.pulse,
    required this.isDark,
  });

  final Color primary;
  final Color secondary;
  final double progress;
  final double pulse;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;
    final blur = MaskFilter.blur(
      BlurStyle.normal,
      isDark ? 90 : 76,
    );

    final orb1 = Offset(
      size.width * (0.18 + 0.06 * math.sin(phase)),
      size.height * (0.14 + 0.08 * math.cos(phase * 1.3)),
    );
    final orb2 = Offset(
      size.width * (0.84 + 0.08 * math.cos(phase * 0.7)),
      size.height * (0.26 + 0.1 * math.sin(phase * 1.1)),
    );
    final orb3 = Offset(
      size.width * (0.48 + 0.14 * math.cos(phase * 0.9)),
      size.height * (0.83 + 0.09 * math.sin(phase * 1.5)),
    );

    final paints = [
      Paint()
        ..color = primary.withValues(alpha: isDark ? 0.48 : 0.35 + pulse * 0.14)
        ..maskFilter = blur,
      Paint()
        ..color = secondary.withValues(alpha: isDark ? 0.4 : 0.3 + pulse * 0.1)
        ..maskFilter = blur,
      Paint()
        ..color = Color.lerp(primary, secondary, 0.55)!
            .withValues(alpha: isDark ? 0.36 : 0.24 + pulse * 0.11)
        ..maskFilter = blur,
    ];

    canvas.drawCircle(orb1, size.shortestSide * 0.26, paints[0]);
    canvas.drawCircle(orb2, size.shortestSide * 0.29, paints[1]);
    canvas.drawCircle(orb3, size.shortestSide * 0.34, paints[2]);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.03 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 4; i++) {
      final yBase = size.height * (0.2 + i * 0.19);
      final path = Path()..moveTo(-30, yBase);
      for (double x = -30; x <= size.width + 30; x += 14) {
        final y = yBase +
            math.sin((x / size.width * math.pi * 2) + phase + i * 0.8) * 10 +
            math.cos((x / size.width * math.pi) - phase * 0.8) * 6;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.isDark != isDark;
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.color,
    required this.pulse,
  });

  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.37;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 + pulse * 0.8
      ..color = color.withValues(alpha: 0.25 + pulse * 0.2);

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.55);

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.82, ringPaint..strokeWidth = 1);

    for (int i = 0; i < 14; i++) {
      final angle = (math.pi * 2 / 14) * i;
      final p1 = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * (radius + 8 + pulse * 4),
        center.dy + math.sin(angle) * (radius + 8 + pulse * 4),
      );
      canvas.drawLine(p1, p2, dashPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pulse != pulse;
  }
}

class _ScenePalette {
  const _ScenePalette({
    required this.background,
    required this.primary,
    required this.secondary,
  });

  final List<Color> background;
  final Color primary;
  final Color secondary;

  static _ScenePalette lerp(
    List<_OnboardData> pages,
    double pageValue,
    ThemeData theme,
  ) {
    final page = pageValue.clamp(0.0, (pages.length - 1).toDouble());
    final base = page.floor();
    final next = (base + 1).clamp(0, pages.length - 1);
    final t = page - base;

    final from = pages[base];
    final to = pages[next];
    final isDark = theme.brightness == Brightness.dark;

    final baseBg = List<Color>.generate(
      3,
      (i) => Color.lerp(from.background[i], to.background[i], t)!,
    );

    final darkBlend = [
      Color.lerp(
          theme.colorScheme.surface, theme.scaffoldBackgroundColor, 0.3)!,
      Color.lerp(theme.scaffoldBackgroundColor, AppColors.darkSurface, 0.25)!,
      Color.lerp(
        theme.colorScheme.surfaceContainerHighest,
        theme.scaffoldBackgroundColor,
        0.45,
      )!,
    ];

    return _ScenePalette(
      background: isDark ? darkBlend : baseBg,
      primary: Color.lerp(from.accent, to.accent, t)!,
      secondary: Color.lerp(from.accentSecondary, to.accentSecondary, t)!,
    );
  }
}

class _OnboardData {
  const _OnboardData({
    required this.tag,
    required this.icon,
    required this.accent,
    required this.accentSecondary,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.badgeLeft,
    required this.badgeRight,
    required this.metrics,
    required this.orbits,
    required this.motionSeed,
  });

  final String tag;
  final IconData icon;
  final Color accent;
  final Color accentSecondary;
  final List<Color> background;
  final String title;
  final String subtitle;
  final String badgeLeft;
  final String badgeRight;
  final List<_MetricData> metrics;
  final List<_OrbitSpec> orbits;
  final double motionSeed;
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}

class _OrbitSpec {
  const _OrbitSpec({
    required this.icon,
    required this.radius,
    required this.size,
    required this.speed,
    required this.phase,
  });

  final IconData icon;
  final double radius;
  final double size;
  final double speed;
  final double phase;
}

List<_OnboardData> _pages() => const [
      _OnboardData(
        tag: 'PREDICTIVE FLOW',
        icon: Icons.bolt_rounded,
        accent: Color(0xFFFFA928),
        accentSecondary: Color(0xFFFF5E62),
        background: [
          Color(0xFFFFF5DD),
          Color(0xFFFFE9D7),
          Color(0xFFF3E7FF),
        ],
        title: 'Pickup timing that predicts your day',
        subtitle:
            'Adaptive reminders and route intelligence work ahead of schedule so you do not miss a single collection window.',
        badgeLeft: 'Live Signal',
        badgeRight: 'AI Forecast',
        motionSeed: 0.2,
        metrics: [
          _MetricData(
            icon: Icons.speed_rounded,
            value: '2.7x',
            label: 'Response speed',
          ),
          _MetricData(
            icon: Icons.alarm_on_rounded,
            value: '24/7',
            label: 'Monitoring',
          ),
          _MetricData(
            icon: Icons.route_rounded,
            value: '91%',
            label: 'Route accuracy',
          ),
        ],
        orbits: [
          _OrbitSpec(
            icon: Icons.wifi_tethering_rounded,
            radius: 132,
            size: 34,
            speed: 1.0,
            phase: 0.0,
          ),
          _OrbitSpec(
            icon: Icons.memory_rounded,
            radius: 108,
            size: 28,
            speed: 1.2,
            phase: 1.7,
          ),
          _OrbitSpec(
            icon: Icons.schedule_rounded,
            radius: 126,
            size: 30,
            speed: 0.8,
            phase: 2.8,
          ),
          _OrbitSpec(
            icon: Icons.crisis_alert_rounded,
            radius: 98,
            size: 26,
            speed: 1.35,
            phase: 4.1,
          ),
        ],
      ),
      _OnboardData(
        tag: 'REAL TIME TRACKING',
        icon: Icons.travel_explore_rounded,
        accent: Color(0xFF2D9CFF),
        accentSecondary: Color(0xFF2AD0CA),
        background: [
          Color(0xFFE5F2FF),
          Color(0xFFDDF8FF),
          Color(0xFFEDEFFF),
        ],
        title: 'Every report becomes a live mission',
        subtitle:
            'Watch each report move through verification, assignment, and cleanup in real time with deep visual status feedback.',
        badgeLeft: 'Geo Sync',
        badgeRight: 'Fleet View',
        motionSeed: 0.9,
        metrics: [
          _MetricData(
            icon: Icons.ssid_chart_rounded,
            value: '<1s',
            label: 'Update delay',
          ),
          _MetricData(
            icon: Icons.location_searching_rounded,
            value: '98%',
            label: 'Geo precision',
          ),
          _MetricData(
            icon: Icons.dataset_linked_rounded,
            value: 'Live',
            label: 'Status feed',
          ),
        ],
        orbits: [
          _OrbitSpec(
            icon: Icons.location_on_rounded,
            radius: 126,
            size: 34,
            speed: 1.1,
            phase: 0.5,
          ),
          _OrbitSpec(
            icon: Icons.radar_rounded,
            radius: 102,
            size: 30,
            speed: 1.38,
            phase: 2.2,
          ),
          _OrbitSpec(
            icon: Icons.satellite_alt_rounded,
            radius: 138,
            size: 28,
            speed: 0.76,
            phase: 3.5,
          ),
          _OrbitSpec(
            icon: Icons.public_rounded,
            radius: 92,
            size: 24,
            speed: 1.55,
            phase: 4.6,
          ),
        ],
      ),
      _OnboardData(
        tag: 'ONE TAP REPORTING',
        icon: Icons.photo_camera_back_rounded,
        accent: Color(0xFF18B86F),
        accentSecondary: Color(0xFF1CC1A6),
        background: [
          Color(0xFFE5FFEF),
          Color(0xFFDDFCF7),
          Color(0xFFEAF6FF),
        ],
        title: 'Capture, classify, and send in seconds',
        subtitle:
            'Take a photo, auto-detect severity, and dispatch your report with intelligent presets that remove manual friction.',
        badgeLeft: 'Quick Capture',
        badgeRight: 'Smart Classify',
        motionSeed: 1.5,
        metrics: [
          _MetricData(
            icon: Icons.timer_rounded,
            value: '12s',
            label: 'Avg report time',
          ),
          _MetricData(
            icon: Icons.auto_awesome_mosaic_rounded,
            value: 'AI',
            label: 'Issue detection',
          ),
          _MetricData(
            icon: Icons.eco_rounded,
            value: '100%',
            label: 'Digital workflow',
          ),
        ],
        orbits: [
          _OrbitSpec(
            icon: Icons.camera_enhance_rounded,
            radius: 128,
            size: 35,
            speed: 0.95,
            phase: 0.1,
          ),
          _OrbitSpec(
            icon: Icons.image_search_rounded,
            radius: 96,
            size: 28,
            speed: 1.34,
            phase: 1.8,
          ),
          _OrbitSpec(
            icon: Icons.clean_hands_rounded,
            radius: 110,
            size: 30,
            speed: 1.08,
            phase: 3.2,
          ),
          _OrbitSpec(
            icon: Icons.send_rounded,
            radius: 142,
            size: 26,
            speed: 0.72,
            phase: 4.8,
          ),
        ],
      ),
    ];
