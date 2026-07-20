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

## 4. Consequence: Phase 1 ships free

`SRS-Backend-Auth-Subscription.md` §7.6 defines premium value as *"all 114 surahs, full 99
names, daily hadiths"*. Withholding both Hadith and Surah removes two of the three, and the
third — the 99 Names — is not currently gated anywhere in the code.

**Phase 1 therefore has no sellable premium content.** The only premium-gated element in the
codebase is a single `tahajjud` item in the amal tracker (`amal_item_model.dart`). A 5 BDT/week
subscription whose entire value is one extra checkbox is not a product; it is a refund
liability, a likely store-review objection, and a fast route to BDApps complaints.

This is not a defect to be worked around. It is the correct consequence of deferring both
content features, and the release plan follows it rather than fighting it.

**FR-PH-01 — Phase 1 SHALL ship with the subscription gate disabled**
The `subscription_gate_enabled` Remote Config flag (FR-P-07) SHALL be `false` for Phase 1, and
the shipped default SHALL also be `false` so that a device which never reaches Firebase behaves
identically. Every Phase 1 feature is free.

This is now a requirement, not a fallback. In v1.0 of this document it was the contingency if
`surahs_full.json` slipped; with Surah withheld there is nothing left for the gate to sell.

**FR-PH-02 — No visible subscription surface in Phase 1**
While the gate is disabled, the app SHALL NOT show subscription entry points: the premium row
in Settings, the `PremiumLock` badge, and the automatic gate prompt (FR-S-09) SHALL all be
absent. The `tahajjud` amal item SHALL be free in Phase 1 rather than locked against a tier the
user cannot buy.

**FR-PH-03 — The subscription implementation is retained, not removed**
M-2, M-3 and M-4 remain in the codebase, tested and working. Phase 2 enables the tier by
flipping the flag once content exists; no re-implementation is required. Deleting the
subscription code because Phase 1 does not use it would be a costly and unnecessary reversal.

**FR-PH-04 — Auth remains in force**
Disabling the paywall does not disable accounts. FR-G-03's login requirement is unchanged, so
entitlement can be attached to an existing user base the moment Phase 2 turns the tier on.

> **Open question OQ-PH-05 (§9):** if Phase 1 is entirely free, is mandatory login still
> wanted? It is friction ahead of any paid value. This is a product decision, not a technical
> one, and the answer changes FR-PH-04.

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
| `SRS-Backend-Auth-Subscription.md` | §7.6 premium table | "Hadith of the day" and "Surah collection" are both **Phase 2**. Phase 1 has no premium tier. |
| `SRS-Backend-Auth-Subscription.md` | §7, FR-S-* | The subscription gate is disabled for Phase 1 (FR-PH-01). The flow remains implemented and tested. |
| `SRS-Backend-Auth-Subscription.md` | §9, FR-C-01 | The Phase 1 bundled baseline is `cities.json` and `names_of_allah.json` only. |
| `SRS-Backend-Auth-Subscription.md` | §15.1 sequencing note | Superseded. The premium tier is not thin, it is absent by design until Phase 2. |
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
| AC-PH-09 | The subscription gate is disabled, and no premium badge, settings row or gate prompt appears anywhere in Phase 1. |
| AC-PH-10 | The `tahajjud` amal item is completable by every Phase 1 user. |
| AC-PH-11 | A Phase 1 build with Firebase entirely unreachable still hides both features and still shows no paywall. |

---

## 9. Open Questions

| ID | Question | Owner |
|---|---|---|
| OQ-PH-01 | Phase 1 now earns nothing. Is that accepted for a first release building an audience, or is a Phase 1 revenue path wanted (e.g. ads, per FR-OQ-04 in the backend SRS)? | Product owner |
| OQ-PH-02 | Which hadith collection and grading standard will be used? Needed before Phase 2 work begins. | Product owner |
| OQ-PH-03 | Which Quran source for `surahs_full.json` — Tanzil, King Fahd Complex, or another? Needed before Phase 2. | Product owner |
| OQ-PH-04 | Does Phase 2 have a target date, or is it content-ready-driven? Affects whether Remote Config enablement suffices or a full release is planned. | Product owner |
| OQ-PH-05 | With Phase 1 entirely free, is mandatory login (FR-G-03) still wanted? It is friction ahead of any paid value, and the strongest argument for it — attaching entitlement — does not apply until Phase 2. | Product owner |
| OQ-PH-06 | Does hiding Surah leave Phase 1 with enough to justify a release? Remaining: prayer times, azan, qibla, amal tracker, tasbeeh, 99 Names, calendar, Ramadan. | Product owner |
