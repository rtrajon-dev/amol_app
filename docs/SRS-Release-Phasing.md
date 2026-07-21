# Software Requirements Specification (SRS) — Release Phasing

**Product:** Amol365 — ইসলামিক আমল
**Package:** com.bdapps.amol365
**Document version:** 1.0
**Date:** 2026-07-20
**Author:** Rajon Talukdar
**Companion to:** `docs/SRS.md` (Namaz Time), `docs/SRS-Backend-Auth-Subscription.md` (server tier)

---

## Revision History

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-20 | Initial. Defines Phase 1 / Phase 2 scope and the feature-visibility mechanism. |
| 1.1 | 2026-07-20 | Surah withheld to Phase 2 alongside Hadith. Phase 1 therefore ships with no premium content, and the subscription gate becomes disabled-by-requirement rather than by fallback (§4). |
| 1.2 | 2026-07-21 | Monetisation changed: the whole app is the paid product, so Phase 1 ships with a MANDATORY paywall after login. Supersedes v1.1 §4 entirely. |

---

## 1. Introduction

### 1.1 Purpose

This document defines which features ship in **Phase 1** (first public release) and which are
withheld until **Phase 2**, and specifies the mechanism by which a withheld feature is hidden.

It exists because the decision is not a code detail. Hiding a feature changes what the premium
tier is worth, what the content pipeline must carry, and what a store reviewer sees — and those
consequences are spread across two other specifications that would otherwise silently
contradict this one. §7 lists the amendments this document makes to them.

### 1.2 Scope

In scope:

- The Phase 1 feature set and the Phase 2 deferral list.
- The feature-visibility mechanism (flagging, navigation, routing).
- The revised premium proposition for Phase 1.
- Content-catalogue consequences for M-5.

Out of scope:

- Feature behaviour itself, specified in the companion documents.
- Sourcing of religious content, which is an editorial task, not an engineering one (§6.2).

### 1.3 Definitions

| Term | Meaning |
|---|---|
| Phase 1 | The first public release on BDApps / Play Store |
| Phase 2 | A later release, date not yet fixed, adding the deferred features |
| Withheld | Implemented in the codebase but not reachable by a user |
| Feature flag | A boolean controlling whether a feature is reachable |

---

## 2. Rationale

Both withheld features are withheld for the same reason: **their content is not ready, and
partial religious content is worse than none.**

Hadith carries **two** hardcoded entries in `hadith_model.dart`. A "Hadith of the day" that
repeats every second day reads as an abandoned app rather than an incomplete one.

Surah ships eight popular surahs and is usable, but the full 114-surah corpus
(`surahs_full.json`) does not exist. Shipping a Quran feature that visibly stops at eight
invites the reasonable question of why the rest is missing, and answering it with a paywall
over content that has not been produced is worse than not shipping the feature yet.

Both also carry an accuracy obligation that ordinary app content does not. Misquoted Quranic
text or a misattributed, misgraded hadith presented as authentic to Bangladeshi Muslim users is
a harm no release deadline justifies. Withholding until properly sourced corpora exist is the
responsible default, not a delay to be minimised (FR-PH-10).

The 99 Names of Allah is **not** withheld: `names_of_allah.json` is populated and complete, and
it carries Phase 1's content value on its own.

---

## 3. Phase Scope

### 3.1 Phase 1 — shipped

| Feature | State |
|---|---|
| Prayer times (Namaz) + azan | Complete (`docs/SRS.md`) |
| Qibla compass | Complete |
| Amal tracker | Complete, SQLite-backed |
| Tasbeeh counter | Complete, SQLite-backed |
| 99 Names of Allah | Complete |
| Islamic calendar | Complete |
| Ramadan mode | Complete (pending checkbox wiring) |
| Auth, subscription, entitlement | Complete (M-2, M-3, M-4) |
| Push, telemetry, remote config | Complete (M-6) |
| Content sync | Mechanism complete (M-5, FR-C-02 … FR-C-07) |

