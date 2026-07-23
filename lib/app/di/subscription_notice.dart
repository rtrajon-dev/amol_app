import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A one-shot message Home owes the user about their subscription.
///
/// The gate and the registration flow both end by handing the user to Home, and
/// both leave something unsaid: one has just taken a subscription out, the
/// other has found an existing one. Neither screen survives long enough to say
/// it — the router replaces them the moment entitlement flips — so the notice
/// is parked here and Home reads it once.
///
/// Lives in `app/di` because it spans auth (M-2) and subscription (M-3), which
/// may not import each other (SRS §4). Same rule that puts
/// [subscriptionResolvingProvider] and `sessionCoordinatorProvider` here.
enum SubscriptionNotice {
  /// Nothing to say.
  none,

  /// A subscription was just created through the gate. Covers
  /// INITIAL CHARGING PENDING: the record exists and bdapps will debit the
  /// number daily from here, so the user is subscribed even though the first
  /// charge has not landed yet.
  activated,

  /// The number was already paying — a web subscriber, or a reinstall. Worth
  /// saying explicitly, because the user's fear at this moment is a second
  /// charge.
  recognised,
}

final subscriptionNoticeProvider =
    NotifierProvider<SubscriptionNoticeNotifier, SubscriptionNotice>(
  SubscriptionNoticeNotifier.new,
);

class SubscriptionNoticeNotifier extends Notifier<SubscriptionNotice> {
  @override
  SubscriptionNotice build() => SubscriptionNotice.none;

  void set(SubscriptionNotice notice) => state = notice;

  /// Reads the pending notice and clears it, so it shows once rather than on
  /// every return to Home.
  SubscriptionNotice take() {
    final notice = state;
    state = SubscriptionNotice.none;
    return notice;
  }
}
