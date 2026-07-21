import 'package:amol365/app/config/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

/// The price on screen must match the Amol365 web app.
///
/// Mobile said "সাপ্তাহিক ৫ টাকা" in four widgets while the web said
/// ২.৭৮ টাকা/দিন — one subscriber base, two clients, two prices. That becomes
/// a billing complaint, not a bug report.
void main() {
  group('the quoted price', () {
    test('is the daily rate, never the old weekly one', () {
      for (final copy in [
        Pricing.daily,
        Pricing.dailyWithTax,
        Pricing.disclosure,
        Pricing.activeSummary,
      ]) {
        expect(copy, contains('২.৭৮'));
        expect(copy, isNot(contains('৫ টাকা')));
        expect(copy, isNot(contains('সাপ্তাহিক')));
        expect(copy, isNot(contains('সপ্তাহে')));
      }
    });

    test('states that tax is included wherever it is the offer', () {
      // A price shown without "+ VAT" reads as the final amount. It is not.
      expect(Pricing.dailyWithTax, contains('ভ্যাট'));
      expect(Pricing.disclosure, contains('ভ্যাট'));
      expect(Pricing.dailyWithTax, contains('সম্পূরক শুল্ক'));
      expect(Pricing.dailyWithTax, contains('সার্ভিস চার্জ'));
    });

    test('the disclosure names auto-renewal and the eligible carriers', () {
      // A user on Grameenphone who only discovers the restriction at the OTP
      // step has been wasted, and an undisclosed auto-renewal is a complaint.
      expect(Pricing.disclosure, contains('অটো-রিনিউয়াল'));
      expect(Pricing.disclosure, contains('রবি'));
      expect(Pricing.disclosure, contains('এয়ারটেল'));
    });
  });
}
