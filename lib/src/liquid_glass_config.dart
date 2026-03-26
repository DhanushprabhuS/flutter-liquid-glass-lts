import 'package:flutter/material.dart';

/// Shape of a liquid glass element.
enum LiquidGlassShape {
  /// Standard rounded rectangle (superellipse).
  roundedRect,

  /// Perfect circle / ellipse.
  circle,

  /// Pill / capsule shape.
  capsule,

  /// Custom path provided by the caller.
  custom,
}

/// Controls the refraction (light-bending) of the glass.
class RefractionConfig {
  /// How strongly the background is distorted. 0 = none, 1 = full.
  final double strength;

  /// Chromatic aberration — splits RGB channels slightly.
  final double dispersion;

  /// Edge-softness for the refraction mask.
  final double edgeSoftness;

  const RefractionConfig({
    this.strength = 0.18,
    this.dispersion = 0.012,
    this.edgeSoftness = 0.06,
  });

  RefractionConfig copyWith({
    double? strength,
    double? dispersion,
    double? edgeSoftness,
  }) =>
      RefractionConfig(
        strength: strength ?? this.strength,
        dispersion: dispersion ?? this.dispersion,
        edgeSoftness: edgeSoftness ?? this.edgeSoftness,
      );
}

/// Controls the Fresnel rim-reflection effect.
class FresnelConfig {
  /// Whether the Fresnel effect is active.
  final bool enabled;

  /// Intensity of the rim glow.
  final double intensity;

  /// Power / sharpness of the falloff (higher = sharper rim).
  final double power;

  /// Tint colour of the Fresnel reflection.
  final Color color;

  const FresnelConfig({
    this.enabled = true,
    this.intensity = 0.55,
    this.power = 3.5,
    this.color = Colors.white,
  });

  FresnelConfig copyWith({
    bool? enabled,
    double? intensity,
    double? power,
    Color? color,
  }) =>
      FresnelConfig(
        enabled: enabled ?? this.enabled,
        intensity: intensity ?? this.intensity,
        power: power ?? this.power,
        color: color ?? this.color,
      );
}

/// Controls the specular glare highlight on the glass surface.
class GlareConfig {
  /// Whether the glare is visible.
  final bool enabled;

  /// Opacity of the glare highlight.
  final double opacity;

  /// Angle of the glare in degrees (0 = top-left to bottom-right).
  final double angle;

  /// Relative size of the glare spot (0-1 fraction of widget size).
  final double size;

  /// Hardness of the glare edge (0 = soft, 1 = hard).
  final double hardness;

  /// Colour of the glare.
  final Color color;

  const GlareConfig({
    this.enabled = true,
    this.opacity = 0.35,
    this.angle = -35.0,
    this.size = 0.6,
    this.hardness = 0.25,
    this.color = Colors.white,
  });

  GlareConfig copyWith({
    bool? enabled,
    double? opacity,
    double? angle,
    double? size,
    double? hardness,
    Color? color,
  }) =>
      GlareConfig(
        enabled: enabled ?? this.enabled,
        opacity: opacity ?? this.opacity,
        angle: angle ?? this.angle,
        size: size ?? this.size,
        hardness: hardness ?? this.hardness,
        color: color ?? this.color,
      );
}

/// Controls the background blur applied beneath the glass.
class BlurConfig {
  /// Sigma for the Gaussian blur (pixels).
  final double sigma;

  /// Whether the blur is enabled.
  final bool enabled;

  const BlurConfig({
    this.sigma = 18.0,
    this.enabled = true,
  });

  BlurConfig copyWith({double? sigma, bool? enabled}) => BlurConfig(
        sigma: sigma ?? this.sigma,
        enabled: enabled ?? this.enabled,
      );
}

/// Controls the tint / fill overlay of the glass.
class TintConfig {
  /// Base tint colour (alpha is used for opacity).
  final Color color;

  /// Saturation boost applied to the blurred background.
  final double saturationBoost;

