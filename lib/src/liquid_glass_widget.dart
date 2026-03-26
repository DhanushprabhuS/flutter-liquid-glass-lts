import 'dart:ui';

import 'package:flutter/material.dart';

import 'liquid_glass_config.dart';
import 'liquid_glass_painter.dart';
import 'liquid_glass_shapes.dart';

/// A widget that renders an Apple-inspired liquid glass pane over its
/// background.
///
/// Wrap any content (icons, text, buttons) in [LiquidGlassWidget] to give it
/// the glass treatment:
///
/// ```dart
/// LiquidGlassWidget(
///   config: LiquidGlassConfig.appleDefault,
///   width: 200,
///   height: 80,
///   child: Center(child: Text('Hello', style: TextStyle(color: Colors.white))),
/// )
/// ```
///
/// The widget uses [BackdropFilter] for the blur layer so it must be placed
/// over a painted background (image, gradient, etc.) to look correct.
class LiquidGlassWidget extends StatefulWidget {
  /// Width of the glass pane.  Required unless [expand] is true.
  final double? width;

  /// Height of the glass pane.  Required unless [expand] is true.
  final double? height;

  /// When true the widget fills its parent (ignores [width] / [height]).
  final bool expand;

  /// Visual configuration.
  final LiquidGlassConfig config;

  /// Optional child rendered on top of the glass surface.
  final Widget? child;

  /// Custom path provider for [LiquidGlassShape.custom].
  final Path Function(Size)? customPathBuilder;

  /// Drives the shimmer and glare pulse animation.
  /// If null a built-in looping animation is used.
  final Animation<double>? animation;

  const LiquidGlassWidget({
    super.key,
    this.width,
    this.height,
    this.expand = false,
    this.config = LiquidGlassConfig.appleDefault,
    this.child,
    this.customPathBuilder,
    this.animation,
  });

  @override
  State<LiquidGlassWidget> createState() => _LiquidGlassWidgetState();
}

class _LiquidGlassWidgetState extends State<LiquidGlassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _internal;

  Animation<double> get _anim =>
      widget.animation ?? _internal;

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
    Widget glass = AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) {
        return _GlassBody(
          config: widget.config,
          animationValue: _anim.value,
          customPathBuilder: widget.customPathBuilder,
          child: child,
        );
      },
      child: widget.child,
    );

    if (widget.expand) {
      return glass;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: glass,
    );
  }
}

class _GlassBody extends StatelessWidget {
  final LiquidGlassConfig config;
  final double animationValue;
  final Widget? child;
  final Path Function(Size)? customPathBuilder;

  const _GlassBody({
    required this.config,
    required this.animationValue,
    this.child,
    this.customPathBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final size = constraints.biggest;
      final rect = Offset.zero & size;

      Path shapePath = customPathBuilder != null
          ? customPathBuilder!(size)
          : LiquidGlassShapes.pathFor(
              config.shape,
              rect,
              borderRadius: config.borderRadius,
            );

      return Stack(
        fit: StackFit.expand,
        children: [
          // ── Backdrop blur layer ───────────────────────────────────────
          if (config.blur.enabled)
            ClipPath(
              clipper: _PathClipper(shapePath),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: config.blur.sigma,
                  sigmaY: config.blur.sigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),

          // ── All glass effects (painted on top of blur) ────────────────
          CustomPaint(
            painter: LiquidGlassPainter(
              config: config,
              animationValue: animationValue,
            ),
            child: ClipPath(
              clipper: _PathClipper(shapePath),
              child: child,
            ),
          ),
        ],
      );
    });
  }
}

class _PathClipper extends CustomClipper<Path> {
  final Path path;
  const _PathClipper(this.path);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}