### 3.2 Phase 2 — withheld

| Feature | Reason | Release condition |
|---|---|---|
| Hadith collection | Two entries only; corpus not sourced or graded | FR-PH-08 |
| Daily hadith push | Depends on the above | FR-PH-08 |
| Surah collection | `surahs_full.json` does not exist; 8 of 114 is a visibly partial Quran | FR-PH-11 |

---

## 4. Monetisation: the whole app is the product

`SRS-Backend-Auth-Subscription.md` §7.6 originally defined premium as specific *content* — all
114 surahs, the full 99 names, daily hadiths. Withholding Hadith and Surah left that model with
nothing to sell, and v1.1 of this document responded by shipping Phase 1 free.

**v1.2 replaces the model rather than patching it.** Amol365 is sold as a whole: prayer times,
azan, qibla, the amal tracker, tasbeeh, the calendar, the 99 Names and Ramadan mode are the
product, and access to them requires a subscription. Content differentiation is no longer what
the tier rests on, which is why withholding two content features no longer empties it.

**FR-MG-01 — Subscription is mandatory** (canonical ID: FR-G-06 in the backend SRS)
An authenticated user without entitlement SHALL NOT reach any feature. The gate is shown after
login and cannot be dismissed.

**FR-MG-02 — The gate follows login, not onboarding**
Order is Splash → Onboarding → Login/Register → Subscription → Home. A user must have an account
before subscribing, so entitlement always has an account to bind to (FR-S-12).

**FR-MG-03 — A gated user SHALL always be able to sign out**
The mandatory gate SHALL offer sign-out in place of the dismiss control. A user who cannot or
will not pay must never be trapped in an app with no exit and no route to another account.

**FR-MG-04 — Device-local data SHALL survive**
Losing entitlement SHALL NOT delete amal history, tasbeeh counts or streaks. Access is what
lapses, not the user's record of their own worship.

**FR-MG-05 — The kill switch is now load-bearing**
`subscription_gate_enabled` (FR-P-07) SHALL remain reachable from Remote Config. Under a soft
gate it was a convenience; under a mandatory one it is the only way to release users if BDApps
billing fails, and a carrier outage would otherwise lock every user out of an app they cannot
buy. Setting it false SHALL make every feature reachable without subscription.

**FR-MG-06 — Lapsing stops everything, azan included**
When entitlement is lost, scheduled azan notifications SHALL be cancelled. Pending alarms
outlive the app process, so a lapse that only guards the UI would keep delivering the paid
feature indefinitely. Conversely, a new subscription SHALL reschedule them immediately, so a
subscriber never silently misses prayers waiting for some other trigger.

> **Deliberate product risks, accepted:**
> - **No trial.** A user is asked to pay having seen nothing but the login screen. This is the
>   weakest conversion position, and OQ-PH-01 tracks whether it holds up in the field.
> - **Offline first run.** Registering requires a network, so a first-run user with no data
>   cannot enter at all. After one successful check, FR-S-15's 24h TTL + 7 day grace carries a
>   subscriber for up to 31 days offline.
> - **BDApps store only.** Google Play requires Play Billing for digital goods, so carrier
>   billing for app access is not Play-safe. Publishing to Play later requires FR-MG-07.

**FR-MG-07 — Play Store variant (deferred)**
Should Amol365 be published on Google Play, the mandatory carrier-billing gate SHALL be replaced
by Play Billing or the app SHALL ship without a paywall on that channel. This is a distribution
blocker, not a preference.

---

## 5. Functional Requirements — feature visibility

**FR-PH-05 — Single source of truth**
Feature visibility SHALL be expressed as named flags in one place. No feature SHALL be hidden
by commenting out code, deleting routes, or any means that must be manually reversed in
Phase 2 — a withheld feature is temporarily invisible, not removed.

