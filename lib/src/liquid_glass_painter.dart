import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'liquid_glass_config.dart';
import 'liquid_glass_shapes.dart';

/// [CustomPainter] that renders a single liquid glass pane.
///
/// All effect layers are composited in software:
///   1. Drop shadow
///   2. Clipped backdrop blur + colour tint
///   3. Refraction / dispersion fringe on the border
///   4. Fresnel rim glow
///   5. Specular glare highlight
///   6. Optional stroke border
class LiquidGlassPainter extends CustomPainter {
  final LiquidGlassConfig config;

  /// Animation progress [0, 1] – drives subtle "breathe" / shimmer.
  final double animationValue;

  const LiquidGlassPainter({
    required this.config,
    this.animationValue = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = LiquidGlassShapes.pathFor(
      config.shape,
      rect,
      borderRadius: config.borderRadius,
    );

    // ── 1. Drop shadows ────────────────────────────────────────────────────
    for (final shadow in config.shadows) {
      final shadowPaint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius / 2);
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    // ── 2. Clip all subsequent drawing to the glass shape ─────────────────
    canvas.save();
    canvas.clipPath(path);

    // ── 2a. Tint fill ─────────────────────────────────────────────────────
    final tintPaint = Paint()..color = config.tint.color;
    canvas.drawRect(rect, tintPaint);

    // ── 3. Refraction / dispersion fringe ─────────────────────────────────
    _paintRefractionFringe(canvas, size, path);

    // ── 4. Fresnel rim glow ───────────────────────────────────────────────
    if (config.fresnel.enabled) {
      _paintFresnel(canvas, size);
    }

    // ── 5. Specular glare ─────────────────────────────────────────────────
    if (config.glare.enabled) {
      _paintGlare(canvas, size);
    }

    canvas.restore(); // end clip

    // ── 6. Optional stroke border ─────────────────────────────────────────
    if (config.border != null) {
      final bp = config.border!;
      final borderPaint = Paint()
        ..color = bp.color
        ..strokeWidth = bp.width
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // Refraction fringe: a thin iridescent band painted along the inside edge.
  // ---------------------------------------------------------------------------
  void _paintRefractionFringe(Canvas canvas, Size size, Path shapePath) {
    final cfg = config.refraction;
    if (cfg.strength <= 0) return;

    final fringeWidth = size.shortestSide * cfg.edgeSoftness.clamp(0.02, 0.15);

    // Build an inner path slightly inset from the outer shape.
    final innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - fringeWidth * 2,
      height: size.height - fringeWidth * 2,
    );
    final innerPath = LiquidGlassShapes.pathFor(
      config.shape,
      innerRect,
      borderRadius: (config.borderRadius - fringeWidth).clamp(0, double.infinity),
    );

    // Fringe region = outer minus inner.
    final fringePath = Path.combine(
      PathOperation.difference,
      shapePath,
      innerPath,
    );

    // Animated shimmer offset.
    final shimmer = math.sin(animationValue * 2 * math.pi) * 0.5 + 0.5;

    // Dispersion colours (R, G, B offset versions).
    final disp = cfg.dispersion;
    final alphaBase = (cfg.strength * 180).clamp(0, 255).round();

    // Red channel shifted left-up
    canvas.drawPath(
      fringePath,
      Paint()
        ..color = Color.fromARGB(
          (alphaBase * (0.6 + 0.2 * shimmer)).round().clamp(0, 255),
          255,
          60,
          60,
        )
        ..blendMode = BlendMode.screen
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, fringeWidth * disp * 40),
    );

    // Blue channel shifted right-down
    canvas.drawPath(
      fringePath,
      Paint()
        ..color = Color.fromARGB(
          (alphaBase * (0.5 + 0.15 * shimmer)).round().clamp(0, 255),
          60,
          120,
          255,
        )
        ..blendMode = BlendMode.screen
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, fringeWidth * disp * 35),
    );

    // White-ish core fringe
    canvas.drawPath(
      fringePath,
      Paint()
        ..color = Color.fromARGB(
          (alphaBase * 0.4).round().clamp(0, 255),
          220,
          235,
          255,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, fringeWidth * 0.5),
    );
  }

  // ---------------------------------------------------------------------------
  // Fresnel rim: a gradient that is bright at the edges, dark in the centre.
  // ---------------------------------------------------------------------------
  void _paintFresnel(Canvas canvas, Size size) {
    final cfg = config.fresnel;
    final power = cfg.power.clamp(1.0, 10.0);
    final innerScale = math.pow(0.55, 1.0 / power).toDouble();

    final rect = Offset.zero & size;

    final gradient = ui.Gradient.radial(
      rect.center,
      rect.longestSide / 2,
      [
        cfg.color.withValues(alpha: 0),
        cfg.color.withValues(alpha: cfg.intensity * 0.6),
        cfg.color.withValues(alpha: cfg.intensity),
      ],
      [innerScale * 0.55, innerScale, 1.0],
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = gradient
        ..blendMode = BlendMode.screen,
    );
  }

  // ---------------------------------------------------------------------------
  // Glare: a soft diagonal highlight, like a specular light source reflection.
  // ---------------------------------------------------------------------------
  void _paintGlare(Canvas canvas, Size size) {
    final cfg = config.glare;
    final angleRad = cfg.angle * math.pi / 180.0;
    final cx = size.width * 0.35;
    final cy = size.height * 0.25;
    final radius = size.longestSide * cfg.size;

    // Animate a subtle intensity pulse.
    final pulse = 0.92 + 0.08 * math.sin(animationValue * 2 * math.pi);
    final opacity = (cfg.opacity * pulse).clamp(0.0, 1.0);

    // Elliptical glare by applying a rotation transform.
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angleRad);

    final gradient = ui.Gradient.radial(
      Offset.zero,
      radius,
      [
        cfg.color.withValues(alpha: opacity),
        cfg.color.withValues(alpha: opacity * (1 - cfg.hardness) * 0.3),
        cfg.color.withValues(alpha: 0),
      ],
      [0.0, cfg.hardness.clamp(0.05, 0.95), 1.0],
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 2,
        height: size.height * 2,
      ),
      Paint()
        ..shader = gradient
        ..blendMode = BlendMode.screen,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiquidGlassPainter old) =>
      old.config != config || old.animationValue != animationValue;
}
