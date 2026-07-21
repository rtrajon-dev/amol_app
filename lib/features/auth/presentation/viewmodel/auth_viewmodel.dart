import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/network/api_exception.dart';
import '../../domain/app_user.dart';

enum AuthStatus {
  /// Startup: the local session has not been read yet. The router shows the
  /// splash while in this state so no screen flashes before the answer.
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isBusy = false,
    this.failure,
  });

  final AuthStatus status;
  final AppUser? user;

  /// A request is in flight — drives button spinners.
  final bool isBusy;

  /// Last failure, Bangla and displayable (FR-A-11). Cleared on the next action.
  final ApiException? failure;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isBusy,
    ApiException? failure,
    bool clearFailure = false,
    bool clearUser = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        isBusy: isBusy ?? this.isBusy,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Restore without blocking construction; the router waits on `unknown`.
    Future.microtask(restoreSession);
    return const AuthState();
  }

  /// FR-A-05 / FR-A-06 — decide entry from LOCAL state only.
  ///
  /// A stored refresh token is enough to enter Home. The server is consulted
  /// afterwards, in the background, and only an authoritative rejection ends
  /// the session. This is what keeps a rural user with no signal from being
  /// locked out of prayer times, which need no network at all.
  Future<void> restoreSession() async {
    final repository = ref.read(authRepositoryProvider);

    final hasSession = await repository.hasLocalSession();
    if (!ref.mounted) return;
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
      return;
    }

    state = state.copyWith(status: AuthStatus.authenticated);
    unawaitedRefreshProfile();
  }

  /// Background profile fetch. Never downgrades the session on a network error.
  Future<void> unawaitedRefreshProfile() async {
    final repository = ref.read(authRepositoryProvider);
    try {
      final user = await repository.me();
      if (!ref.mounted) return;
      state = state.copyWith(user: user, status: AuthStatus.authenticated);
    } on ApiException catch (e) {
      if (e.isNetworkFailure) {
        return; // FR-A-06 — offline is not a logout.
      }
      if (e.isSessionEnded) {
        await _clearSession();
      }
    } catch (_) {
      // An unexpected failure is not proof the session is invalid either.
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _run(() async {
      final user = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearFailure: true,
      );
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String msisdn,
    String? displayName,
  }) async {
    return _run(() async {
      final user = await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            msisdn: msisdn,
            displayName: displayName,
          );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearFailure: true,
      );
    });
  }

  Future<bool> forgotPassword(String email) async {
    return _run(() => ref.read(authRepositoryProvider).forgotPassword(email));
  }

  /// FR-A-12 — irreversible. The server requires the password because the
  /// access token alone is not proof of intent: a borrowed unlocked phone
  /// should not be able to destroy an account.
  Future<bool> deleteAccount(String password) async {
    state = state.copyWith(isBusy: true, clearFailure: true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount(password);
      // Entitlement and gate state are dropped by sessionCoordinatorProvider
      // on the authenticated → unauthenticated transition below.
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isBusy: false, failure: e);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isBusy: true, clearFailure: true);
    await ref.read(authRepositoryProvider).logout();
    await _clearSession();
  }

  /// Called by the network layer when the server authoritatively ends the
  /// session (FR-A-06 — only an explicit rejection, never a network error).
  Future<void> onSessionEnded() => _clearSession();

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Dropping cached entitlement and resetting the gate belong to
  /// `sessionCoordinatorProvider`, which watches this state. Auth must not
  /// reach into the subscription module directly (SRS §4, dependency rule).
  Future<void> _clearSession() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Shared busy/error handling. Returns true on success.
  Future<bool> _run(Future<void> Function() action) async {
    state = state.copyWith(isBusy: true, clearFailure: true);
    try {
      await action();
      state = state.copyWith(isBusy: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isBusy: false, failure: e);
      return false;
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        failure: const ApiException.unexpected(),
      );
      return false;
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
