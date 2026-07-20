import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../domain/compass_math.dart';

/// A single compass sample.
class CompassReading {
  const CompassReading({
    required this.heading,
    required this.fieldStrength,
  });

  /// Degrees clockwise from **magnetic** north, or null when the sensors
  /// cannot resolve a direction (free fall, or field parallel to gravity).
  final double? heading;

  /// Magnitude of the measured field, in microtesla.
  final double fieldStrength;

  /// True when the field magnitude is unlike Earth's, which means something
  /// nearby is deflecting the needle.
  bool get hasInterference => !CompassMath.isFieldPlausible(fieldStrength);
}

/// Turns the raw accelerometer and magnetometer streams into headings.
///
/// `sensors_plus` exposes the two sensors separately and they tick
/// independently, so the latest accelerometer sample is held and paired with
/// each magnetometer sample. The magnetometer drives emission because it is
/// the sensor that actually carries direction.
class CompassService {
  CompassService({
    Stream<AccelerometerEvent>? accelerometer,
    Stream<MagnetometerEvent>? magnetometer,
    this.smoothing = 0.2,
  })  : _accelerometer = accelerometer ??
            accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval),
        _magnetometer = magnetometer ??
            magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval);

  final Stream<AccelerometerEvent> _accelerometer;
  final Stream<MagnetometerEvent> _magnetometer;

  /// Weight given to each new reading. Raw magnetometer output jitters by
  /// several degrees; without this the needle visibly shakes.
  final double smoothing;

  Stream<CompassReading> readings() {
    late StreamController<CompassReading> controller;
    StreamSubscription<AccelerometerEvent>? accelSub;
    StreamSubscription<MagnetometerEvent>? magSub;

    AccelerometerEvent? latestAccel;
    double? smoothed;

    void start() {
      accelSub = _accelerometer.listen(
        (event) => latestAccel = event,
        onError: controller.addError,
      );

      magSub = _magnetometer.listen(
        (mag) {
          final accel = latestAccel;
          // Until gravity is known there is no way to compensate for tilt, and
          // an uncompensated heading would be wrong in a way the user cannot
          // see. Waiting a frame or two is the honest option.
          if (accel == null) return;

          final raw = CompassMath.headingDegrees(
            ax: accel.x,
            ay: accel.y,
            az: accel.z,
            mx: mag.x,
            my: mag.y,
            mz: mag.z,
          );

          if (raw == null) {
            smoothed = null;
            controller.add(CompassReading(
              heading: null,
              fieldStrength: CompassMath.fieldStrength(mag.x, mag.y, mag.z),
            ));
            return;
          }

          smoothed = smoothed == null
              ? raw
              : CompassMath.smooth(smoothed!, raw, smoothing);

          controller.add(CompassReading(
            heading: smoothed,
            fieldStrength: CompassMath.fieldStrength(mag.x, mag.y, mag.z),
          ));
        },
        onError: controller.addError,
      );
    }

    Future<void> stop() async {
      await accelSub?.cancel();
      await magSub?.cancel();
      accelSub = null;
      magSub = null;
      // Drop the filter state so a re-listen starts from the live heading
      // rather than easing over from wherever the needle was minutes ago.
      smoothed = null;
      latestAccel = null;
    }

    controller = StreamController<CompassReading>(
      onListen: start,
      onCancel: stop,
    );

    return controller.stream;
  }
}
