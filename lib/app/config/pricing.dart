/// Subscription price, in one place.
///
/// The app previously said "সাপ্তাহিক ৫ টাকা" in four separate widgets while
/// the Amol365 web app said ২.৭৮ টাকা/দিন. One subscriber base, two clients,
/// two different prices on screen — the kind of disagreement that becomes a
/// billing complaint rather than a bug report.
///
/// Wording is copied verbatim from the web app (`index.php`, `terms.php`,
/// `account.php`) so the two never read differently. If BDApps changes the
/// tariff, this constant and those three PHP files are the whole surface.
///
/// The figure is **inclusive** of VAT, supplementary duty and service charge.
/// Anything computing net revenue has to subtract those before applying the
/// BDApps developer share.
abstract class Pricing {
  /// Headline. Short enough for a card subtitle.
  static const daily = 'প্রতিদিন ২.৭৮ টাকা';

  /// Headline plus the tax note. For anywhere presented as the actual offer.
  static const dailyWithTax =
      'প্রতিদিন ২.৭৮ টাকা + (ভ্যাট + সম্পূরক শুল্ক + সার্ভিস চার্জ)';

  /// Full disclosure, shown before the user commits. Auto-renewal and the
  /// carrier restriction are both stated: a user on Grameenphone who reaches
  /// the OTP step and only then discovers it cannot work has been wasted.
  static const disclosure =
      'প্রতিদিন ২.৭৮ টাকা + (ভ্যাট + সম্পূরক শুল্ক + সার্ভিস চার্জ), '
      'অটো-রিনিউয়ালসহ আপনার মোবাইল ব্যালেন্স থেকে কাটা হবে। '
      'শুধুমাত্র রবি ও এয়ারটেল গ্রাহকদের জন্য।';

  /// Shown against an active subscription.
  static const activeSummary = 'প্রতিদিন ২.৭৮ টাকা (ভ্যাটসহ)';
}
