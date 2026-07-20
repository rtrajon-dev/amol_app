import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:amol365/features/qibla/data/compass_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  /// Phone flat and face up, top edge pointing north.
  final northAccel = AccelerometerEvent(0, 0, 9.81, DateTime.now());
  final northField = MagnetometerEvent(0, 20, -40, DateTime.now());

  /// Same posture, top edge pointing east.
  final eastField = MagnetometerEvent(-20, 0, -40, DateTime.now());

  group('Qibla bearing (adhan)', () {
    // Bearings are geometric facts, so these assert direction rather than a
    // recomputation of the same formula — a test that just re-ran adhan would
    // pass even if adhan were wrong.

    test('points west-north-west from Bangladesh', () {
      final dhaka = Qibla(Coordinates(23.8103, 90.4125)).direction;

      // Mecca is west and slightly north of Dhaka.
      expect(dhaka, greaterThan(265));
      expect(dhaka, lessThan(285));
    });

    test('points west-north-west from Indonesia', () {
      final jakarta = Qibla(Coordinates(-6.2088, 106.8456)).direction;

      expect(jakarta, greaterThan(285));
      expect(jakarta, lessThan(300));
    });

    test('points south-east from Turkey', () {
      final istanbul = Qibla(Coordinates(41.0082, 28.9784)).direction;

      expect(istanbul, greaterThan(140));
      expect(istanbul, lessThan(170));
    });

    test('differs measurably across Bangladesh', () {
      final dhaka = Qibla(Coordinates(23.8103, 90.4125)).direction;
      final sylhet = Qibla(Coordinates(24.8949, 91.8687)).direction;

      expect((dhaka - sylhet).abs(), greaterThan(0.1),
          reason: 'a fixed bearing for the whole country would be wrong');
    });

    test('is always a valid compass bearing', () {
      for (final coords in [
        Coordinates(23.8103, 90.4125),
        Coordinates(-33.8688, 151.2093),
        Coordinates(64.1466, -21.9426),
        Coordinates(0, 0),
      ]) {
        final direction = Qibla(coords).direction;
        expect(direction, greaterThanOrEqualTo(0));
        expect(direction, lessThan(360));
      }
    });
  });

  group('CompassService', () {
    late StreamController<AccelerometerEvent> accel;
    late StreamController<MagnetometerEvent> mag;

    setUp(() {
      accel = StreamController<AccelerometerEvent>.broadcast();
      mag = StreamController<MagnetometerEvent>.broadcast();
    });

    tearDown(() async {
      await accel.close();
      await mag.close();
    });

    CompassService build({double smoothing = 1.0}) => CompassService(
          accelerometer: accel.stream,
          magnetometer: mag.stream,
          // Unsmoothed by default so a single sample is assertable.
          smoothing: smoothing,
        );

    test('emits nothing until gravity is known', () async {
      final readings = <CompassReading>[];
      final sub = build().readings().listen(readings.add);

      // Magnetometer alone cannot be tilt-compensated.
      mag.add(northField);
      await Future<void>.delayed(Duration.zero);

      expect(readings, isEmpty);

      await sub.cancel();
    });

    test('emits once both sensors have reported', () async {
      final readings = <CompassReading>[];
      final sub = build().readings().listen(readings.add);

      accel.add(northAccel);
      await Future<void>.delayed(Duration.zero);
      mag.add(northField);
      await Future<void>.delayed(Duration.zero);

      expect(readings, hasLength(1));
      expect(readings.single.heading, closeTo(0, 0.001));

      await sub.cancel();
    });

    test('tracks the device turning east', () async {
      final readings = <CompassReading>[];
      final sub = build().readings().listen(readings.add);

      accel.add(northAccel);
      await Future<void>.delayed(Duration.zero);
      mag.add(eastField);
      await Future<void>.delayed(Duration.zero);

      expect(readings.single.heading, closeTo(90, 0.001));

      await sub.cancel();
    });

    test('is driven by the magnetometer, not the accelerometer', () async {
      final readings = <CompassReading>[];
      final sub = build().readings().listen(readings.add);

      accel.add(northAccel);
      accel.add(northAccel);
      accel.add(northAccel);
      await Future<void>.delayed(Duration.zero);

      expect(readings, isEmpty,
          reason: 'gravity alone carries no direction');

      await sub.cancel();
    });

    test('reports interference from an implausible field', () async {
      final readings = <CompassReading>[];
      final sub = build().readings().listen(readings.add);

      accel.add(northAccel);
      await Future<void>.delayed(Duration.zero);
      // ~224 µT: far above Earth's field, so something is nearby.
      mag.add(MagnetometerEvent(0, 100, -200, DateTime.now()));
      await Future<void>.delayed(Duration.zero);

      expect(readings.single.hasInterference, isTrue);

      await sub.cancel();
    });

    test('does not report interference for a normal field', () async {
      final readings = <CompassReading>[];
      final sub = build().readings().listen(readings.add);

      accel.add(northAccel);
      await Future<void>.delayed(Duration.zero);
      mag.add(northField); // ~44.7 µT
      await Future<void>.delayed(Duration.zero);

      expect(readings.single.hasInterference, isFalse);

      await sub.cancel();
    });

    test('emits a null heading when the sensors cannot resolve one', () async {
      final readings = <CompassReading>[];
      final sub = build().readings().listen(readings.add);

      accel.add(AccelerometerEvent(0, 0, 9.81, DateTime.now()));
      await Future<void>.delayed(Duration.zero);
      // Field parallel to gravity: no horizontal component.
      mag.add(MagnetometerEvent(0, 0, -40, DateTime.now()));
      await Future<void>.delayed(Duration.zero);

      expect(readings, hasLength(1));
      expect(readings.single.heading, isNull,
          reason: 'an unresolvable heading must not be reported as north');

      await sub.cancel();
    });

    test('smoothing eases towards a new heading instead of jumping', () async {
      final readings = <CompassReading>[];
      final sub = build(smoothing: 0.5).readings().listen(readings.add);

      accel.add(northAccel);
      await Future<void>.delayed(Duration.zero);

      mag.add(northField); // establishes 0°
      await Future<void>.delayed(Duration.zero);
      mag.add(eastField); // jumps to 90°
      await Future<void>.delayed(Duration.zero);

      expect(readings.first.heading, closeTo(0, 0.001));
      expect(readings.last.heading, closeTo(45, 0.001),
          reason: 'half way, not all the way');

      await sub.cancel();
    });

    test('stops listening to the sensors when the stream is cancelled',
        () async {
      final sub = build().readings().listen((_) {});
      await Future<void>.delayed(Duration.zero);

      expect(accel.hasListener, isTrue);
      expect(mag.hasListener, isTrue);

      await sub.cancel();

      expect(accel.hasListener, isFalse);
      expect(mag.hasListener, isFalse);
    });
  });
}
