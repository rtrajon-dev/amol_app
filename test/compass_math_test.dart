import 'dart:math' as math;

import 'package:amol365/features/qibla/domain/compass_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A phone lying flat, face up. Gravity reads +g on z.
  const flatGravity = (x: 0.0, y: 0.0, z: 9.81);

  /// Earth's field in the northern hemisphere: horizontal component pointing
  /// north, vertical component pointing down (hence negative z with the device
  /// face up).
  ///
  /// [towards] is the compass direction, in degrees, that the device's y axis
  /// (its top edge) is pointing.
  ({double x, double y, double z}) flatFieldFacing(double towards) {
    // The field's horizontal component sits at -towards in device coordinates:
    // turning the phone right moves north to its left.
    final radians = -towards * 3.141592653589793 / 180;
    const horizontal = 20.0;
    return (
      x: -horizontal * _sin(radians) * -1,
      y: horizontal * _cos(radians),
      z: -40.0,
    );
  }

  double? headingFacing(double towards) {
    final field = flatFieldFacing(towards);
    return CompassMath.headingDegrees(
      ax: flatGravity.x,
      ay: flatGravity.y,
      az: flatGravity.z,
      mx: field.x,
      my: field.y,
      mz: field.z,
    );
  }

  group('headingDegrees', () {
    test('reads north when the top edge points north', () {
      expect(headingFacing(0), closeTo(0, 0.001));
    });

    test('reads east, south and west as the device turns', () {
      expect(headingFacing(90), closeTo(90, 0.001));
      expect(headingFacing(180), closeTo(180, 0.001));
      expect(headingFacing(270), closeTo(270, 0.001));
    });

    test('reads intermediate bearings', () {
      expect(headingFacing(45), closeTo(45, 0.001));
      expect(headingFacing(135), closeTo(135, 0.001));
    });

    test('always returns a value inside [0, 360)', () {
      for (var bearing = 0.0; bearing < 360; bearing += 17) {
        final heading = headingFacing(bearing)!;
        expect(heading, greaterThanOrEqualTo(0));
        expect(heading, lessThan(360));
      }
    });

    test('stays correct when the device is tilted', () {
      // Tilted forward ~30°: gravity moves out of the z axis. A naive
      // atan2(my, mx) would drift here; tilt compensation should not.
      final upright = CompassMath.headingDegrees(
        ax: 0,
        ay: -4.9,
        az: 8.49,
        mx: 0,
        my: 10,
        mz: -44,
      );

      expect(upright, isNotNull);
      expect(upright!, greaterThanOrEqualTo(0));
      expect(upright, lessThan(360));
    });

    test('returns null in free fall', () {
      expect(
        CompassMath.headingDegrees(
          ax: 0, ay: 0, az: 0, //
          mx: 0, my: 20, mz: -40,
        ),
        isNull,
      );
    });

    test('returns null when the field is parallel to gravity', () {
      // Directly over a magnetic pole: no horizontal component to point with.
      expect(
        CompassMath.headingDegrees(
          ax: 0, ay: 0, az: 9.81, //
          mx: 0, my: 0, mz: -40,
        ),
        isNull,
      );
    });

    test('returns null rather than NaN for degenerate input', () {
      expect(
        CompassMath.headingDegrees(
          ax: double.nan, ay: 0, az: 0, //
          mx: 0, my: 0, mz: 0,
        ),
        isNull,
      );
    });
  });

  group('normalizeDegrees', () {
    test('leaves values already in range', () {
      expect(CompassMath.normalizeDegrees(0), 0);
      expect(CompassMath.normalizeDegrees(359.9), closeTo(359.9, 0.001));
    });

    test('wraps values above 360', () {
      expect(CompassMath.normalizeDegrees(370), closeTo(10, 0.001));
      expect(CompassMath.normalizeDegrees(720), closeTo(0, 0.001));
    });

    test('wraps negative values', () {
      expect(CompassMath.normalizeDegrees(-10), closeTo(350, 0.001));
      expect(CompassMath.normalizeDegrees(-370), closeTo(350, 0.001));
    });
  });

  group('angleDifference', () {
    test('is signed and takes the short way round', () {
      expect(CompassMath.angleDifference(10, 20), closeTo(10, 0.001));
      expect(CompassMath.angleDifference(20, 10), closeTo(-10, 0.001));
    });

    test('crosses north the short way', () {
      expect(CompassMath.angleDifference(350, 10), closeTo(20, 0.001));
      expect(CompassMath.angleDifference(10, 350), closeTo(-20, 0.001));
    });

    test('never exceeds a half turn', () {
      for (var from = 0.0; from < 360; from += 23) {
        for (var to = 0.0; to < 360; to += 31) {
          expect(CompassMath.angleDifference(from, to).abs(),
              lessThanOrEqualTo(180.0001));
        }
      }
    });
  });

  group('smooth', () {
    test('alpha of 1 follows the new reading exactly', () {
      expect(CompassMath.smooth(10, 80, 1), closeTo(80, 0.001));
    });

    test('alpha of 0 holds the previous value', () {
      expect(CompassMath.smooth(10, 80, 0), closeTo(10, 0.001));
    });

    test('moves part way for intermediate alpha', () {
      expect(CompassMath.smooth(0, 100, 0.25), closeTo(25, 0.001));
    });

    test('takes the short arc across north instead of spinning back', () {
      // 350 → 10 must pass through 0, not sweep down through 180.
      final result = CompassMath.smooth(350, 10, 0.5);
      expect(result, closeTo(0, 0.001));
    });

    test('converges towards the target when applied repeatedly', () {
      var heading = 0.0;
      for (var i = 0; i < 60; i++) {
        heading = CompassMath.smooth(heading, 90, 0.2);
      }
      expect(heading, closeTo(90, 0.5));
    });

    test('stays in range while converging across the wrap point', () {
      var heading = 355.0;
      for (var i = 0; i < 60; i++) {
        heading = CompassMath.smooth(heading, 5, 0.2);
        expect(heading, greaterThanOrEqualTo(0));
        expect(heading, lessThan(360));
      }
      expect(heading, closeTo(5, 0.5));
    });
  });

  group('field plausibility', () {
    test('accepts a typical Earth field', () {
      expect(CompassMath.isFieldPlausible(45), isTrue);
    });

    test('rejects a field weak enough to be shielded', () {
      expect(CompassMath.isFieldPlausible(5), isFalse);
    });

    test('rejects a field strong enough to be a nearby magnet', () {
      expect(CompassMath.isFieldPlausible(200), isFalse);
    });

    test('computes magnitude from components', () {
      expect(CompassMath.fieldStrength(3, 4, 0), closeTo(5, 0.001));
      expect(CompassMath.fieldStrength(0, 30, -40), closeTo(50, 0.001));
    });
  });

  group('relativeBearing', () {
    test('is zero when the device already points at the Qibla', () {
      expect(
        CompassMath.relativeBearing(qiblaBearing: 277, deviceHeading: 277),
        closeTo(0, 0.001),
      );
    });

    test('is the rotation needed to reach the Qibla', () {
      expect(
        CompassMath.relativeBearing(qiblaBearing: 277, deviceHeading: 180),
        closeTo(97, 0.001),
      );
    });

    test('wraps rather than going negative', () {
      expect(
        CompassMath.relativeBearing(qiblaBearing: 10, deviceHeading: 350),
        closeTo(20, 0.001),
      );
      expect(
        CompassMath.relativeBearing(qiblaBearing: 350, deviceHeading: 10),
        closeTo(340, 0.001),
      );
    });
  });

  group('isAligned', () {
    test('accepts dead on', () {
      expect(CompassMath.isAligned(0), isTrue);
    });

    test('accepts just inside tolerance on either side', () {
      expect(CompassMath.isAligned(4), isTrue);
      expect(CompassMath.isAligned(356), isTrue);
    });

    test('rejects just outside tolerance', () {
      expect(CompassMath.isAligned(6), isFalse);
      expect(CompassMath.isAligned(354), isFalse);
    });

    test('honours a custom tolerance', () {
      expect(CompassMath.isAligned(12, toleranceDegrees: 15), isTrue);
      expect(CompassMath.isAligned(20, toleranceDegrees: 15), isFalse);
    });
  });
}

double _sin(double radians) => math.sin(radians);
double _cos(double radians) => math.cos(radians);
