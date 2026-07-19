import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase bootstrap with graceful degradation.
///
/// The app ships WITHOUT `google-services.json` / `GoogleService-Info.plist`
/// until those are generated from the Firebase console (docs/FIREBASE.md).
/// Until then — and on any future initialisation failure — every Firebase
/// service becomes a no-op and the app runs normally.
///
/// This is deliberate and follows C-BE-05: prayer times, qibla, tasbeeh, and
/// the amal tracker need no network and no Firebase. A missing analytics
/// backend must never be able to stop a user from praying on time.
class FirebaseService {
  FirebaseService._();
  static final instance = FirebaseService._();

  bool _available = false;
  bool _attempted = false;

  /// True only when Firebase initialised successfully.
  bool get isAvailable => _available;

  Future<void> initialize() async {
    if (_attempted) return;
    _attempted = true;

    try {
      await Firebase.initializeApp();
      _available = true;
      debugPrint('Firebase: initialised');
    } catch (e) {
      // Missing config files are the expected case before setup, so this is
      // logged at debug level rather than reported as an error.
      _available = false;
      debugPrint('Firebase: unavailable ($e) — push, crash reporting and '
          'analytics are disabled. See docs/FIREBASE.md.');
    }
  }
}
