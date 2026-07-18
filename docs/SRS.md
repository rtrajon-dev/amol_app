# Software Requirements Specification (SRS) — Namaz Time

**Product:** Amol365 — ইসলামিক আমল
**Package:** com.bdapps.amol365
**Platform:** Android (primary), iOS (secondary)
**Target market:** Bangladeshi Muslims, distributed via BDApps (Robi / Airtel)
**Document version:** 2.0
**Date:** 2026-07-18
**Author:** Rajon Talukdar
**Companion to:** `docs/SRS-Backend-Auth-Subscription.md` (server tier, accounts, subscription)

---

## Revision History

| Version | Date | Change |
|---|---|---|
| 2.0 | 2026-07-18 | Namaz Time feature specification. |

---

## 1. Introduction

### 1.1 Purpose

This document specifies the **Namaz Time (নামাজের সময়)** feature: a location-driven prayer-time
capability. The user supplies a location — by device GPS or by manual selection — and the app
computes and displays the five daily prayer times, plus sunrise, for that location.

Namaz Time occupies a bottom-navigation slot and is one of the app's two most-used screens.
It is **partially implemented**; §2 establishes the accurate baseline, and §4 specifies the
work required to complete it.

### 1.2 Scope

In scope:

- Location acquisition by GPS, with permission handling.
- Manual city selection and coordinate entry.
- Calculation-method and madhab configuration.
- Prayer-time computation, display, and next-prayer countdown.
- Azan notifications.
- Offline caching.
- The three related rows in the Settings screen.

Out of scope:

- All other features (Amal Tracker, Tasbeeh, Qibla, Hadith, Islamic Calendar, Names of Allah,
  Surah, Ramadan, Onboarding) except where they consume prayer times.
- Accounts, subscription, entitlement, and the server tier — specified in
  `docs/SRS-Backend-Auth-Subscription.md`.
- Premium gating. Namaz Time is a free-tier feature in its entirety.

### 1.3 Definitions and Abbreviations

| Term | Meaning |
|---|---|
| Namaz / Salah | The five obligatory daily Islamic prayers |
| Waqt | The time window of a single prayer |
| Azan | The call to prayer; here, the notification issued at prayer onset |
| Calculation method | Parameter set (solar depression angles) determining Fajr and Isha times |
| Madhab | Jurisprudential school; affects Asr calculation (Hanafi vs Shafi) |
| Adhan | The `adhan` Dart package (v2.0.0+1) used for astronomical prayer-time computation |
| SRS | Software Requirements Specification |

### 1.4 References

- `FEATURES.md` — feature and business plan (repository root)
- `docs/SRS-Backend-Auth-Subscription.md` — server tier, accounts, subscription
- `adhan` package: https://pub.dev/packages/adhan
- `geolocator` package: https://pub.dev/packages/geolocator
- `flutter_local_notifications` package: https://pub.dev/packages/flutter_local_notifications

---

## 2. Current System State

An accurate baseline is required because Namaz Time is **partially implemented**, not absent.

### 2.1 What already exists

| Component | File | State |
|---|---|---|
| Prayer time service | `lib/features/prayer_time/data/services/prayer_time_service.dart` | Functional. GPS fetch → adhan calculation → Bangla-labelled model. Falls back to Dhaka coordinates. |
| Calculation utility | `lib/app/utils/prayer_time_utils.dart` | Functional but **hardcoded** to `CalculationMethod.karachi` + `Madhab.hanafi`. |
| Prayer time model | `lib/features/prayer_time/domain/models/prayer_time_model.dart` | Holds six formatted time strings plus next-prayer name/time. Times are `String`, not `DateTime`. |
| Prayer time screen | `lib/features/prayer_time/presentation/view/prayer_time_screen.dart` | Renders six `PrayerCard`s. No countdown, no date, no location display. |
| View-model | `lib/features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart` | Single `FutureProvider`. No refresh, no caching, no error typing. |
| Home banner | `lib/features/home/presentation/widgets/next_prayer_banner.dart` | Exists. |
| Navigation | `lib/app/shell/main_shell.dart`, `widgets/bottom_nav_bar.dart` | নামাজ occupies bottom-nav index 2, routing to `AppRoutes.prayerTime`. |