**FR-PH-06 — Default off, remotely enableable**
The Hadith and Surah flags SHALL each default to `false` in the shipped binary and SHALL be
overridable by Firebase Remote Config, following the pattern already established by
`daily_hadith_push_enabled`. This allows either feature to be enabled without an APK release
once its content is live, and allows them to be enabled independently.

**FR-PH-07 — Hidden means unreachable, not merely unlisted**
When a flag is off, the feature SHALL be absent from:
- the home screen quick-action grid,
- bottom navigation, if present there,
- any settings entry,
- and its routes SHALL redirect to Home rather than render.

Removing the tile while leaving the route live is insufficient: a deep link, a notification, or
a stale back-stack entry would otherwise land the user on a screen the phase is meant to
withhold. For Surah this includes the detail route (`/surah/:id`), not only the list.

**FR-PH-08 — Withheld code still builds and is still tested**
The Hadith and Surah sources, models, screens and tests SHALL remain in the tree and SHALL
continue to compile and pass. Withheld code that rots is not withheld; it is broken code with a
later delivery date.

**FR-PH-09 — No dangling promises**
No user-facing string, onboarding screen, store listing, or premium comparison shown in Phase 1
SHALL reference hadith or surah features. The §7.6 gating table is amended accordingly (§7).

**FR-PH-10 — Phase 2 release condition, Hadith**
The Hadith flag SHALL NOT be enabled until all of:
1. `hadiths.json` exists with a corpus of at least 100 entries,
2. every entry carries its collection, reference and grading,
3. the content is sourced from a named authoritative collection, recorded in `docs/CONTENT.md`,
4. and the file is reachable through the M-5 content manifest.

**FR-PH-11 — Phase 2 release condition, Surah**
The Surah flag SHALL NOT be enabled until all of:
1. `surahs_full.json` exists and contains all 114 surahs,
2. Arabic text is reproduced from a named authoritative source (FR-PH-12),
3. and the file is reachable through the M-5 content manifest.

For both: enabling a flag against absent content would show users an empty screen, which is a
worse failure than the one this deferral exists to prevent.

---

## 6. Content requirements

### 6.1 Manifest catalogue

`content/manifest.php` advertises `hadiths`, `surahs` and `surahsFull` to every client. A
Phase 1 client can display none of them, so downloading any is wasted bytes on a metered
connection.

**FR-PH-12 — Client-side filtering**
The content sync client SHALL skip manifest keys belonging to withheld features. The existing
"unknown key" path in `ContentSyncService.fileNames` already provides this: removing `hadiths`,
`surahs` and `surahsFull` from that map makes a Phase 1 client ignore them with no server
change, and restoring them in Phase 2 costs three lines.

The server SHALL NOT be modified for this. It continues to advertise everything it holds, which
keeps a single manifest correct for clients of both phases simultaneously — a Phase 1 and a
Phase 2 APK will be in the field at the same time.

### 6.2 Sourcing obligation

**FR-PH-13 — Named sources**
Quran text and hadith corpora SHALL be sourced from a named, verifiable published source,
recorded in `docs/CONTENT.md` before shipping. Content SHALL NOT be transcribed from memory,
generated, or assembled from unattributed web sources.

This governs `surahs_full.json` and `hadiths.json`, and applies equally to the eight surahs
already bundled in `surahs.json`, whose provenance SHALL be recorded before Phase 2 enables the
feature.

---

## 7. Amendments to companion documents

This document supersedes the following where they conflict.

