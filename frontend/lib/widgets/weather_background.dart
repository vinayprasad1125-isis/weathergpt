import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Maps a temperature (°C) to one of four weather animation states.
enum WeatherAnimationState { snow, cloudy, mildSunny, extremeSunny }

WeatherAnimationState getWeatherAnimation(int? temp) {
  if (temp == null) return WeatherAnimationState.cloudy;
  if (temp < 20) return WeatherAnimationState.snow;
  if (temp < 33) return WeatherAnimationState.cloudy;
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
        return List.generate(10, (i) => _Particle(
          x: _rng.nextDouble(),
          y: 0.05 + _rng.nextDouble() * 0.45, // Spread a bit lower too
          size: 70.0 + _rng.nextDouble() * 100,
          speed: 0.015 + _rng.nextDouble() * 0.025, // Increased speed to make animation more apparent
          drift: 0,
          opacity: 0.15 + _rng.nextDouble() * 0.3,
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
        builder: (context, child) {
          return CustomPaint(
            painter: _WeatherPainter(
              _currentState,
              reduceMotion ? 0.0 : _particleCtrl.value,
              _particles,
              Theme.of(context).colorScheme,
              reduceMotion ? 0.0 : DateTime.now().millisecondsSinceEpoch / 1000.0,
            ),
            child: Container(),
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
  final double t; // 0.0 to 1.0 (animation progress)
  final List<_Particle> particles;
  final ColorScheme colorScheme;
  final double time; // Continuous time in seconds for non-snapping linear movement

  _WeatherPainter(this.state, this.t, this.particles, this.colorScheme, this.time);

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
    final flakePaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      // compute continuous position to avoid snapping when t resets
      final dy = (p.y + p.speed * time * 1.5) % 1.0;
      final dx = (p.x + p.drift * math.sin(p.phase + time)) % 1.0;
      flakePaint.color = colorScheme.onSurface.withOpacity(p.opacity * 0.7);
      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        p.size / 2,
        flakePaint,
      );
    }
  }

  void _paintCloudy(Canvas canvas, Size size) {
    final isLight = colorScheme.brightness == Brightness.light;
    
    final cloudPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18); 

    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    for (final p in particles) {
      // Use continuous time so clouds move endlessly without snapping back
      final dx = ((p.x + p.speed * time) % 1.4) - 0.2; 
      
      final adjustedOpacity = isLight ? math.min(1.0, p.opacity * 2.8) : p.opacity * 0.7;
      
      final cx = dx * size.width;
      final cy = p.y * size.height;
      final r = p.size;
      
      // Draw shadow first to give 3D volume and contrast against light backgrounds
      shadowPaint.color = isLight 
          ? Colors.blueGrey.withValues(alpha: adjustedOpacity * 0.3)
          : Colors.black.withValues(alpha: adjustedOpacity * 0.5);
      
      final shadowOffset = r * 0.2;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + shadowOffset), width: r * 2.2, height: r * 0.8), shadowPaint);
      canvas.drawCircle(Offset(cx - r * 0.5, cy - r * 0.1 + shadowOffset), r * 0.55, shadowPaint);
      canvas.drawCircle(Offset(cx + r * 0.1, cy - r * 0.3 + shadowOffset), r * 0.85, shadowPaint);
      canvas.drawCircle(Offset(cx + r * 0.65, cy - r * 0.05 + shadowOffset), r * 0.45, shadowPaint);
      
      // Draw white cloud body
      cloudPaint.color = Colors.white.withValues(alpha: adjustedOpacity);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.2, height: r * 0.8), cloudPaint);
      canvas.drawCircle(Offset(cx - r * 0.5, cy - r * 0.1), r * 0.55, cloudPaint);
      canvas.drawCircle(Offset(cx + r * 0.1, cy - r * 0.3), r * 0.85, cloudPaint);
      canvas.drawCircle(Offset(cx + r * 0.65, cy - r * 0.05), r * 0.45, cloudPaint);
    }
  }

  // ── MILD SUNNY ────────────────────────────────────────────────────────────
  void _paintMildSunny(Canvas canvas, Size size) {
    final pulse = 0.92 + 0.08 * math.sin(t * math.pi * 2);
    final cx = size.width * 0.82;
    final cy = size.height * 0.12;

    // outer soft glow
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    glowPaint.color = colorScheme.secondary.withOpacity(0.35 * pulse);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.35, glowPaint);

    glowPaint.color = colorScheme.secondary.withOpacity(0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.2, glowPaint);

    // solid sun core
    final sunPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colorScheme.secondary.withOpacity(0.85);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.08, sunPaint);
  }

  // ── EXTREME SUNNY ────────────────────────────────────────────────────────
  void _paintExtremeSunny(Canvas canvas, Size size) {
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
      shimmerPaint.color = colorScheme.secondary.withOpacity(0.07);
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
      rayPaint.color = colorScheme.secondary.withOpacity(0.22);
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
    glowPaint.color = colorScheme.error.withOpacity(0.38 * pulse);
    canvas.drawCircle(Offset(cx, cy), 140 * pulse, glowPaint);

    glowPaint.color = colorScheme.secondary.withOpacity(0.55 * pulse);
    glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(cx, cy), 70 * pulse, glowPaint);

    // sun disc
    final sunPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colorScheme.secondary;
    canvas.drawCircle(Offset(cx, cy), 40 * pulse, sunPaint);
  }

  @override
  bool shouldRepaint(_WeatherPainter old) =>
      old.t != t || old.state != state;
}
