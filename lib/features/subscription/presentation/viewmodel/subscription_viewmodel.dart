import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/network/api_exception.dart';
import '../../../../app/services/storage_service.dart';
import '../../../../app/services/telemetry_service.dart';
import '../../domain/entitlement.dart';
import '../../domain/subscription_repository.dart';

/// The app-wide answer to "what may this user access" (FR-S-01).
///
/// Feature modules watch THIS and nothing else from the subscription feature.
final entitlementProvider =
    NotifierProvider<EntitlementNotifier, Entitlement>(EntitlementNotifier.new);

class EntitlementNotifier extends Notifier<Entitlement> {
  @override
  Entitlement build() {
    Future.microtask(_restore);
    return Entitlement.free;
  }

  /// NFR-S-04 — feature gating reads from cache and never awaits the network.
  Future<void> _restore() async {
    final repository = ref.read(subscriptionRepositoryProvider);
    state = await repository.cached();
    unawaitedRevalidate();
  }

  /// FR-S-14 — background revalidation past the 24h TTL. Never blocks the UI,
  /// never downgrades on a network failure (FR-S-15).
  Future<void> unawaitedRevalidate() async {
    try {
      state = await ref.read(subscriptionRepositoryProvider).refreshIfStale();
    } on ApiException {
      // Keep whatever we had. An unreachable server is not a verdict.
    }
  }

  void set(Entitlement entitlement) => state = entitlement;

  Future<void> clear() async {
    await ref.read(subscriptionRepositoryProvider).clear();
    state = Entitlement.free;
  }
}

// ---------------------------------------------------------------- gate policy

/// Telemetry for the gate.
///
/// FR-S-09's three-prompt cap is GONE. It existed for a soft gate, where the
/// risk was nagging a user who could keep using the app anyway; under FR-G-06
/// the whole app is the paid product, so an unsubscribed user sees the gate
/// every time by definition and a cap would only mean showing them a blank
/// wall instead.
///
/// Whether the gate appears is now decided in one place — the router redirect
/// — from entitlement and the FR-P-07 kill switch. What remains here is the
/// counting, which still makes the funnel readable.
abstract class SubscriptionGatePolicy {
  static Future<void> recordShown() async {
    final shown = StorageService.instance.getInt(StorageKeys.subGatePromptCount);
    await StorageService.instance.setInt(StorageKeys.subGatePromptCount, shown + 1);
    // FR-P-06 — `promptNumber` is what makes the funnel readable: it shows
    // whether prompt 2 and 3 convert at all, or just annoy.
    await TelemetryService.instance
        .logEvent(AnalyticsEvents.gateShown, {'promptNumber': shown + 1});
  }

  static Future<void> recordDismissed() async {
    await StorageService.instance
        .setInt(StorageKeys.subGateDismissedAt, DateTime.now().millisecondsSinceEpoch);
    final shown = StorageService.instance.getInt(StorageKeys.subGatePromptCount);
    await TelemetryService.instance
        .logEvent(AnalyticsEvents.gateDismissed, {'promptNumber': shown});
  }

  /// Clear the counters when a session ends, so the next account's funnel is
  /// measured from zero rather than inheriting the previous user's tally on a
  /// shared phone.
  ///
  /// This no longer affects whether the gate appears — that follows from
  /// entitlement alone — only what the numbers mean.
  static Future<void> reset() async {
    await StorageService.instance.setInt(StorageKeys.subGatePromptCount, 0);
    await StorageService.instance.remove(StorageKeys.subGateDismissedAt);
  }
}

// ------------------------------------------------------------------ gate flow

enum GateStep { phone, otp, success }

class SubscriptionState {
  const SubscriptionState({
    this.step = GateStep.phone,
    this.isBusy = false,
    this.failure,
    this.msisdn = '',
    this.challenge,
    this.resendAvailableAt,
  });

  final GateStep step;
  final bool isBusy;
  final ApiException? failure;

  /// Held in memory only, for the duration of the flow.
  final String msisdn;

  /// FR-S-04 — txnId lives in memory only. If the app is killed mid-flow the
  /// user restarts from the number screen (EC-11, accepted).
  final OtpChallenge? challenge;

  final DateTime? resendAvailableAt;