### 2.2 Known gaps (the work of this specification)

| ID | Gap |
|---|---|
| G-01 | No manual location/city selection. GPS or silent Dhaka fallback only. |
| G-02 | Calculation method and madhab are hardcoded; `StorageKeys.calculationMethod` is defined but never read or written. |
| G-03 | `NotificationService.scheduleAzan()` is an empty stub containing only a `TODO`. No azan ever fires. |
| G-04 | No offline caching. Every launch re-acquires GPS; airplane mode with no GPS fix yields a silent wrong-location result. |
| G-05 | Settings rows for city, calculation method, and azan notification have empty `onTap: () {}` handlers. |
| G-06 | GPS denial and location-service-disabled both fall back to Dhaka **without informing the user**, producing silently incorrect times outside Dhaka. |
| G-07 | Model stores formatted strings, preventing countdown arithmetic and notification scheduling. |
| G-08 | `prayerTimeUtils.dhakeLat` is a typo (`dhake` vs `dhaka`). |

---

## 3. Overall Description

### 3.1 Product perspective

Amol365 is a Flutter application using feature-first clean architecture with Riverpod state
management and `go_router` navigation. Prayer times are computed astronomically **on-device**,
not fetched. Namaz Time has no server dependency of any kind and SHALL acquire none.

### 3.2 User classes

| Class | Description | Relevant needs |
|---|---|---|
| Primary user | A Bangladeshi Muslim adult using the app daily for prayer timing | Accurate times for their own location; reliable azan alert; works offline |
| Traveller user | A user outside their home district, or abroad | Location must follow them, or be manually overridable |
| Low-connectivity user | Rural user, intermittent data, older Android device | Must work with no network and no GPS fix |

### 3.3 Operating environment

- Android 6.0 (API 23) and above; iOS 13 and above.
- Flutter SDK ^3.11.5.
- Offline-capable. Network access is not required for any requirement in this document.

### 3.4 Design and implementation constraints

| ID | Constraint |
|---|---|
| C-01 | Prayer times MUST be computed on-device via the `adhan` package. No prayer-time API dependency. |
| C-02 | All user-facing strings MUST be in Bangla. Arabic content retains Arabic script. |
| C-03 | Persistence uses `SharedPreferences` via the existing `StorageService`. No new database. |
| C-04 | Feature-first clean architecture (`data/`, `domain/`, `presentation/`) MUST be preserved. |
| C-05 | Location permission is optional, never blocking. The app MUST be fully usable with permission permanently denied. |
| C-06 | Existing app size and cold-start budget must not regress materially. |
| C-07 | Namaz Time MUST remain free-tier and MUST NOT be gated by entitlement. |

### 3.5 Assumptions and dependencies

- The `adhan` package remains maintained and its results are accepted as authoritative.
- Device system clock and timezone are correct. The app does not attempt clock correction.
- Android background-execution restrictions (Doze, OEM battery managers) may delay notifications
  on some devices; this is a known platform limitation, mitigated but not eliminated.

---

## 4. Namaz Time (নামাজের সময়)

### 4.1 Feature overview

The user supplies a location — automatically via device GPS or manually via a Bangladeshi city
list or coordinate entry — and the app computes and displays that day's prayer times for that
location, highlights the next prayer with a live countdown, and optionally issues an azan
notification at each prayer's onset.

### 4.2 User stories

| ID | Story |
|---|---|
| US-01 | As a user, I want the app to detect my location so I get accurate prayer times without configuring anything. |
| US-02 | As a user who declines location permission, I want to pick my city from a list so I still get accurate times. |
| US-03 | As a traveller, I want to change my location at any time so times follow me. |
| US-04 | As a user, I want to see how long until the next prayer so I can plan. |
| US-05 | As a user, I want an azan notification at each prayer time so I do not miss a waqt. |
| US-06 | As a user following a specific madhab, I want to change the calculation method so times match my local mosque. |
| US-07 | As an offline user, I want prayer times to work with no network connection. |
| US-08 | As a user, I want to see tomorrow's or a chosen date's times so I can plan ahead (e.g. sehri during Ramadan). |

