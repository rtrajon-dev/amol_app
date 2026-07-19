import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/services/content_service.dart';
import '../../../../app/services/storage_service.dart';
import '../../domain/models/city_model.dart';
import 'prayer_time_viewmodel.dart';

/// All 64 district headquarters, loaded from bundled JSON (FR-N-05).
/// Offline by construction — this is what a user with no GPS and no data falls
/// back to, so it must never require a network call.
final cityListProvider = FutureProvider<List<CityModel>>((ref) async {
  final rows = await ContentService.instance.loadList('cities.json');
  return rows.map(CityModel.fromJson).toList();
});

/// Applies a location choice and reschedules azan for the new coordinates.
class LocationSettingsController {
  LocationSettingsController(this._ref);

  final Ref _ref;

  /// FR-N-01, FR-N-03 — manual selection. Persisted, and it wins over GPS on
  /// every subsequent launch until the user switches back to automatic.
  Future<void> selectCity(CityModel city) async {
    final storage = StorageService.instance;
    await storage.setString(StorageKeys.locationSource, 'manual');
    await storage.setString(StorageKeys.locationLat, city.latitude.toString());
    await storage.setString(StorageKeys.locationLng, city.longitude.toString());
    await storage.setString(StorageKeys.locationName, city.bangla);
    await storage.setInt(
      StorageKeys.locationTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _applied();
  }

  /// FR-N-06 — manual coordinates, for users outside Bangladesh.
  Future<bool> selectCoordinates({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    // EC-06 — (0,0) is null island, not a location. Almost always a parse
    // error or an empty field rather than an intentional choice.
    if (latitude == 0 && longitude == 0) return false;

    final storage = StorageService.instance;
    await storage.setString(StorageKeys.locationSource, 'manual');
    await storage.setString(StorageKeys.locationLat, latitude.toString());
    await storage.setString(StorageKeys.locationLng, longitude.toString());
    await storage.setString(
      StorageKeys.locationName,
      name.trim().isEmpty ? 'নির্ধারিত অবস্থান' : name.trim(),
    );
    await _applied();
    return true;
  }

  /// Switch back to GPS (FR-N-01).
  Future<void> useAutomatic() async {
    final storage = StorageService.instance;
    await storage.setString(StorageKeys.locationSource, 'auto');
    await storage.setString(StorageKeys.locationName, '');
    await _applied();
  }

  /// FR-N-15 / FR-N-26 — every prayer time just moved, so the displayed times
  /// and the whole scheduled azan window are both invalid.
  Future<void> _applied() async {
    _ref.invalidate(resolvedLocationProvider);
    await _ref.read(azanSchedulerProvider).rescheduleAll();
  }
}

final locationSettingsProvider =
    Provider<LocationSettingsController>(LocationSettingsController.new);
