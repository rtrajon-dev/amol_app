# Software Requirements Specification (SRS)

**Product:** ইসলামিক আমল (Islamic Amol)
**Package:** com.bdapps.islamic_amol
**Platform:** Android (primary), iOS (secondary)
**Target market:** Bangladeshi Muslims, distributed via BDApps (Robi / Airtel)
**Document version:** 1.0
**Date:** 2026-07-18
**Author:** Rajon Talukdar

---

## Revision History

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-18 | Initial SRS. Covers removal of the Dua module (Release 1.1) and the Namaz Time feature (Release 2.0). |

---

## 1. Introduction

### 1.1 Purpose

This document specifies the requirements for two scoped changes to the Islamic Amol mobile application:

1. **Release 1.1 — Dua module removal.** The Dua (দোয়া) feature is withdrawn from the product. This SRS defines what must be removed, what must be preserved, and how the vacated navigation slot is handled.
2. **Release 2.0 — Namaz Time (নামাজের সময়).** A location-driven prayer-time feature. The user supplies a location — by device GPS or by manual selection — and the app computes and displays the five daily prayer times, plus sunrise, for that location. **This release is deferred and MUST NOT be implemented until explicitly authorised by the product owner.**

### 1.2 Scope

In scope:

- Removal of all Dua screens, models, view-models, routes, and navigation entry points.
- Completion of the Namaz Time feature: location acquisition, manual city selection, calculation-method configuration, next-prayer countdown, azan notifications, offline caching.

Out of scope:

- All other existing features (Amal Tracker, Tasbeeh, Qibla, Hadith, Islamic Calendar, Names of Allah, Surah, Ramadan, Onboarding) except where they reference Dua or prayer times.
- Monetisation, premium subscription, and BDApps billing integration.
- Backend services. The application remains fully offline-capable and device-local.

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

### 2.2 Known gaps (the work of Release 2.0)

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

Islamic Amol is a standalone Flutter application using feature-first clean architecture with Riverpod state management and `go_router` navigation. All data is device-local; there is no server component. Prayer times are computed astronomically on-device, not fetched.

### 3.2 User classes

| Class | Description | Relevant needs |
|---|---|---|
| Primary user | A Bangladeshi Muslim adult using the app daily for prayer timing and amal tracking | Accurate times for their own location; reliable azan alert; works offline |
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

### 3.5 Assumptions and dependencies

- The `adhan` package remains maintained and its results are accepted as authoritative.
- Device system clock and timezone are correct. The app does not attempt clock correction.
- Android background-execution restrictions (Doze, OEM battery managers) may delay notifications on some devices; this is a known platform limitation, mitigated but not eliminated.

---

## 4. Release 1.1 — Dua Module Removal

### 4.1 Rationale

The Dua feature is being withdrawn from the product. Its bottom-navigation slot is reallocated to Namaz Time.

### 4.2 Functional Requirements

**FR-D-01 — Remove Dua source module**
The directory `lib/features/dua/` and all six files within it SHALL be deleted:
- `domain/models/dua_model.dart`
- `presentation/viewmodel/dua_viewmodel.dart`
- `presentation/view/dua_screen.dart`
- `presentation/view/dua_detail_screen.dart`
- `presentation/widgets/dua_card.dart`
- `presentation/widgets/dua_category_chip.dart`

**FR-D-02 — Remove routes**
`AppRoutes.dua` and `AppRoutes.duaDetail` SHALL be removed from `lib/app/router/app_routes.dart`, and their corresponding `GoRoute` entries and imports removed from `lib/app/router/app_router.dart`.

**FR-D-03 — Reallocate navigation slot**
The দোয়া tab in `lib/app/shell/widgets/bottom_nav_bar.dart` and the corresponding entry in `MainShell._tabs` SHALL be replaced by a **নামাজ** tab pointing at `AppRoutes.prayerTime`, with icon `Icons.access_time_outlined` / `Icons.access_time`.