  const TintConfig({
    this.color = const Color(0x22FFFFFF),
    this.saturationBoost = 0.0,
  });

  TintConfig copyWith({Color? color, double? saturationBoost}) => TintConfig(
        color: color ?? this.color,
        saturationBoost: saturationBoost ?? this.saturationBoost,
      );
}

/// Controls the smooth-merge (blob) effect between adjacent glass shapes.
class BlobConfig {
  /// Whether blob merging is enabled.
  final bool enabled;

  /// How far apart shapes need to be before they start merging (logical px).
  final double mergeRadius;

  /// Smoothness of the merge joint (higher = rounder blob).
  final double smoothness;

  const BlobConfig({
    this.enabled = true,
    this.mergeRadius = 32.0,
    this.smoothness = 28.0,
  });

  BlobConfig copyWith({
    bool? enabled,
    double? mergeRadius,
    double? smoothness,
  }) =>
      BlobConfig(
        enabled: enabled ?? this.enabled,
        mergeRadius: mergeRadius ?? this.mergeRadius,
        smoothness: smoothness ?? this.smoothness,
      );
}

/// Master configuration for a single liquid glass element.
class LiquidGlassConfig {
  final LiquidGlassShape shape;
  final double borderRadius;
  final RefractionConfig refraction;
  final FresnelConfig fresnel;
  final GlareConfig glare;
  final BlurConfig blur;
  final TintConfig tint;
  final BlobConfig blob;

  /// Optional border drawn around the glass.
  final BorderSide? border;

  /// Shadow depth.
  final List<BoxShadow> shadows;

  const LiquidGlassConfig({
    this.shape = LiquidGlassShape.roundedRect,
    this.borderRadius = 24.0,
    this.refraction = const RefractionConfig(),
    this.fresnel = const FresnelConfig(),
    this.glare = const GlareConfig(),
    this.blur = const BlurConfig(),
    this.tint = const TintConfig(),
    this.blob = const BlobConfig(),
    this.border,
    this.shadows = const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  });

  /// A preset that mimics Apple's default visionOS/iOS26 glass.
  static const LiquidGlassConfig appleDefault = LiquidGlassConfig();

  /// Minimal, nearly-invisible glass for subtle overlays.
  static const LiquidGlassConfig subtle = LiquidGlassConfig(
    refraction: RefractionConfig(strength: 0.08, dispersion: 0.004),
    fresnel: FresnelConfig(intensity: 0.25, power: 5.0),
    glare: GlareConfig(opacity: 0.15),
    blur: BlurConfig(sigma: 8.0),
    tint: TintConfig(color: Color(0x11FFFFFF)),
  );

  /// Bold, highly refractive glass.
  static const LiquidGlassConfig bold = LiquidGlassConfig(
    refraction: RefractionConfig(strength: 0.35, dispersion: 0.025),
    fresnel: FresnelConfig(intensity: 0.80, power: 2.5),
    glare: GlareConfig(opacity: 0.55, size: 0.75),
    blur: BlurConfig(sigma: 28.0),
    tint: TintConfig(color: Color(0x33FFFFFF), saturationBoost: 0.3),
  );

  LiquidGlassConfig copyWith({
    LiquidGlassShape? shape,
    double? borderRadius,
    RefractionConfig? refraction,
    FresnelConfig? fresnel,
    GlareConfig? glare,
    BlurConfig? blur,
    TintConfig? tint,
    BlobConfig? blob,
    BorderSide? border,
    List<BoxShadow>? shadows,
  }) =>
      LiquidGlassConfig(
        shape: shape ?? this.shape,
        borderRadius: borderRadius ?? this.borderRadius,
        refraction: refraction ?? this.refraction,
        fresnel: fresnel ?? this.fresnel,
        glare: glare ?? this.glare,
        blur: blur ?? this.blur,
        tint: tint ?? this.tint,
        blob: blob ?? this.blob,
        border: border ?? this.border,
        shadows: shadows ?? this.shadows,
      );
}
