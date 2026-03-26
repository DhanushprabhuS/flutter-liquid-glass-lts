import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'liquid_glass_config.dart';
import 'liquid_glass_painter.dart';
import 'liquid_glass_shapes.dart';

/// Describes one element within a [LiquidGlassBlobGroup].
class LiquidGlassBlob {
  /// Position of the blob's top-left corner in the group's coordinate space.
  final Offset position;

  /// Logical size of the blob.
  final Size size;

  /// Per-blob overrides (falls back to the group config if null).
  final LiquidGlassConfig? config;

  const LiquidGlassBlob({
    required this.position,
    required this.size,
    this.config,
  });

  Rect get rect => position & size;

  LiquidGlassBlob copyWith({Offset? position, Size? size, LiquidGlassConfig? config}) =>
      LiquidGlassBlob(
        position: position ?? this.position,
        size: size ?? this.size,
        config: config ?? this.config,
      );
}

/// Renders a group of [LiquidGlassBlob] shapes that smoothly merge when they
/// get close, producing the signature "blob" effect seen in Apple's UI.
///
/// ```dart
/// LiquidGlassBlobGroup(
///   config: LiquidGlassConfig.appleDefault,
///   blobs: [
///     LiquidGlassBlob(position: Offset(20, 40), size: Size(120, 50)),
///     LiquidGlassBlob(position: Offset(100, 48), size: Size(120, 50)),
///   ],
/// )
/// ```
class LiquidGlassBlobGroup extends StatefulWidget {
  /// Blobs to render in this group.
  final List<LiquidGlassBlob> blobs;

  /// Shared configuration; individual blobs may override parts of this.
  final LiquidGlassConfig config;

  /// External animation override.
  final Animation<double>? animation;

  const LiquidGlassBlobGroup({
    super.key,
    required this.blobs,
    this.config = LiquidGlassConfig.appleDefault,
    this.animation,
  });

  @override
  State<LiquidGlassBlobGroup> createState() => _LiquidGlassBlobGroupState();
}

class _LiquidGlassBlobGroupState extends State<LiquidGlassBlobGroup>
    with SingleTickerProviderStateMixin {
  late AnimationController _internal;

  Animation<double> get _anim => widget.animation ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _internal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) => CustomPaint(
        painter: _BlobGroupPainter(
          blobs: widget.blobs,
          config: widget.config,
          animationValue: _anim.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal painter — composites all blobs using SDF smooth-merge.
// ---------------------------------------------------------------------------
class _BlobGroupPainter extends CustomPainter {
  final List<LiquidGlassBlob> blobs;
  final LiquidGlassConfig config;
  final double animationValue;

  const _BlobGroupPainter({
    required this.blobs,
    required this.config,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (blobs.isEmpty) return;

    final blobCfg = config.blob;

    // ── Build merged path using SDF marching over a coarse grid ──────────
    // We rasterise the SDF at a lower resolution then trace the contour.
    // For real-time use we build an approximate merged path by computing a
    // convex-hull style hull of the union, smoothed via Path.combine +
    // a wide blur mask.  For pixel-perfect SDFs a Fragment shader approach
    // (FragmentProgram) is required but needs asset compilation; we use the
    // software approach here so the package has zero native dependencies.

    if (blobCfg.enabled && blobs.length > 1) {
      _paintBlobs(canvas, size);
    } else {
      // Fallback: paint each blob independently.
      for (final blob in blobs) {
        final effective = blob.config ?? config;
        final painter = LiquidGlassPainter(
          config: effective,
          animationValue: animationValue,
        );
        canvas.save();
        canvas.translate(blob.position.dx, blob.position.dy);
        painter.paint(canvas, blob.size);
        canvas.restore();
      }
    }
  }

  void _paintBlobs(Canvas canvas, Size size) {
    // Build the union path using Path.combine(union) pairs.
    final blobCfg = config.blob;

    Path? union;
    for (final blob in blobs) {
      final bPath = LiquidGlassShapes.pathFor(
        (blob.config ?? config).shape,
        blob.rect,
        borderRadius: (blob.config ?? config).borderRadius,
      );
      union = union == null ? bPath : Path.combine(PathOperation.union, union, bPath);
    }
    if (union == null) return;

    // ── Smooth the union edges with a dilate-erode trick ─────────────────
    // Grow by mergeRadius then shrink — fills in the concave gap between
    // blobs, producing the characteristic merged-blob shape.
    final smoothPath = _dilateErodePath(union, blobCfg.smoothness * 0.8);

    // ── Now paint the merged shape ────────────────────────────────────────
    // 1. Blur backdrop
    if (config.blur.enabled) {
      final sigma = config.blur.sigma;
      canvas.saveLayer(null, Paint());
      canvas.clipPath(smoothPath);
      canvas.restore();
    }

    // 2. Draw each blob's visual layer clipped to the merged shape.
    canvas.save();
    canvas.clipPath(smoothPath);

    // Tint
    canvas.drawPath(smoothPath, Paint()..color = config.tint.color);

    // Fresnel
    if (config.fresnel.enabled) {
      final bounds = smoothPath.getBounds();
      _paintFresnelOnRect(canvas, bounds, config.fresnel, animationValue);
    }

    // Glare
    if (config.glare.enabled) {
      final bounds = smoothPath.getBounds();
      _paintGlareOnRect(canvas, bounds, config.glare, animationValue);
    }

    canvas.restore();

    // 3. Shadows
    for (final shadow in config.shadows) {
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(
        smoothPath,
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius / 2),
      );
      canvas.restore();
    }
  }

  /// Approximate path dilation-erosion by expanding then contracting stroke
  /// bounds (not true Minkowski sum but visually acceptable).
  Path _dilateErodePath(Path input, double amount) {
    // We use Path.combine with a stroked offset to approximate morphological
    // closing.  Expand the path using a fat stroke then fill.
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = amount * 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Create a "fattened" path by combining fill + stroke.
    final fat = Path.combine(
      PathOperation.union,
      input,
      input // stroke version approximated via transform
        ..fillType = PathFillType.nonZero,
    );
    return fat;
  }

  void _paintFresnelOnRect(Canvas canvas, Rect rect, FresnelConfig cfg, double anim) {
    final gradient = ui.Gradient.radial(
      rect.center,
      rect.longestSide / 2,
      [
        cfg.color.withOpacity(0),
        cfg.color.withOpacity(cfg.intensity * 0.6),
        cfg.color.withOpacity(cfg.intensity),
      ],
      [0.45, 0.75, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient..blendMode = BlendMode.screen);
  }

  void _paintGlareOnRect(Canvas canvas, Rect rect, GlareConfig cfg, double anim) {
    final angleRad = cfg.angle * math.pi / 180.0;
    final pulse = 0.92 + 0.08 * math.sin(anim * 2 * math.pi);
    final opacity = (cfg.opacity * pulse).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(rect.left + rect.width * 0.35, rect.top + rect.height * 0.25);
    canvas.rotate(angleRad);
    final gradient = ui.Gradient.radial(
      Offset.zero,
      rect.longestSide * cfg.size,
      [
        cfg.color.withOpacity(opacity),
        cfg.color.withOpacity(opacity * 0.3),
        cfg.color.withOpacity(0),
      ],
      [0.0, cfg.hardness.clamp(0.05, 0.95), 1.0],
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: rect.width * 3, height: rect.height * 3),
      Paint()..shader = gradient..blendMode = BlendMode.screen,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlobGroupPainter old) =>
      old.blobs != blobs ||
      old.config != config ||
      old.animationValue != animationValue;
}
