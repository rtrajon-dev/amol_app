import 'dart:convert';

import '../../../app/services/secure_storage_service.dart';
import '../domain/entitlement.dart';

/// FR-S-13 — entitlement is cached in secure storage, never in
/// `SharedPreferences`, which is trivially editable on a rooted device.
///
/// FR-S-17 — this cache is a UX optimisation only. It decides what the UI
/// shows; it never decides what the server hands out.
class EntitlementCache {
  EntitlementCache(this._storage);

  final SecureStore _storage;

  Entitlement? _memory;

  Future<Entitlement> read() async {
    final cached = _memory;
    if (cached != null) return cached;

    final raw = await _storage.read(SecureKeys.entitlementCache);
    if (raw == null || raw.isEmpty) return Entitlement.free;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return Entitlement.free;
      final entitlement = Entitlement.fromJson(Map<String, dynamic>.from(decoded));
      _memory = entitlement;
      return entitlement;
    } catch (_) {
      // A corrupt cache means "unknown", not "premium".
      return Entitlement.free;
    }
  }

  Future<void> write(Entitlement entitlement) async {
    _memory = entitlement;
    await _storage.write(
      SecureKeys.entitlementCache,
      jsonEncode(entitlement.toJson()),
    );
  }

  Future<void> clear() async {
    _memory = null;
    await _storage.delete(SecureKeys.entitlementCache);
  }
}