### 4.3 Functional Requirements — Location

**FR-N-01 — Location source selection**
The system SHALL support two mutually exclusive location sources, persisted across launches:
- **Automatic (GPS):** coordinates from the device location service.
- **Manual:** a user-selected city from a bundled list, or user-entered coordinates.

**FR-N-02 — Permission request flow**
On first entry to Namaz Time, the system SHALL request location permission with a Bangla
rationale explaining that the permission is used solely to compute prayer times. The request
SHALL NOT be made during app startup or onboarding.

**FR-N-03 — Permission denial handling**
If permission is denied or permanently denied, the system SHALL:
1. Present the manual city selector.
2. NOT silently fall back to Dhaka. *(Closes G-06.)*
3. Persist the manual choice and not re-prompt for permission on subsequent launches unless the
   user explicitly re-enables automatic location.

**FR-N-04 — Location service disabled**
If the device location service is off while source is Automatic, the system SHALL display an
actionable Bangla message offering to open location settings or switch to manual selection.

**FR-N-05 — Bundled city list**
The system SHALL bundle an offline list of Bangladeshi locations covering all 64 district
headquarters, each with name (Bangla), name (English, for search), latitude, and longitude.
The list SHALL be searchable in both scripts.

**FR-N-06 — Coordinate entry**
The system SHALL allow manual entry of latitude (−90..90) and longitude (−180..180) for users
outside Bangladesh, with validation and a Bangla error message on invalid input.

**FR-N-07 — Location caching**
The last resolved location (coordinates, display name, source) SHALL be persisted and used
immediately on launch, before any GPS acquisition completes. *(Closes G-04.)*

**FR-N-08 — Location staleness**
When source is Automatic, the system SHALL re-acquire coordinates if the cached fix is older
than 12 hours or the device has moved more than 50 km, and SHALL otherwise reuse the cache to
conserve battery.

**FR-N-09 — GPS timeout**
GPS acquisition SHALL time out after 15 seconds and fall back to the cached location, with a
non-blocking indication that cached data is in use.

### 4.4 Functional Requirements — Calculation

**FR-N-10 — Prayer times computed**
For a given location and date, the system SHALL compute: Fajr (ফজর), Sunrise (সূর্যোদয়),
Dhuhr (যোহর), Asr (আসর), Maghrib (মাগরিব), Isha (এশা).

**FR-N-11 — Selectable calculation method**
The system SHALL allow selection from at minimum: Karachi (default), Muslim World League,
Umm al-Qura, Egyptian, Moonsighting Committee. The selection SHALL persist via
`StorageKeys.calculationMethod`. *(Closes G-02.)*

**FR-N-12 — Selectable madhab**
The system SHALL allow selection of Hanafi (default) or Shafi, affecting Asr computation only,
persisted under a new `StorageKeys.madhab`.

**FR-N-13 — Manual time adjustment**
The system SHALL allow a per-prayer offset of −30 to +30 minutes so users can align with their
local mosque, persisted per prayer.

**FR-N-14 — Model refactor**
`PrayerTimesModel` SHALL store `DateTime` values rather than pre-formatted strings, with
formatting applied at the presentation layer. *(Closes G-07; prerequisite for FR-N-16 and
FR-N-20.)*

**FR-N-15 — Recomputation triggers**
Times SHALL be recomputed on: location change, calculation-method change, madhab change, offset
change, date rollover past midnight, and device timezone change.

### 4.5 Functional Requirements — Display

**FR-N-16 — Next-prayer countdown**
The Namaz Time screen SHALL display the next upcoming prayer and a live countdown in Bangla
numerals, updating at least once per second while the screen is visible and pausing when
backgrounded.

**FR-N-17 — Current-waqt indication**
The prayer whose waqt is currently active SHALL be visually distinguished from past and future
prayers.

**FR-N-18 — Location and date header**
The screen SHALL display the active location name, the Gregorian date, and the corresponding
Hijri date (via the existing `hijri_utils.dart`).