*Note:* The bottom nav retains five tabs (হোম, আমল, নামাজ, তাসবিহ, রমজান). `MainShell._tabs` and the `BottomNavigationBar.items` list are positionally coupled — both MUST be edited together or navigation will route to the wrong screen.

**FR-D-04 — Remove home quick-action**
The দোয়া `_QuickItem` at `lib/features/home/presentation/view/home_screen.dart:76` SHALL be removed. The remaining quick-action grid MUST re-flow without a visual gap.

**FR-D-05 — Preserve unrelated Dua-named content**
The following are semantically distinct from the Dua module and SHALL NOT be removed:
- `AmalType.dua` enum member and the `morning_azkar` / `evening_azkar` amal items in `lib/features/amal_tracker/domain/models/amal_item_model.dart` — these are amal-tracker checklist items.
- The `iftar_dua` Ramadan amal item in `lib/features/ramadan/domain/models/ramadan_model.dart`.

**FR-D-06 — Migrate persisted state**
If a user's persisted state references a Dua route as a last-visited location, the app SHALL fall back to `AppRoutes.home` rather than failing to route. No Dua-specific `StorageKeys` exist, so no key cleanup is required.

**FR-D-07 — Update documentation**
`FEATURES.md` SHALL be updated to remove `dua/` from the architecture tree and remove Dua from the feature list.

### 4.3 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-D-01 | `grep -ri "dua" lib/` returns matches only in `amal_item_model.dart`, `ramadan_model.dart`, and font licence files. |
| AC-D-02 | `flutter analyze` reports zero errors and no new warnings. |
| AC-D-03 | Every bottom-nav tab navigates to its labelled screen; index-to-route mapping verified for all five tabs. |
| AC-D-04 | Navigating to the legacy path `/dua` results in the router's not-found handling, not a crash. |
| AC-D-05 | Upgrading from 1.0 with existing `SharedPreferences` data launches successfully to Home. |

---

## 5. Release 2.0 — Namaz Time (নামাজের সময়)

> **Status: DEFERRED.** Requirements in this section are specified but MUST NOT be implemented until the product owner explicitly authorises Release 2.0.

### 5.1 Feature overview

The user supplies a location — automatically via device GPS or manually via a Bangladeshi city list or coordinate entry — and the app computes and displays that day's prayer times for that location, highlights the next prayer with a live countdown, and optionally issues an azan notification at each prayer's onset.

### 5.2 User stories

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

### 5.3 Functional Requirements — Location

**FR-N-01 — Location source selection**
The system SHALL support two mutually exclusive location sources, persisted across launches:
- **Automatic (GPS):** coordinates from the device location service.
- **Manual:** a user-selected city from a bundled list, or user-entered coordinates.

**FR-N-02 — Permission request flow**
On first entry to Namaz Time, the system SHALL request location permission with a Bangla rationale explaining that the permission is used solely to compute prayer times. The request SHALL NOT be made during app startup or onboarding.

**FR-N-03 — Permission denial handling**
If permission is denied or permanently denied, the system SHALL:
1. Present the manual city selector.
2. NOT silently fall back to Dhaka. *(Closes G-06.)*
3. Persist the manual choice and not re-prompt for permission on subsequent launches unless the user explicitly re-enables automatic location.

**FR-N-04 — Location service disabled**
If the device location service is off while source is Automatic, the system SHALL display an actionable Bangla message offering to open location settings or switch to manual selection.

**FR-N-05 — Bundled city list**
The system SHALL bundle an offline list of Bangladeshi locations covering all 64 district headquarters, each with name (Bangla), name (English, for search), latitude, and longitude. The list SHALL be searchable in both scripts.

**FR-N-06 — Coordinate entry**
The system SHALL allow manual entry of latitude (−90..90) and longitude (−180..180) for users outside Bangladesh, with validation and a Bangla error message on invalid input.

