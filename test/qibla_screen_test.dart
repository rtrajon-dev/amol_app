import 'dart:async';
import 'dart:math' as math;

import 'package:amol365/features/prayer_time/data/services/prayer_time_service.dart';
import 'package:amol365/features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import 'package:amol365/features/qibla/data/compass_service.dart';
import 'package:amol365/features/qibla/presentation/view/qibla_screen.dart';
import 'package:amol365/features/qibla/presentation/viewmodel/qibla_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Feeds the real screen from streams under the test's control, so the whole
/// chain runs: provider → service → maths → CustomPainter.
class FakeCompassService implements CompassService {
  final accel = StreamController<AccelerometerEvent>.broadcast();
  final mag = StreamController<MagnetometerEvent>.broadcast();

  late final CompassService _delegate = CompassService(
    accelerometer: accel.stream,
    magnetometer: mag.stream,
    smoothing: 1.0,
  );

  @override
  Stream<CompassReading> readings() => _delegate.readings();

  @override
  double get smoothing => 1.0;

  Future<void> dispose() async {
    await accel.close();
    await mag.close();
  }
}

void main() {
  const designSize = Size(390, 844);

  const dhaka = ResolvedLocation(
    latitude: 23.8103,
    longitude: 90.4125,
    name: 'ঢাকা',
    source: LocationSource.manual,
  );

  late FakeCompassService compass;

  setUp(() => compass = FakeCompassService());
  tearDown(() => compass.dispose());

  Future<void> pumpScreen(
    WidgetTester tester, {
    ResolvedLocation location = dhaka,
  }) async {
    tester.view.physicalSize = designSize * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resolvedLocationProvider.overrideWith((ref) async => location),
          compassServiceProvider.overrideWithValue(compass),
        ],
        child: ScreenUtilInit(
          designSize: designSize,
          builder: (_, _) => const MaterialApp(home: QiblaScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Puts the device flat, top edge pointing at [towards] degrees.
  ///
  /// Each sensor event travels controller → service → StreamProvider → rebuild,
  /// crossing several microtask boundaries, so a single pump is not enough to
  /// see it on screen.
  Future<void> face(WidgetTester tester, double towards) async {
    compass.accel.add(AccelerometerEvent(0, 0, 9.81, DateTime.now()));
    await tester.pumpAndSettle();

    // Horizontal component rotates opposite the device's own rotation.
    final radians = -towards * math.pi / 180;
    compass.mag.add(MagnetometerEvent(
      -20 * _sin(radians) * -1,
      20 * _cos(radians),
      -40,
      DateTime.now(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the bearing and location before any sensor data',
      (tester) async {
    await pumpScreen(tester);

    // Dhaka's Qibla is ~277°; the screen must be useful even with no compass.
    expect(find.textContaining('°'), findsOneWidget);
    expect(find.text('ঢাকা'), findsOneWidget);
    expect(find.textContaining('কম্পাস পাওয়া যাচ্ছে না'), findsOneWidget);
  });

  testWidgets('renders the compass once sensors report', (tester) async {
    await pumpScreen(tester);
    await face(tester, 0);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('কম্পাস পাওয়া যাচ্ছে না'), findsNothing);
  });

  testWidgets('confirms alignment when the device faces the Qibla',
      (tester) async {
    await pumpScreen(tester);

    // Dhaka's Qibla bearing, rounded to the degree.
    await face(tester, 277);

    expect(find.textContaining('কিবলার দিকে মুখ করা হয়েছে'), findsOneWidget);
  });

  testWidgets('asks the user to turn when facing away', (tester) async {
    await pumpScreen(tester);
    await face(tester, 90);

    expect(find.textContaining('ফোনটি ঘুরিয়ে'), findsOneWidget);
    expect(find.textContaining('কিবলার দিকে মুখ করা হয়েছে'), findsNothing);
  });

  testWidgets('warns about magnetic interference', (tester) async {
    await pumpScreen(tester);

    compass.accel.add(AccelerometerEvent(0, 0, 9.81, DateTime.now()));
    await tester.pumpAndSettle();
    compass.mag.add(MagnetometerEvent(0, 100, -200, DateTime.now()));
    await tester.pumpAndSettle();

    expect(find.textContaining('চৌম্বকীয় বাধা'), findsOneWidget);
  });

  testWidgets('flags an approximate location, since it makes the Qibla wrong',
      (tester) async {
    await pumpScreen(
      tester,
      location: const ResolvedLocation(
        latitude: 23.8103,
        longitude: 90.4125,
        name: 'ঢাকা',
        source: LocationSource.fallback,
      ),
    );

    expect(find.textContaining('আনুমানিক অবস্থান'), findsOneWidget);
  });

  testWidgets('does not flag a known location', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('আনুমানিক অবস্থান'), findsNothing);
  });

  testWidgets('survives the device rotating through a full turn',
      (tester) async {
    await pumpScreen(tester);

    for (var bearing = 0.0; bearing < 360; bearing += 30) {
      await face(tester, bearing);
      expect(tester.takeException(), isNull,
          reason: 'painting must hold at $bearing°');
    }
  });
}

double _sin(double radians) => math.sin(radians);
double _cos(double radians) => math.cos(radians);