**FR-N-19 — Date navigation**
The user SHALL be able to view prayer times for any date within ±30 days of today, with a
control to return to today.

**FR-N-20 — Home banner integration**
`next_prayer_banner.dart` SHALL show the next prayer name and countdown, sourced from the same
provider as the Namaz Time screen — no duplicate computation.

**FR-N-21 — Loading and error states**
Every asynchronous state SHALL have a defined presentation: skeleton/shimmer while loading, and
a typed, actionable Bangla error message with a retry affordance on failure. Generic exception
text SHALL NOT be shown to the user.

### 4.6 Functional Requirements — Notifications

**FR-N-22 — Azan scheduling**
`NotificationService.scheduleAzan()` SHALL be implemented using `TZDateTime` and zoned
scheduling to fire at each enabled prayer's onset. *(Closes G-03.)*

**FR-N-23 — Per-prayer toggles**
The user SHALL be able to enable or disable notifications independently for each of the five
prayers. Sunrise SHALL NOT be notifiable.

**FR-N-24 — Pre-prayer reminder**
The user SHALL optionally enable a reminder 5/10/15/30 minutes before each enabled prayer.

**FR-N-25 — Notification permission**
On Android 13+ (API 33+), `POST_NOTIFICATIONS` SHALL be requested at the point the user first
enables a notification, not at startup. On denial, toggles SHALL be shown disabled with an
explanation and a path to system settings.

**FR-N-26 — Rescheduling**
All pending notifications SHALL be cancelled and rescheduled whenever times change (per
FR-N-15), and a rolling 7 days of notifications SHALL be maintained so alerts continue without
the app being opened.

**FR-N-27 — Notification content**
Each notification SHALL display the prayer name and time in Bangla and open the Namaz Time
screen when tapped.

**FR-N-28 — Sound mode**
The user SHALL choose between azan audio, default notification tone, or silent. If azan audio
is bundled, it SHALL be a single file no larger than 2 MB.

**FR-N-29 — Local delivery only**
Azan notifications SHALL be delivered locally via `flutter_local_notifications`. They SHALL NOT
be routed through any push service, so that prayer alerts never depend on connectivity.

### 4.7 Functional Requirements — Settings

**FR-N-30 — Wire existing settings rows**
The three নামাজ rows in `settings_screen.dart` SHALL be given working handlers and live
subtitles reflecting current state. *(Closes G-05.)*
- শহর নির্বাচন → location source and city selector
- হিসাব পদ্ধতি → calculation method and madhab
- আযান নোটিফিকেশন → per-prayer toggles, reminder offset, sound mode

### 4.8 Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | Accuracy | Computed times SHALL match the `adhan` reference implementation exactly for a given location, date, method, and madhab. |
| NFR-02 | Performance | With a cached location, the Namaz Time screen SHALL render times within 300 ms of navigation. |
| NFR-03 | Performance | Prayer-time computation SHALL NOT block the UI thread perceptibly. |
| NFR-04 | Battery | GPS SHALL be acquired at most once per 12 hours under normal use (per FR-N-08). Continuous location streaming is prohibited. |
| NFR-05 | Offline | All requirements in §4 SHALL function with no network connectivity. |
| NFR-06 | Reliability | Notifications SHALL fire within 60 seconds of the scheduled time on a device not under aggressive OEM battery restriction. |
| NFR-07 | Localisation | All user-facing strings in Bangla; numerals rendered in Bangla script. |
| NFR-08 | Accessibility | Text SHALL scale with system font size without clipping. Colour SHALL NOT be the sole indicator of the current waqt (per FR-N-17). |
| NFR-09 | Privacy | Coordinates SHALL NOT leave the device. No analytics or telemetry on location. |
| NFR-10 | Compatibility | Verified on Android 6.0 through the current Android release, and iOS 13+. |

### 4.9 Data Requirements

New `StorageKeys` entries:

