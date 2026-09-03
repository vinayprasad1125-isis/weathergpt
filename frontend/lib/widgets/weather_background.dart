import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Maps a temperature (°C) to one of four weather animation states.
enum WeatherAnimationState { snow, cloudy, mildSunny, extremeSunny }

WeatherAnimationState getWeatherAnimation(int? temp) {
  if (temp == null) return WeatherAnimationState.cloudy;
  if (temp < 23) return WeatherAnimationState.snow;
  if (temp < 32) return WeatherAnimationState.cloudy;
  if (temp <= 40) return WeatherAnimationState.mildSunny;
  return WeatherAnimationState.extremeSunny;
}

/// Drop-in background widget. Place it at the bottom of a Stack.
class WeatherBackground extends StatefulWidget {
  final int? temperature;
  const WeatherBackground({super.key, required this.temperature});

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleCtrl;
  late AnimationController _fadeCtrl;
  WeatherAnimationState _currentState = WeatherAnimationState.cloudy;
  WeatherAnimationState _nextState = WeatherAnimationState.cloudy;

  // particle data lives here so it is not regenerated every tick
  final math.Random _rng = math.Random(42);
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _currentState = getWeatherAnimation(widget.temperature);
    _nextState = _currentState;
    _particles = _buildParticles(_currentState);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(WeatherBackground old) {
    super.didUpdateWidget(old);
    final newState = getWeatherAnimation(widget.temperature);
    if (newState != _currentState) {
      _nextState = newState;
      // fade out → swap → fade in
      _fadeCtrl.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentState = _nextState;
            _particles = _buildParticles(_currentState);
          });
          _fadeCtrl.forward();
        }
      });
    }
  }

  List<_Particle> _buildParticles(WeatherAnimationState state) {
    switch (state) {
      case WeatherAnimationState.snow:
        return List.generate(80, (i) => _Particle(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          size: 2.0 + _rng.nextDouble() * 4,
          speed: 0.04 + _rng.nextDouble() * 0.06,
          drift: (_rng.nextDouble() - 0.5) * 0.015,
          opacity: 0.5 + _rng.nextDouble() * 0.5,
          phase: _rng.nextDouble() * math.pi * 2,
        ));
      case WeatherAnimationState.cloudy:
        return List.generate(6, (i) => _Particle(
          x: _rng.nextDouble(),
          y: 0.05 + _rng.nextDouble() * 0.35,
          size: 80.0 + _rng.nextDouble() * 120,
          speed: 0.008 + _rng.nextDouble() * 0.012,
          drift: 0,
          opacity: 0.12 + _rng.nextDouble() * 0.15,
          phase: _rng.nextDouble() * math.pi * 2,
        ));
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honour prefers-reduced-motion (MediaQuery)
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return FadeTransition(
      opacity: _fadeCtrl,
      child: AnimatedBuilder(
        animation: _particleCtrl,
        builder: (context, _) {
          final t = reduceMotion ? 0.0 : _particleCtrl.value;
          return CustomPaint(
            painter: _WeatherPainter(
              state: _currentState,
              t: t,
              particles: _particles,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared particle data class
// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  double x, y;
  final double size, speed, drift, opacity, phase;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
    required this.phase,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter – all drawing happens here, zero widget rebuilds needed
// ─────────────────────────────────────────────────────────────────────────────
class _WeatherPainter extends CustomPainter {
  final WeatherAnimationState state;
  final double t; // animation controller value [0,1]
  final List<_Particle> particles;

  _WeatherPainter({required this.state, required this.t, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    switch (state) {
      case WeatherAnimationState.snow:
        _paintSnow(canvas, size);
        break;
      case WeatherAnimationState.cloudy:
        _paintCloudy(canvas, size);
        break;
      case WeatherAnimationState.mildSunny:
        _paintMildSunny(canvas, size);
        break;
      case WeatherAnimationState.extremeSunny:
        _paintExtremeSunny(canvas, size);
        break;
    }
  }

  // ── SNOW ──────────────────────────────────────────────────────────────────
  void _paintSnow(Canvas canvas, Size size) {
    // subtle cold-blue gradient sky
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFB8D4F0), const Color(0xFFECF4FB)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final flakePaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      // compute current position
      final dy = (p.y + p.speed * t * 10) % 1.0;
      final dx = (p.x + p.drift * math.sin(p.phase + t * math.pi * 4)) % 1.0;
      flakePaint.color = Colors.white.withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        p.size / 2,
        flakePaint,
      );
    }
  }

  // ── CLOUDY ────────────────────────────────────────────────────────────────
  void _paintCloudy(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFCFD9E8), const Color(0xFFECF0F5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cloudPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    for (final p in particles) {
      final dx = ((p.x + p.speed * t * 4) % 1.2) - 0.1;
      cloudPaint.color = Colors.white.withOpacity(p.opacity);
      final cx = dx * size.width;
      final cy = p.y * size.height;
      final r = p.size;
      // draw a simple cloud blob as multiple overlapping circles
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.1), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.5, cy + r * 0.15), width: r * 1.4, height: r * 0.9), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.55, cy + r * 0.15), width: r * 1.3, height: r * 0.85), cloudPaint);
    }
  }

  // ── MILD SUNNY ────────────────────────────────────────────────────────────
  void _paintMildSunny(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF87CEEB), const Color(0xFFFFF9E6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final pulse = 0.92 + 0.08 * math.sin(t * math.pi * 2);
    final cx = size.width * 0.82;
    final cy = size.height * 0.12;

    // outer soft glow
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55);
    glowPaint.color = const Color(0xFFFFF176).withOpacity(0.35 * pulse);
    canvas.drawCircle(Offset(cx, cy), 120 * pulse, glowPaint);

    // mid glow
    glowPaint.color = const Color(0xFFFFEB3B).withOpacity(0.5 * pulse);
    glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset(cx, cy), 60 * pulse, glowPaint);

    // sun disc
    final sunPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD600).withOpacity(0.85);
    canvas.drawCircle(Offset(cx, cy), 32 * pulse, sunPaint);
  }

  // ── EXTREME SUNNY ────────────────────────────────────────────────────────
  void _paintExtremeSunny(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFA726), const Color(0xFFFFF8E1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final pulse = 0.88 + 0.12 * math.sin(t * math.pi * 2);
    final cx = size.width * 0.82;
    final cy = size.height * 0.1;

    // heat shimmer bands
    final shimmerPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (int i = 0; i < 5; i++) {
      final bandY = size.height * (0.55 + i * 0.1) +
          6 * math.sin(t * math.pi * 4 + i * 0.9);
      shimmerPaint.color = const Color(0xFFFFA726).withOpacity(0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, bandY, size.width, 18),
          const Radius.circular(9),
        ),
        shimmerPaint,
      );
    }

    // rays
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2 + t * math.pi * 0.5;
      final r1 = 50.0 * pulse;
      final r2 = 90.0 + 20 * math.sin(t * math.pi * 3 + i) * pulse;
      rayPaint.color = const Color(0xFFFFD600).withOpacity(0.22);
      canvas.drawLine(
        Offset(cx + math.cos(angle) * r1, cy + math.sin(angle) * r1),
        Offset(cx + math.cos(angle) * r2, cy + math.sin(angle) * r2),
        rayPaint,
      );
    }

    // outer intense glow
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65);
    glowPaint.color = const Color(0xFFFF6F00).withOpacity(0.38 * pulse);
    canvas.drawCircle(Offset(cx, cy), 140 * pulse, glowPaint);

    glowPaint.color = const Color(0xFFFFD600).withOpacity(0.55 * pulse);
    glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(cx, cy), 70 * pulse, glowPaint);

    // sun disc
    final sunPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFE57F);
    canvas.drawCircle(Offset(cx, cy), 40 * pulse, sunPaint);
  }

  @override
  bool shouldRepaint(_WeatherPainter old) =>
      old.t != t || old.state != state;
}
