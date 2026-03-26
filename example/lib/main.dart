import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() => runApp(const LiquidGlassExampleApp());

class LiquidGlassExampleApp extends StatelessWidget {
  const LiquidGlassExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _GalleryPage(),
    );
  }
}

// ============================================================================
// Gallery — scrollable showcase of all presets and features
// ============================================================================
class _GalleryPage extends StatelessWidget {
  const _GalleryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Colourful background ─────────────────────────────────────────
          const _AnimatedBackground(),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: const [
                SizedBox(height: 16),
                _SectionHeader('🔮 Liquid Glass Studio'),
                SizedBox(height: 4),
                _SubHeader('Flutter recreation of Apple\'s Liquid Glass UI'),
                SizedBox(height: 32),

                _SectionHeader('Presets'),
                SizedBox(height: 16),
                _PresetRow(),
                SizedBox(height: 32),

                _SectionHeader('Shapes'),
                SizedBox(height: 16),
                _ShapeRow(),
                SizedBox(height: 32),

                _SectionHeader('Blob Merge Effect'),
                SizedBox(height: 16),
                _BlobDemo(),
                SizedBox(height: 32),

                _SectionHeader('Interactive Controls'),
                SizedBox(height: 16),
                _InteractiveDemo(),
                SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Animated gradient background
// ============================================================================
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * 2 * math.pi;
        return CustomPaint(
          painter: _BgPainter(t),
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  const _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xFF0A0A1A));

    final blobs = [
      (Offset(size.width * (0.2 + 0.15 * math.sin(t * 0.7)),
               size.height * (0.25 + 0.12 * math.cos(t * 0.5))),
       size.width * 0.45,
       const Color(0xFF4F46E5)),
      (Offset(size.width * (0.75 + 0.12 * math.cos(t * 0.6)),
               size.height * (0.4 + 0.15 * math.sin(t * 0.8))),
       size.width * 0.4,
       const Color(0xFFEC4899)),
      (Offset(size.width * (0.5 + 0.18 * math.sin(t * 0.4)),
               size.height * (0.7 + 0.1 * math.cos(t * 0.9))),
       size.width * 0.38,
       const Color(0xFF06B6D4)),
    ];

    for (final (center, radius, color) in blobs) {
      canvas.drawCircle(
        center,
        radius,
        paint
          ..color = color.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

// ============================================================================
// Section helpers
// ============================================================================
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      );
}

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 15,
        ),
      );
}

// ============================================================================
// Preset row
// ============================================================================
class _PresetRow extends StatelessWidget {
  const _PresetRow();

  @override
  Widget build(BuildContext context) {
    final presets = [
      ('Default', LiquidGlassConfig.appleDefault),
      ('Subtle', LiquidGlassConfig.subtle),
      ('Bold', LiquidGlassConfig.bold),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: presets
          .map(
            (p) => LiquidGlassWidget(
              width: 96,
              height: 96,
              config: p.$2.copyWith(shape: LiquidGlassShape.circle),
              child: Center(
                child: Text(
                  p.$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================================
// Shape row
// ============================================================================
class _ShapeRow extends StatelessWidget {
  const _ShapeRow();

  @override
  Widget build(BuildContext context) {
    final shapes = [
      ('Rect', LiquidGlassShape.roundedRect),
      ('Circle', LiquidGlassShape.circle),
      ('Capsule', LiquidGlassShape.capsule),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: shapes
          .map(
            (s) => LiquidGlassWidget(
              width: s.$2 == LiquidGlassShape.capsule ? 110 : 90,
              height: 60,
              config: LiquidGlassConfig.appleDefault.copyWith(shape: s.$2),
              child: Center(
                child: Text(
                  s.$1,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================================
// Blob merge demo
// ============================================================================
class _BlobDemo extends StatefulWidget {
  const _BlobDemo();

  @override
  State<_BlobDemo> createState() => _BlobDemoState();
}

class _BlobDemoState extends State<_BlobDemo> {
  double _gap = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: LiquidGlassBlobGroup(
            config: LiquidGlassConfig.appleDefault,
            blobs: [
              LiquidGlassBlob(
                position: Offset(20 + _gap, 20),
                size: const Size(120, 80),
              ),
              LiquidGlassBlob(
                position: Offset(160 - _gap, 20),
                size: const Size(120, 80),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Gap', style: TextStyle(color: Colors.white54, fontSize: 13)),
            Expanded(
              child: Slider(
                value: _gap,
                min: -40,
                max: 60,
                onChanged: (v) => setState(() => _gap = v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// Interactive parameter controls demo
// ============================================================================
class _InteractiveDemo extends StatefulWidget {
  const _InteractiveDemo();

  @override
  State<_InteractiveDemo> createState() => _InteractiveDemoState();
}

class _InteractiveDemoState extends State<_InteractiveDemo> {
  double _blurSigma = 18;
  double _refractionStrength = 0.18;
  double _dispersion = 0.012;
  double _fresnelIntensity = 0.55;
  double _glareOpacity = 0.35;

  @override
  Widget build(BuildContext context) {
    final config = LiquidGlassConfig(
      shape: LiquidGlassShape.roundedRect,
      borderRadius: 28,
      blur: BlurConfig(sigma: _blurSigma),
      refraction: RefractionConfig(
        strength: _refractionStrength,
        dispersion: _dispersion,
      ),
      fresnel: FresnelConfig(intensity: _fresnelIntensity),
      glare: GlareConfig(opacity: _glareOpacity),
    );

    return Column(
      children: [
        Center(
          child: LiquidGlassWidget(
            width: 260,
            height: 110,
            config: config,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded, color: Colors.white, size: 32),
                  SizedBox(height: 6),
                  Text(
                    'Liquid Glass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _Slider('Blur σ', _blurSigma, 0, 40, (v) => setState(() => _blurSigma = v)),
        _Slider('Refraction', _refractionStrength, 0, 0.5,
            (v) => setState(() => _refractionStrength = v)),
        _Slider('Dispersion', _dispersion, 0, 0.05,
            (v) => setState(() => _dispersion = v)),
        _Slider('Fresnel', _fresnelIntensity, 0, 1.0,
            (v) => setState(() => _fresnelIntensity = v)),
        _Slider('Glare', _glareOpacity, 0, 1.0,
            (v) => setState(() => _glareOpacity = v)),
      ],
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _Slider(this.label, this.value, this.min, this.max, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 44,
          child: Text(
            value.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