| Key | Type | Default |
|---|---|---|
| `locationSource` | String (`auto` \| `manual`) | `auto` |
| `locationLat` | double (as String) | — |
| `locationLng` | double (as String) | — |
| `locationName` | String | — |
| `locationTimestamp` | int (epoch ms) | — |
| `madhab` | String | `hanafi` |
| `prayerOffsets` | String (JSON map) | `{}` |
| `azanPerPrayer` | String (JSON map) | all enabled |
| `preReminderMinutes` | int | `0` (off) |
| `azanSoundMode` | String | `default` |

Existing `calculationMethod` becomes live (currently written nowhere).

### 4.10 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-N-01 | Granting location permission yields times matching an independent reference for the tested coordinates. |
| AC-N-02 | Denying permission presents the city selector; no silent Dhaka fallback occurs. |
| AC-N-03 | Selecting a non-Dhaka district produces times differing appropriately from Dhaka's. |
| AC-N-04 | Airplane mode with a cached location renders full prayer times. |
| AC-N-05 | Changing calculation method visibly changes Fajr and Isha; changing madhab visibly changes Asr. |
| AC-N-06 | An enabled azan notification fires within 60 s of the prayer time with the device locked. |
| AC-N-07 | Disabling a prayer's toggle prevents its notification while others still fire. |
| AC-N-08 | The countdown decrements once per second and rolls over correctly at each prayer onset. |
| AC-N-09 | Crossing midnight while the screen is open advances to the new day's times without a manual refresh. |
| AC-N-10 | Changing the device timezone triggers recomputation. |
| AC-N-11 | All three settings rows open functional screens; subtitles reflect persisted state. |
| AC-N-12 | Unit tests cover calculation, offsets, and next-prayer selection including the post-Isha edge case. |
| AC-N-13 | The নামাজ bottom-nav tab navigates to the Namaz Time screen; index-to-route mapping verified for all five tabs. |

### 4.11 Edge cases

| ID | Case | Required behaviour |
|---|---|---|
| EC-01 | After Isha, before midnight | Next prayer is tomorrow's Fajr; countdown spans midnight correctly. |
| EC-02 | High latitude (>48°) | Apply an `adhan` high-latitude rule and inform the user the times are approximate. |
| EC-03 | Device clock manually wrong | Times are computed from device time; no correction attempted. Documented limitation. |
| EC-04 | Timezone change mid-session | Recompute (FR-N-15). |
| EC-05 | DST transition | Times remain correct across the transition; covered by test. |
| EC-06 | Coordinates (0, 0) or null island | Treat as invalid; fall back to manual selection. |
| EC-07 | Permission granted then revoked in system settings while backgrounded | On resume, detect and fall back to cached location with notice. |
| EC-08 | Offsets pushing prayers out of order | Reject or warn; prayer sequence must remain monotonic. |

---

## 5. Traceability

| Gap | Closed by |
|---|---|
| G-01 | FR-N-01, FR-N-05, FR-N-06 |
| G-02 | FR-N-11, FR-N-12 |
| G-03 | FR-N-22 |
| G-04 | FR-N-07, FR-N-08 |
| G-05 | FR-N-30 |
| G-06 | FR-N-03 |
| G-07 | FR-N-14 |
| G-08 | Corrected during FR-N-14 refactor |

| Constraint | Enforced by |
|---|---|
| C-01 | NFR-01 |
| C-05 | FR-N-03, AC-N-02 |
| C-07 | Namaz Time is absent from the premium table in `FEATURES.md` |
| NFR-05 | AC-N-04 |

---

## 6. Release Plan

| Release | Content | Gate |
|---|---|---|
| 2.0 | §4 Namaz Time | AC-N-01 … AC-N-13 all pass |

### 6.1 Relationship to the backend releases

Namaz Time is **independent of** `docs/SRS-Backend-Auth-Subscription.md` and its releases
3.0–3.4. It has no server dependency, no entitlement check, and no account requirement, and may
therefore be developed and shipped in parallel with the backend work without coordination.

The one intersection is startup ordering: once the subscription gate and login are introduced
(backend M-4), Namaz Time sits behind them in the navigation sequence. Its own requirement
NFR-05 — full function with no network — is what guarantees this does not degrade it, because a
returning user reaches Home from cached session state without a network call.

---
