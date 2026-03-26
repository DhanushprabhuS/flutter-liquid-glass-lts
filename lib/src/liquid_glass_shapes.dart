import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'liquid_glass_config.dart';

/// Utility methods for building and querying liquid-glass shapes.
abstract class LiquidGlassShapes {
  LiquidGlassShapes._();

  /// Returns the [Path] for [shape] inside [rect] with [borderRadius].
  static Path pathFor(
    LiquidGlassShape shape,
    Rect rect, {
    double borderRadius = 24,
    Path? customPath,
  }) {
    switch (shape) {
      case LiquidGlassShape.roundedRect:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(borderRadius.clamp(0, rect.shortestSide / 2)),
            ),
          );
      case LiquidGlassShape.circle:
        return Path()..addOval(rect);
      case LiquidGlassShape.capsule:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(rect.shortestSide / 2),
            ),
          );
      case LiquidGlassShape.custom:
        return customPath ?? (Path()..addRect(rect));
    }
  }

  /// Smooth-minimum (polynomial) — the scalar basis for blob merging.
  ///
  /// Returns a value ≤ min(a, b); lower [k] = sharper join.
  static double smin(double a, double b, double k) {
    final h = (k - (a - b).abs()).clamp(0.0, k);
    return math.min(a, b) - h * h * 0.25 / k;
  }

  /// Signed distance from [point] to the rounded-rect defined by [rect] /
  /// [radius].  Negative = inside.
  static double sdfRoundedRect(Offset point, Rect rect, double radius) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final hw = rect.width / 2 - radius;
    final hh = rect.height / 2 - radius;
    final qx = (point.dx - cx).abs() - hw;
    final qy = (point.dy - cy).abs() - hh;
    return math.sqrt(
              math.max(qx, 0) * math.max(qx, 0) +
                  math.max(qy, 0) * math.max(qy, 0),
            ) +
        math.min(math.max(qx, qy), 0.0) -
        radius;
  }

  /// Signed distance from [point] to a circle centred on [rect].
  static double sdfCircle(Offset point, Rect rect) {
    final r = rect.shortestSide / 2;
    final dx = point.dx - rect.center.dx;
    final dy = point.dy - rect.center.dy;
    return math.sqrt(dx * dx + dy * dy) - r;
  }
}
