import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sileo_glass/sileo_glass.dart';

void main() {
  group('buildSileoGooeyPath', () {
    test('produces exact pill bounds when bodyHeight is zero', () {
      final path = buildSileoGooeyPath(
        width: 350,
        pillHeight: 40,
        pillX: 210,
        pillWidth: 140,
        bodyHeight: 0,
        roundness: 16,
      );

      final bounds = path.getBounds();
      expect(bounds.left, closeTo(210, 0.5));
      expect(bounds.top, closeTo(0, 0.5));
      expect(bounds.right, closeTo(350, 0.5));
      expect(bounds.bottom, closeTo(40, 0.5));

      expect(path.contains(const Offset(280, 20)), isTrue);
      expect(path.contains(const Offset(50, 20)), isFalse);
    });

    test('produces unified stepped silhouette for left-aligned downward expansion', () {
      final path = buildSileoGooeyPath(
        width: 350,
        pillHeight: 40,
        pillX: 0,
        pillWidth: 140,
        bodyHeight: 100,
        roundness: 16,
      );

      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 0.5));
      expect(bounds.top, closeTo(0, 0.5));
      expect(bounds.right, closeTo(350, 0.5));
      expect(bounds.bottom, closeTo(140, 0.5));

      // Inside pill
      expect(path.contains(const Offset(70, 20)), isTrue);
      // Inside body
      expect(path.contains(const Offset(175, 90)), isTrue);
      // Inside concave neck fillet (slightly right of pill, just above y=40)
      expect(path.contains(const Offset(143, 37)), isTrue);
      // Outside above right shoulder
      expect(path.contains(const Offset(300, 10)), isFalse);
    });

    test('produces symmetric stepped silhouette for center-aligned expansion', () {
      final path = buildSileoGooeyPath(
        width: 350,
        pillHeight: 40,
        pillX: 105,
        pillWidth: 140,
        bodyHeight: 90,
        roundness: 16,
      );

      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 0.5));
      expect(bounds.right, closeTo(350, 0.5));
      expect(bounds.bottom, closeTo(130, 0.5));

      // Outside both top-left and top-right shoulders
      expect(path.contains(const Offset(20, 10)), isFalse);
      expect(path.contains(const Offset(330, 10)), isFalse);
      // Inside center pill and body
      expect(path.contains(const Offset(175, 20)), isTrue);
      expect(path.contains(const Offset(175, 85)), isTrue);
    });

    test('mirrors vertically when expandDownward is false', () {
      final path = buildSileoGooeyPath(
        width: 350,
        pillHeight: 40,
        pillX: 210,
        pillWidth: 140,
        bodyHeight: 100,
        roundness: 16,
        expandDownward: false,
      );

      final bounds = path.getBounds();
      expect(bounds.top, closeTo(0, 0.5));
      expect(bounds.bottom, closeTo(140, 0.5));

      // Body now sits at the top [0..100]
      expect(path.contains(const Offset(50, 50)), isTrue);
      // Pill now sits at bottom-right [210..350, 100..140]
      expect(path.contains(const Offset(280, 120)), isTrue);
      // Bottom-left empty space below body shoulder is excluded
      expect(path.contains(const Offset(30, 130)), isFalse);
    });

    test('handles degenerate and extreme parameter values safely', () {
      for (final bodyHeight in <double>[-10, 0, 2, 12, 32, 220]) {
        for (final roundness in <double>[-5, 0, 8, 16, 40]) {
          for (final pillWidth in <double>[0, 40, 200, 350, 500]) {
            final path = buildSileoGooeyPath(
              width: 350,
              pillHeight: 40,
              pillX: 100,
              pillWidth: pillWidth,
              bodyHeight: bodyHeight,
              roundness: roundness,
            );
            final bounds = path.getBounds();
            expect(bounds.isFinite, isTrue);
            expect(bounds.width, greaterThan(0));
            expect(bounds.height, greaterThan(0));
          }
        }
      }
    });

    test('SileoGooeyPainter.shouldRepaint reacts only to actual changes', () {
      const a = SileoGooeyPainter(
        pillHeight: 40,
        pillX: 0,
        pillWidth: 120,
        bodyHeight: 80,
        roundness: 16,
        fill: Color(0xFF1A1A1A),
        expandDownward: true,
      );
      const same = SileoGooeyPainter(
        pillHeight: 40,
        pillX: 0,
        pillWidth: 120,
        bodyHeight: 80,
        roundness: 16,
        fill: Color(0xFF1A1A1A),
        expandDownward: true,
      );
      const changed = SileoGooeyPainter(
        pillHeight: 40,
        pillX: 0,
        pillWidth: 120,
        bodyHeight: 81,
        roundness: 16,
        fill: Color(0xFF1A1A1A),
        expandDownward: true,
      );

      expect(a.shouldRepaint(same), isFalse);
      expect(a.shouldRepaint(changed), isTrue);
    });

    test('tapers width smoothly with zero snap as body approaches pill', () {
      var prevWidth = 0.0;
      for (var b = 0.0; b <= 64.0; b += 1.0) {
        final path = buildSileoGooeyPath(
          width: 350,
          pillHeight: 40,
          pillX: 105,
          pillWidth: 140,
          bodyHeight: b,
          roundness: 16,
        );
        final w = path.getBounds().width;
        if (b > 0.0) {
          // Width must grow monotonically without abrupt jumps (> 12px per 1px height step).
          expect(w, greaterThanOrEqualTo(prevWidth - 0.01));
          expect(w - prevWidth, lessThan(12.0));
        }
        // Near pill attachment (b <= 2px), width stays flush with pill (zero side sliver).
        if (b <= 2.0) {
          expect(w, closeTo(140.0, 0.2));
        }
        prevWidth = w;
      }
      expect(prevWidth, closeTo(350.0, 0.5));
    });
  });
}
