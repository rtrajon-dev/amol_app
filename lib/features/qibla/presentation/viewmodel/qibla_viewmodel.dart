import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prayer_time/data/services/prayer_time_service.dart';
import '../../../prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import '../../data/compass_service.dart';
import '../../domain/compass_math.dart';

class QiblaState {
  const QiblaState({
    required this.qiblaBearing,
    required this.location,
    this.heading,
    this.hasInterference = false,
  });

  /// Degrees clockwise from **true** north to the Kaaba, from the user's
  /// position. Fixed for a given location.
  final double qiblaBearing;

  final ResolvedLocation location;

  /// Device heading from magnetic north, or null when the sensors cannot give
  /// one. Null must be rendered as "no reading", never as north.
  final double? heading;

  /// Something nearby is deflecting the field; the heading is not trustworthy.
  final bool hasInterference;

  bool get hasHeading => heading != null;

  /// Rotation to apply to the needle. Null while there is no heading.
  double? get relativeBearing => heading == null
      ? null
      : CompassMath.relativeBearing(
          qiblaBearing: qiblaBearing,
          deviceHeading: heading!,
        );

  bool get isAligned {
    final relative = relativeBearing;
    return relative != null && CompassMath.isAligned(relative);
  }
}

final compassServiceProvider = Provider<CompassService>((ref) {
  return CompassService();
});

/// Qibla direction plus a live device heading.
///
/// The bearing itself comes from `adhan` and needs only a location, so it is
/// correct even on a device with no magnetometer — the screen can still show
/// "the Qibla is at 277°" and let the user orient by other means.
///
/// One caveat is deliberately not hidden: `adhan` returns a bearing from TRUE
/// north while the magnetometer measures MAGNETIC north, and the two differ by
/// the local magnetic declination. Across Bangladesh that is well under a
/// degree, so it is immaterial for the target audience, but a user far from
/// here would see an error equal to their local declination. Correcting it
/// properly needs a world magnetic model, which is not worth bundling for a
/// sub-degree effect in the markets served.
final qiblaProvider = StreamProvider<QiblaState>((ref) async* {
  final location = await ref.watch(resolvedLocationProvider.future);

  final bearing = Qibla(
    Coordinates(location.latitude, location.longitude),
  ).direction;

  final compass = ref.watch(compassServiceProvider);

  // Emit immediately so the bearing and location are on screen before the
  // sensors have produced anything.
  yield QiblaState(qiblaBearing: bearing, location: location);

  await for (final reading in compass.readings()) {
    yield QiblaState(
      qiblaBearing: bearing,
      location: location,
      heading: reading.heading,
      hasInterference: reading.hasInterference,
    );
  }
});
