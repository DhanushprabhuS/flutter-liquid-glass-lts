# 🔮 liquid_glass

**Apple-inspired Liquid Glass UI effects for Flutter.**

A Flutter-native recreation of the liquid glass aesthetic introduced in Apple's visionOS and iOS 26, featuring:

- 🌊 **Refraction** — distorts the background through the glass
- 🌈 **Chromatic dispersion** — RGB fringe on the edges
- 💎 **Fresnel reflection** — bright rim glow at glancing angles
- ✨ **Specular glare** — animated diagonal highlight
- 🫧 **Blob merging** — shapes smoothly merge when close
- 🌫 **Gaussian blur** — `BackdropFilter`-based background blur
- 🎨 **Presets** — `appleDefault`, `subtle`, `bold`
- 🏃 **Animations** — spring-based and looping shimmer

No native plugins required.  Works on iOS, Android, Web, macOS, Windows, Linux.

---

## Installation

```yaml
dependencies:
  liquid_glass: ^0.1.0
```

---

## Quick start

```dart
import 'package:liquid_glass/liquid_glass.dart';

// Wrap any widget in a glass pane
LiquidGlassWidget(
  width: 200,
  height: 80,
  config: LiquidGlassConfig.appleDefault,
  child: Center(
    child: Text('Hello', style: TextStyle(color: Colors.white)),
  ),
)
```

> **Important**: `LiquidGlassWidget` uses `BackdropFilter` for the blur layer.  
> Place it over a painted background (image, gradient, etc.) to see the full effect.

---

## Widgets

### `LiquidGlassWidget`

The primary single-pane glass widget.

| Property | Type | Default | Description |
|---|---|---|---|
| `width` | `double?` | — | Pane width (ignored when `expand: true`) |
| `height` | `double?` | — | Pane height |
| `expand` | `bool` | `false` | Fill parent |
| `config` | `LiquidGlassConfig` | `appleDefault` | All visual settings |
| `child` | `Widget?` | — | Content rendered on the glass |
| `animation` | `Animation<double>?` | (internal loop) | Drive shimmer externally |
| `customPathBuilder` | `Path Function(Size)?` | — | Custom clip path |

### `LiquidGlassBlobGroup`

Renders multiple glass shapes that **smoothly merge** when close.

```dart
LiquidGlassBlobGroup(
  config: LiquidGlassConfig.appleDefault,
  blobs: [
    LiquidGlassBlob(position: Offset(20, 40), size: Size(120, 50)),
    LiquidGlassBlob(position: Offset(100, 48), size: Size(120, 50)),
  ],
)
```

---

## Configuration

### `LiquidGlassConfig`

```dart
const LiquidGlassConfig(
  shape: LiquidGlassShape.roundedRect,  // roundedRect | circle | capsule | custom
  borderRadius: 24.0,
  refraction: RefractionConfig(
    strength: 0.18,       // 0–1, how much the background is bent
    dispersion: 0.012,    // chromatic aberration split
    edgeSoftness: 0.06,   // fringe band width
  ),
  fresnel: FresnelConfig(
    enabled: true,
    intensity: 0.55,
    power: 3.5,           // sharpness of the rim
    color: Colors.white,
  ),
  glare: GlareConfig(
    enabled: true,
    opacity: 0.35,
    angle: -35.0,         // degrees
    size: 0.6,
    hardness: 0.25,       // 0 = soft, 1 = hard
    color: Colors.white,
  ),
  blur: BlurConfig(
    sigma: 18.0,
    enabled: true,
  ),
  tint: TintConfig(
    color: Color(0x22FFFFFF),
    saturationBoost: 0.0,
  ),
  blob: BlobConfig(
    enabled: true,
    mergeRadius: 32.0,
    smoothness: 28.0,
  ),
  shadows: [BoxShadow(...)],
)
```

### Built-in presets

```dart
LiquidGlassConfig.appleDefault  // standard visionOS-like glass
LiquidGlassConfig.subtle        // very light touch
LiquidGlassConfig.bold          // dramatic refraction + heavy blur
```

---

## Animations

### Auto shimmer

Every `LiquidGlassWidget` runs a built-in 5-second looping shimmer
that gently animates the glare and refraction fringe.  Pass your own
`Animation<double>` via the `animation` property to drive it externally.

### Spring animations

```dart
import 'package:liquid_glass/liquid_glass.dart';

SpringSizeAnimation(
  targetSize: Size(200, 80),
  spring: LiquidGlassSprings.snappy,
  builder: (context, size) => LiquidGlassWidget(
    width: size.width,
    height: size.height,
    config: LiquidGlassConfig.appleDefault,
  ),
)
```

Available spring presets: `LiquidGlassSprings.gentle`, `.snappy`, `.bouncy`.

### Shimmer mixin

```dart
class _MyState extends State<MyWidget>
    with SingleTickerProviderStateMixin, LiquidGlassShimmerMixin {
  @override
  Widget build(BuildContext context) {
    return LiquidGlassWidget(
      animation: shimmerAnimation,
      config: LiquidGlassConfig.appleDefault,
    );
  }
}
```

---

## Custom shapes

```dart
LiquidGlassWidget(
  width: 200,
  height: 100,
  config: LiquidGlassConfig.appleDefault.copyWith(
    shape: LiquidGlassShape.custom,
  ),
  customPathBuilder: (size) {
    // Draw a star, speech bubble, etc.
    final path = Path();
    // ... your path commands ...
    return path;
  },
)
```

---

## SDF utilities

The `LiquidGlassShapes` class exposes the underlying signed-distance
functions if you want to build your own effects:

```dart
// Scalar smooth-minimum (blob merge basis)
double merged = LiquidGlassShapes.smin(distA, distB, smoothness);

// Is a point inside a rounded rect?
double d = LiquidGlassShapes.sdfRoundedRect(point, rect, radius);
// d < 0  →  inside
// d >= 0 →  outside
```

---

## Running the example

```bash
cd example
flutter run
```

---

## Technical notes

- The blur layer is implemented with Flutter's built-in `BackdropFilter` +
  `ImageFilter.blur`, which delegates to the platform's GPU compositor.
- Refraction, Fresnel, and glare are rendered in software via `CustomPainter`
  using `ui.Gradient.radial`, blend modes, and `MaskFilter`.
- The blob-merge path is computed with `Path.combine(PathOperation.union)`
  supplemented by a dilation-erosion approximation.
- For pixel-perfect SDF-based merging on GPU, you can integrate Flutter's
  `FragmentProgram` API with the GLSL shaders in `shaders/` (see TODO).

---

## License

MIT © 2025 – inspired by [liquid-glass-studio](https://github.com/iyinchao/liquid-glass-studio) (MIT)
