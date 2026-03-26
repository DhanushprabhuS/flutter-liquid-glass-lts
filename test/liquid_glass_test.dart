import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  group('LiquidGlassConfig', () {
    test('copyWith returns updated config', () {
      const cfg = LiquidGlassConfig.appleDefault;
      final updated = cfg.copyWith(borderRadius: 48);
      expect(updated.borderRadius, 48);
      expect(updated.shape, cfg.shape);
    });

    test('appleDefault has expected defaults', () {
      const cfg = LiquidGlassConfig.appleDefault;
      expect(cfg.blur.sigma, 18.0);
      expect(cfg.refraction.strength, 0.18);
      expect(cfg.fresnel.enabled, true);
      expect(cfg.glare.enabled, true);
    });

    test('subtle preset has lower blur sigma', () {
      expect(LiquidGlassConfig.subtle.blur.sigma,
          lessThan(LiquidGlassConfig.appleDefault.blur.sigma));
    });

    test('bold preset has higher blur sigma', () {
      expect(LiquidGlassConfig.bold.blur.sigma,
          greaterThan(LiquidGlassConfig.appleDefault.blur.sigma));
    });
  });

  group('RefractionConfig', () {
    test('copyWith preserves unchanged fields', () {
      const rc = RefractionConfig(strength: 0.3);
      final updated = rc.copyWith(dispersion: 0.05);
      expect(updated.strength, 0.3);
      expect(updated.dispersion, 0.05);
    });
  });

  group('LiquidGlassShapes', () {
    test('smin returns value <= min(a,b)', () {
      final result = LiquidGlassShapes.smin(5, 10, 4);
      expect(result, lessThanOrEqualTo(5));
    });

    test('sdfRoundedRect returns negative inside rect', () {
      final rect = const Rect.fromLTWH(0, 0, 100, 60);
      final inside = LiquidGlassShapes.sdfRoundedRect(
          const Offset(50, 30), rect, 10);
      expect(inside, isNegative);
    });

    test('sdfCircle returns negative inside circle', () {
      final rect = const Rect.fromLTWH(0, 0, 100, 100);
      final inside = LiquidGlassShapes.sdfCircle(const Offset(50, 50), rect);
      expect(inside, isNegative);
    });
  });

  group('LiquidGlassWidget renders', () {
    testWidgets('builds without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: LiquidGlassWidget(
                width: 120,
                height: 60,
                config: LiquidGlassConfig.appleDefault,
                child: SizedBox(),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LiquidGlassWidget), findsOneWidget);
    });

    testWidgets('renders circle shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassWidget(
              width: 80,
              height: 80,
              config: LiquidGlassConfig.appleDefault.copyWith(
                shape: LiquidGlassShape.circle,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LiquidGlassWidget), findsOneWidget);
    });
  });

  group('LiquidGlassBlobGroup renders', () {
    testWidgets('builds with two blobs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: LiquidGlassBlobGroup(
                blobs: const [
                  LiquidGlassBlob(position: Offset(20, 20), size: Size(120, 60)),
                  LiquidGlassBlob(position: Offset(160, 20), size: Size(120, 60)),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LiquidGlassBlobGroup), findsOneWidget);
    });
  });
}