| Document | Location | Amendment |
|---|---|---|
| `SRS-Backend-Auth-Subscription.md` | §7.6 premium table | Superseded. Premium is no longer a content tier: the WHOLE app requires a subscription (FR-MG-01). Hadith and Surah remain Phase 2 regardless. |
| `SRS-Backend-Auth-Subscription.md` | §8, FR-G-01/FR-G-02 | Superseded. The gate is MANDATORY and sits AFTER login, not before it. FR-S-08 (soft gate) and FR-S-09 (three-prompt cap) no longer apply. |
| `SRS-Backend-Auth-Subscription.md` | §9, FR-C-01 | The Phase 1 bundled baseline is `cities.json` and `names_of_allah.json` only. |
| `SRS-Backend-Auth-Subscription.md` | §15.1 sequencing note | Superseded. The tier does not depend on content landing, so M-5 no longer races Release 3.2. |
| `SRS-Backend-Auth-Subscription.md` | §15 release plan | Add: Phase 2 enables the Hadith and Surah flags; no APK release required if Remote Config carries them. |
| `FEATURES.md` | Feature list, monetisation | Mark hadith and surah features Phase 2. Remove the Phase 1 premium comparison entirely. |

---

## 8. Acceptance criteria

| ID | Criterion |
|---|---|
| AC-PH-01 | With the flags off, no route, tile, nav entry or settings row leads to Hadith or Surah. |
| AC-PH-02 | With the flags off, navigating directly to `/hadith`, `/surah` or `/surah/:id` lands on Home without crashing. |
| AC-PH-03 | With a flag on, that feature is reachable and behaves as before. |
| AC-PH-04 | The flags are independent: enabling Surah does not enable Hadith. |
| AC-PH-05 | Toggling a Remote Config flag changes visibility without an app update. |
| AC-PH-06 | `flutter analyze` is clean and the full suite passes with the flags both off and on. |
| AC-PH-07 | No Phase 1 user-facing string mentions hadith or surah. |
| AC-PH-08 | A Phase 1 client ignores the `hadiths`, `surahs` and `surahsFull` manifest keys and downloads none of them. |
| AC-PH-09 | An authenticated user without entitlement cannot reach any feature; every route lands on the gate. |
| AC-PH-10 | The gate has no dismiss control and the system back gesture does not bypass it. |
| AC-PH-11 | A gated user can sign out from the gate and reach the login screen. |
| AC-PH-12 | Subscribing dismisses the gate immediately, with no relaunch. |
| AC-PH-13 | A subscriber whose entitlement is stale but inside the grace window is NOT gated (FR-S-15). |
| AC-PH-14 | Setting `subscription_gate_enabled` false releases every user without an app update (FR-MG-05). |
| AC-PH-15 | Losing entitlement cancels pending azan notifications; regaining it reschedules them (FR-MG-06). |
| AC-PH-16 | Amal history, tasbeeh counts and streaks survive a lapse and a re-subscribe (FR-MG-04). |
| AC-PH-17 | A Phase 1 build with Firebase entirely unreachable still hides Hadith and Surah and still enforces the paywall. |

---

## 9. Open Questions

| ID | Question | Owner |
|---|---|---|
| OQ-PH-01 | No trial: users are asked to pay having seen only the login screen. Measure install → subscribe conversion early; if it is poor, a trial or a free tier is the first lever. | Product owner |
| OQ-PH-02 | Which hadith collection and grading standard will be used? Needed before Phase 2 work begins. | Product owner |
| OQ-PH-03 | Which Quran source for `surahs_full.json` — Tanzil, King Fahd Complex, or another? Needed before Phase 2. | Product owner |
| OQ-PH-04 | Does Phase 2 have a target date, or is it content-ready-driven? Affects whether Remote Config enablement suffices or a full release is planned. | Product owner |
| OQ-PH-05 | A first-run user with no data connection cannot register and therefore cannot enter at all. Acceptable for a carrier-distributed app, or is an offline-tolerant path needed? | Product owner |
| OQ-PH-06 | Is the Phase 1 feature set worth 5 BDT/week to a user who has seen none of it? Remaining: prayer times, azan, qibla, amal tracker, tasbeeh, 99 Names, calendar, Ramadan. | Product owner |
| OQ-PH-07 | Existing Phase 1 installs, if any ship before the paywall: an update that locks them out is hostile. Grandfather them, or is this pre-launch only? | Product owner |
