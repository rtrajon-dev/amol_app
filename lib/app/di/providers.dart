import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/token_store.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../features/subscription/data/bdapps_subscription_repository.dart';
import '../../features/subscription/data/entitlement_cache.dart';
import '../../features/subscription/data/subscription_api.dart';
import '../../features/subscription/domain/subscription_repository.dart';
import '../database/app_database.dart';
import '../network/api_client.dart';
import '../services/secure_storage_service.dart';
import '../services/storage_service.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Device-local store for amal history and tasbeeh sessions.
///
/// Opened lazily on first use rather than in `bootstrap()`: nothing on the
/// startup path reads it, so opening it there would add disk I/O to cold start
/// for no gain.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.instance;
});

/// FR-BE-08 — a stable per-install identifier sent as `X-Device-Id`.
///
/// Generated once and persisted. Used server-side for support, abuse triage,
/// and to bind a subscription made before an account existed (FR-S-12).
final deviceIdProvider = Provider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final existing = storage.getString(StorageKeys.deviceId);
  if (existing.isNotEmpty) return existing;

  final generated = const Uuid().v4();
  storage.setString(StorageKeys.deviceId, generated);
  return generated;
});

/// Sent as `X-App-Version` (FR-BE-08).
///
/// Overridden in `bootstrap()` from `package_info_plus`. It throws by default
/// so a missing override fails loudly at startup rather than silently shipping
/// a wrong version to the server for the life of the release.
final appVersionProvider = Provider<String>(
  (ref) => throw UnimplementedError('appVersionProvider must be overridden in bootstrap()'),
);

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(secureStorageProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    tokenStore: ref.watch(tokenStoreProvider),
    deviceId: ref.watch(deviceIdProvider),
    appVersion: ref.watch(appVersionProvider),
  );

  // The network layer tells the auth layer when the SERVER has ended the
  // session. It never fires on a network error — that distinction is what
  // keeps an offline user logged in (FR-A-06).
  client.onSessionEnded = () {
    ref.read(authProvider.notifier).onSessionEnded();
  };

  return client;
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(authApiProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

// ------------------------------------------------------- subscription (M-3)
//
// FR-R-01 — decommissioning BDApps means deleting
// `lib/features/subscription/data/` and binding the provider below to a
// different implementation of the same interface. Nothing else changes.

final entitlementCacheProvider = Provider<EntitlementCache>((ref) {
  return EntitlementCache(ref.watch(secureStorageProvider));
});

final subscriptionApiProvider = Provider<SubscriptionApi>((ref) {
  return SubscriptionApi(ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return BdappsSubscriptionRepository(
    api: ref.watch(subscriptionApiProvider),
    cache: ref.watch(entitlementCacheProvider),
  );
});
