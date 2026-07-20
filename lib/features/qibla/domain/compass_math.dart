import 'dart:math' as math;

/// Tilt-compensated compass maths.
///
/// Pure functions over raw sensor vectors so the awkward parts — gimbal
/// behaviour, wrap-around at 360°, magnetic interference — are testable
/// without a device.
///
/// The algorithm is Android's `SensorManager.getRotationMatrix` followed by
/// `getOrientation`, reimplemented here because `sensors_plus` exposes raw
/// vectors rather than a fused orientation. Using the accelerometer to
/// establish "down" is what makes the reading survive a tilted phone; a naive
/// `atan2(my, mx)` is only correct while the device lies perfectly flat.
abstract class CompassMath {
  /// Earth's field strength at the surface, in microtesla. Readings far
  /// outside this band mean something local is bending the field — a magnet,
  /// a speaker, a car body, a steel desk.
  static const minEarthFieldMicroTesla = 25.0;
  static const maxEarthFieldMicroTesla = 65.0;

  /// Device heading in degrees clockwise from **magnetic** north.
  ///
  /// [ax]/[ay]/[az] is the accelerometer vector and [mx]/[my]/[mz] the
  /// magnetometer vector, both in device coordinates.
  ///
  /// Returns null when the two vectors are too close to parallel to define a
  /// horizontal plane — free fall, or standing directly over a magnetic pole.
  /// A null must be shown as "no reading", never silently drawn as north.
  static double? headingDegrees({
    required double ax,
    required double ay,
    required double az,
    required double mx,
    required double my,
    required double mz,
  }) {
    // H = M × A — points east, perpendicular to both the field and gravity.
    var hx = my * az - mz * ay;
    var hy = mz * ax - mx * az;
    var hz = mx * ay - my * ax;

    final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (!normH.isFinite || normH < 0.1) return null;

    hx /= normH;
    hy /= normH;
    hz /= normH;

    final normA = math.sqrt(ax * ax + ay * ay + az * az);
    if (!normA.isFinite || normA < 0.1) return null;

    final gx = ax / normA;
    final gy = ay / normA;
    final gz = az / normA;

    // M' = A × H — points north within the horizontal plane.
    final nx = gy * hz - gz * hy;
    final ny = gz * hx - gx * hz;

    // Azimuth is the device y axis measured against that north vector.
    final azimuth = math.atan2(hy, ny);
    if (!azimuth.isFinite) return null;

    // `nx` participates only through the cross product above; naming it keeps
    // the derivation readable.
    assert(nx.isFinite);

    return normalizeDegrees(azimuth * 180 / math.pi);
  }

  /// Field magnitude in microtesla, for detecting interference.
  static double fieldStrength(double mx, double my, double mz) =>
      math.sqrt(mx * mx + my * my + mz * mz);

  /// Whether a field magnitude is consistent with Earth's own field.
  ///
  /// False means the compass is being pulled by something nearby and the
  /// heading should be presented as unreliable rather than trusted.
  static bool isFieldPlausible(double magnitude) =>
      magnitude >= minEarthFieldMicroTesla &&
      magnitude <= maxEarthFieldMicroTesla;

  /// Folds any angle into [0, 360).
  static double normalizeDegrees(double degrees) {
    final wrapped = degrees % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }

  /// Signed shortest rotation from [from] to [to], in (-180, 180].
  ///
  /// Going from 350° to 10° is +20°, not -340°.
  static double angleDifference(double from, double to) {
    final delta = normalizeDegrees(to - from);
    return delta > 180 ? delta - 360 : delta;
  }

  /// Low-pass filter over a circular quantity.
  ///
  /// Raw magnetometer output jitters by several degrees; drawing it unsmoothed
  /// makes the needle vibrate. Interpolating along the shortest arc keeps the
  /// needle from spinning the long way round when the heading crosses north.
  ///
  /// [alpha] is the weight of the new reading: 1.0 follows instantly, values
  /// near 0 barely move.
  static double smooth(double previous, double next, double alpha) {
    final delta = angleDifference(previous, next);
    return normalizeDegrees(previous + delta * alpha);
  }

  /// Where the Qibla sits relative to where the device is pointing.
  ///
  /// This is the rotation to apply to the needle: 0 means the top of the
  /// device already points at the Kaaba.
  static double relativeBearing({
    required double qiblaBearing,
    required double deviceHeading,
  }) =>
      normalizeDegrees(qiblaBearing - deviceHeading);

  /// True when the device is pointing at the Qibla within [toleranceDegrees].
  static bool isAligned(double relativeBearing, {double toleranceDegrees = 5}) =>
      angleDifference(0, relativeBearing).abs() <= toleranceDegrees;
}