**FR-N-07 — Location caching**
The last resolved location (coordinates, display name, source) SHALL be persisted and used immediately on launch, before any GPS acquisition completes. *(Closes G-04.)*

**FR-N-08 — Location staleness**
When source is Automatic, the system SHALL re-acquire coordinates if the cached fix is older than 12 hours or the device has moved more than 50 km, and SHALL otherwise reuse the cache to conserve battery.

**FR-N-09 — GPS timeout**
GPS acquisition SHALL time out after 15 seconds and fall back to the cached location, with a non-blocking indication that cached data is in use.

### 5.4 Functional Requirements — Calculation

**FR-N-10 — Prayer times computed**
For a given location and date, the system SHALL compute: Fajr (ফজর), Sunrise (সূর্যোদয়), Dhuhr (যোহর), Asr (আসর), Maghrib (মাগরিব), Isha (এশা).

**FR-N-11 — Selectable calculation method**
The system SHALL allow selection from at minimum: Karachi (default), Muslim World League, Umm al-Qura, Egyptian, Moonsighting Committee. The selection SHALL persist via `StorageKeys.calculationMethod`. *(Closes G-02.)*

**FR-N-12 — Selectable madhab**
The system SHALL allow selection of Hanafi (default) or Shafi, affecting Asr computation only, persisted under a new `StorageKeys.madhab`.

**FR-N-13 — Manual time adjustment**
The system SHALL allow a per-prayer offset of −30 to +30 minutes so users can align with their local mosque, persisted per prayer.

**FR-N-14 — Model refactor**
`PrayerTimesModel` SHALL store `DateTime` values rather than pre-formatted strings, with formatting applied at the presentation layer. *(Closes G-07; prerequisite for FR-N-16 and FR-N-20.)*

**FR-N-15 — Recomputation triggers**
Times SHALL be recomputed on: location change, calculation-method change, madhab change, offset change, date rollover past midnight, and device timezone change.

### 5.5 Functional Requirements — Display

**FR-N-16 — Next-prayer countdown**
The Namaz Time screen SHALL display the next upcoming prayer and a live countdown in Bangla numerals, updating at least once per second while the screen is visible and pausing when backgrounded.

**FR-N-17 — Current-waqt indication**
The prayer whose waqt is currently active SHALL be visually distinguished from past and future prayers.

**FR-N-18 — Location and date header**
The screen SHALL display the active location name, the Gregorian date, and the corresponding Hijri date (via the existing `hijri_utils.dart`).

**FR-N-19 — Date navigation**
The user SHALL be able to view prayer times for any date within ±30 days of today, with a control to return to today.

**FR-N-20 — Home banner integration**
`next_prayer_banner.dart` SHALL show the next prayer name and countdown, sourced from the same provider as the Namaz Time screen — no duplicate computation.

**FR-N-21 — Loading and error states**
Every asynchronous state SHALL have a defined presentation: skeleton/shimmer while loading, and a typed, actionable Bangla error message with a retry affordance on failure. Generic exception text SHALL NOT be shown to the user.

### 5.6 Functional Requirements — Notifications

**FR-N-22 — Azan scheduling**
`NotificationService.scheduleAzan()` SHALL be implemented using `TZDateTime` and zoned scheduling to fire at each enabled prayer's onset. *(Closes G-03.)*

**FR-N-23 — Per-prayer toggles**
The user SHALL be able to enable or disable notifications independently for each of the five prayers. Sunrise SHALL NOT be notifiable.

**FR-N-24 — Pre-prayer reminder**
The user SHALL optionally enable a reminder 5/10/15/30 minutes before each enabled prayer.

**FR-N-25 — Notification permission**
On Android 13+ (API 33+), `POST_NOTIFICATIONS` SHALL be requested at the point the user first enables a notification, not at startup. On denial, toggles SHALL be shown disabled with an explanation and a path to system settings.