  int get resendInSeconds {
    final at = resendAvailableAt;
    if (at == null) return 0;
    final remaining = at.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  SubscriptionState copyWith({
    GateStep? step,
    bool? isBusy,
    ApiException? failure,
    String? msisdn,
    OtpChallenge? challenge,
    DateTime? resendAvailableAt,
    bool clearFailure = false,
  }) =>
      SubscriptionState(
        step: step ?? this.step,
        isBusy: isBusy ?? this.isBusy,
        failure: clearFailure ? null : (failure ?? this.failure),
        msisdn: msisdn ?? this.msisdn,
        challenge: challenge ?? this.challenge,
        resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      );
}

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() => const SubscriptionState();

  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);

  /// FR-S-03 — check first. An already-subscribed number completes here with
  /// NO OTP sent and no second charge. This is also the path a web subscriber
  /// takes (FR-S-19).
  Future<void> submitPhone(String rawMsisdn) async {
    final msisdn = normaliseMsisdn(rawMsisdn);
    if (msisdn == null) {
      state = state.copyWith(
        failure: const ApiException(
          code: 'INVALID_MSISDN',
          message: 'সঠিক মোবাইল নম্বর দিন (যেমন ০১৭xxxxxxxx)।',
        ),
      );
      return;
    }

    state = state.copyWith(isBusy: true, clearFailure: true, msisdn: msisdn);
    await TelemetryService.instance.logEvent(AnalyticsEvents.phoneSubmitted);

    try {
      final entitlement = await _repository.checkStatus(msisdn);

      if (entitlement.isPremium) {
        // Setting entitlement is what closes the gate: the router redirect
        // reads it directly, so no counter needs silencing.
        ref.read(entitlementProvider.notifier).set(entitlement);
        // FR-S-19 — an existing web subscriber landing here with no OTP and
        // no second charge. Worth measuring separately from a new subscribe.
        await TelemetryService.instance.logEvent(AnalyticsEvents.alreadySubscribed);
        state = state.copyWith(step: GateStep.success, isBusy: false);
        return;
      }

      // Not subscribed — begin the OTP flow (FR-S-04).
      final challenge = await _repository.requestOtp(msisdn);
      await TelemetryService.instance.logEvent(AnalyticsEvents.otpRequested);
      state = state.copyWith(
        step: GateStep.otp,
        isBusy: false,
        challenge: challenge,
        resendAvailableAt:
            DateTime.now().add(Duration(seconds: challenge.resendAfterSeconds)),
      );
    } on ApiException catch (e) {
      state = state.copyWith(isBusy: false, failure: e);
    }
  }

  /// FR-S-06 — a wrong code keeps the transaction open so the user retries
  /// without re-entering their number.
  Future<bool> submitOtp(String otp) async {
    final challenge = state.challenge;
    if (challenge == null) {
      state = state.copyWith(step: GateStep.phone);
      return false;
    }

    state = state.copyWith(isBusy: true, clearFailure: true);

    try {
      final entitlement = await _repository.verifyOtp(
        txnId: challenge.txnId,
        otp: otp,
      );
      ref.read(entitlementProvider.notifier).set(entitlement);
      await TelemetryService.instance.logEvent(AnalyticsEvents.subscribed);
      await TelemetryService.instance.setPremium(true);
      state = state.copyWith(step: GateStep.success, isBusy: false);
      return true;
    } on ApiException catch (e) {
      // The error CODE is recorded, never the OTP the user typed (FR-P-05).
      await TelemetryService.instance
          .logEvent(AnalyticsEvents.otpFailed, {'code': e.code});
      // FR-S-07 — an expired transaction sends the user back to resend rather
      // than dead-ending on the OTP screen.
      if (e.code == 'OTP_EXPIRED') {
        state = state.copyWith(isBusy: false, failure: e, challenge: null);
      } else {
        state = state.copyWith(isBusy: false, failure: e);
      }
      return false;
    }
  }

  /// FR-S-05 — resend, bounded server-side by the rate limiter (FR-BE-07).
  Future<void> resendOtp() async {
    if (state.msisdn.isEmpty || state.resendInSeconds > 0) return;

    state = state.copyWith(isBusy: true, clearFailure: true);
    try {
      final challenge = await _repository.requestOtp(state.msisdn);
      state = state.copyWith(
        isBusy: false,
        challenge: challenge,
        step: GateStep.otp,
        resendAvailableAt:
            DateTime.now().add(Duration(seconds: challenge.resendAfterSeconds)),
      );
    } on ApiException catch (e) {
      state = state.copyWith(isBusy: false, failure: e);
    }
  }

  void backToPhone() =>
      state = state.copyWith(step: GateStep.phone, clearFailure: true);

  void reset() => state = const SubscriptionState();

  /// FR-S-08 — the cross. No penalty, no confirmation, no re-prompt this
  /// session.
  Future<void> dismiss() async {
    await SubscriptionGatePolicy.recordDismissed();
  }

  /// O-01 — mirrors the server's normalisation so the user gets immediate
  /// local feedback before any network call (FR-S-02).
  static String? normaliseMsisdn(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('880') && digits.length == 13) {
      digits = '0${digits.substring(3)}';
    } else if (digits.startsWith('88') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    }

    return RegExp(r'^01[3-9][0-9]{8}$').hasMatch(digits) ? digits : null;
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
        SubscriptionNotifier.new);
