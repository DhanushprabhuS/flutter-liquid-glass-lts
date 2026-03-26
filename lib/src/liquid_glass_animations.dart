import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Spring simulation presets for liquid glass shape animations.
abstract class LiquidGlassSprings {
  LiquidGlassSprings._();

  /// Gentle, slow spring — suitable for layout transitions.
  static const SpringDescription gentle = SpringDescription(
    mass: 1.0,
    stiffness: 180,
    damping: 22,
  );

  /// Snappy, iOS-like spring.
  static const SpringDescription snappy = SpringDescription(
    mass: 1.0,
    stiffness: 400,
    damping: 28,
  );

  /// Bouncy spring with a slight overshoot.
  static const SpringDescription bouncy = SpringDescription(
    mass: 1.0,
    stiffness: 320,
    damping: 16,
  );
}

/// A mixin that adds a looping shimmer [AnimationController] to a [State].
///
/// Usage:
/// ```dart
/// class _MyState extends State<MyWidget> with LiquidGlassShimmerMixin {
///   @override
///   Widget build(BuildContext context) {
///     return LiquidGlassWidget(
///       animationValue: shimmerValue,
///       ...
///     );
///   }
/// }
/// ```
mixin LiquidGlassShimmerMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  late final AnimationController _shimmerController;

  /// Current normalised shimmer value [0, 1].
  double get shimmerValue => _shimmerController.value;

  /// Raw [Animation<double>] in case you need to attach listeners.
  Animation<double> get shimmerAnimation => _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
}

/// Animates a [Size] change using a spring simulation.
class SpringSizeAnimation extends StatefulWidget {
  final Size targetSize;
  final SpringDescription spring;
  final Widget Function(BuildContext, Size) builder;

  const SpringSizeAnimation({
    super.key,
    required this.targetSize,
    required this.builder,
    this.spring = LiquidGlassSprings.snappy,
  });

  @override
  State<SpringSizeAnimation> createState() => _SpringSizeAnimationState();
}

class _SpringSizeAnimationState extends State<SpringSizeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Size?> _sizeAnim;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _lastSize = widget.targetSize;
    _controller = AnimationController.unbounded(vsync: this);
    _sizeAnim = _controller.drive(
      SizeTween(begin: widget.targetSize, end: widget.targetSize),
    );
  }

  @override
  void didUpdateWidget(SpringSizeAnimation old) {
    super.didUpdateWidget(old);
    if (old.targetSize != widget.targetSize) {
      final sim = SpringSimulation(
        widget.spring,
        0,
        1,
        0,
      );
      _sizeAnim = _controller.drive(
        SizeTween(begin: _lastSize, end: widget.targetSize),
      );
      _controller
        ..value = 0
        ..animateWith(sim);
      _lastSize = widget.targetSize;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sizeAnim,
      builder: (ctx, _) =>
          widget.builder(ctx, _sizeAnim.value ?? widget.targetSize),
    );
  }
}