**FR-N-26 — Rescheduling**
All pending notifications SHALL be cancelled and rescheduled whenever times change (per FR-N-15), and a rolling 7 days of notifications SHALL be maintained so alerts continue without the app being opened.

**FR-N-27 — Notification content**
Each notification SHALL display the prayer name and time in Bangla and open the Namaz Time screen when tapped.

**FR-N-28 — Sound mode**
The user SHALL choose between azan audio, default notification tone, or silent. If azan audio is bundled, it SHALL be a single file no larger than 2 MB.

### 5.7 Functional Requirements — Settings

**FR-N-29 — Wire existing settings rows**
The three নামাজ rows in `settings_screen.dart` SHALL be given working handlers and live subtitles reflecting current state. *(Closes G-05.)*
- শহর নির্বাচন → location source and city selector
- হিসাব পদ্ধতি → calculation method and madhab
- আযান নোটিফিকেশন → per-prayer toggles, reminder offset, sound mode

### 5.8 Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | Accuracy | Computed times SHALL match the `adhan` reference implementation exactly for a given location, date, method, and madhab. |
| NFR-02 | Performance | With a cached location, the Namaz Time screen SHALL render times within 300 ms of navigation. |
| NFR-03 | Performance | Prayer-time computation SHALL NOT block the UI thread perceptibly. |
| NFR-04 | Battery | GPS SHALL be acquired at most once per 12 hours under normal use (per FR-N-08). Continuous location streaming is prohibited. |
| NFR-05 | Offline | All requirements in §5 SHALL function with no network connectivity. |
| NFR-06 | Reliability | Notifications SHALL fire within 60 seconds of the scheduled time on a device not under aggressive OEM battery restriction. |
| NFR-07 | Localisation | All user-facing strings in Bangla; numerals rendered in Bangla script. |
| NFR-08 | Accessibility | Text SHALL scale with system font size without clipping. Colour SHALL NOT be the sole indicator of the current waqt (per FR-N-17). |
| NFR-09 | Privacy | Coordinates SHALL NOT leave the device. No analytics or telemetry on location. |
| NFR-10 | Compatibility | Verified on Android 6.0 through the current Android release, and iOS 13+. |

### 5.9 Data Requirements

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

### 5.10 Acceptance criteria

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

### 5.11 Edge cases

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

## 6. Traceability

| Gap | Closed by |
|---|---|
| G-01 | FR-N-01, FR-N-05, FR-N-06 |
| G-02 | FR-N-11, FR-N-12 |
| G-03 | FR-N-22 |
| G-04 | FR-N-07, FR-N-08 |
| G-05 | FR-N-29 |
| G-06 | FR-N-03 |
| G-07 | FR-N-14 |
| G-08 | Corrected during FR-N-14 refactor |

---

## 7. Release Plan

| Release | Content | Gate |
|---|---|---|
| 1.1 | §4 Dua removal | AC-D-01 … AC-D-05 all pass |
| 2.0 | §5 Namaz Time | Product-owner authorisation to begin; then AC-N-01 … AC-N-12 all pass |

Release 1.1 is independently shippable and does not depend on Release 2.0. However, FR-D-03 reassigns the vacated nav slot to the existing (basic) Namaz Time screen — so that screen becomes more prominent in 1.1 while still carrying the §2.2 gaps. This is accepted: the existing screen is functional for Dhaka-area users, which is the majority of the target market.

---

## 8. Open Questions

| ID | Question | Owner |
|---|---|---|
| OQ-01 | Should azan audio be bundled (app-size cost) or should the default notification tone suffice for v2.0? | Product owner |
| OQ-02 | Is the 64-district list sufficient, or are upazila-level locations required? | Product owner |
| OQ-03 | Should Release 1.1 ship the nav-slot change, or ship Dua removal with a four-tab nav and add the নামাজ tab in 2.0? | Product owner |
| OQ-04 | Is any Dua content to be preserved for possible reintroduction, or is removal permanent? | Product owner |
