# Software Requirements Specification (SRS) — Backend, Authentication & Subscription

**Product:** ইসলামিক আমল (Islamic Amol)
**Package:** com.bdapps.islamic_amol
**Platform:** Android (primary), iOS (secondary)
**Target market:** Bangladeshi Muslims, distributed via BDApps (Robi / Airtel)
**Document version:** 1.0
**Date:** 2026-07-18
**Author:** Rajon Talukdar
**Companion to:** `docs/SRS.md` v2.0 (Namaz Time)

---

## Revision History

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-18 | Initial SRS. Introduces the server tier, email/password authentication, BDApps subscription & entitlement, content sync, and push notifications, specified as seven independently-shippable modules. |

---

## 1. Introduction

### 1.1 Purpose

`docs/SRS.md` §3.1 states that the application is *"standalone… All data is device-local; there is no server component."* This document specifies the controlled introduction of a server tier and the two user-facing flows that depend on it — **subscription** and **authentication** — without surrendering the offline-first property that makes the product viable for its target market.

It is written **module-based**: each module (§5–§11) is separately specified, separately testable, and separately shippable. Modules declare their dependencies explicitly. No module may be assumed present by another except where stated.

### 1.2 Scope

**In scope:**

- The server tier: hosting model, versioned public API surface, and data store.
- Email/password account system (registration, login, session persistence, password reset).
- BDApps subscription integration: status check, OTP subscribe, unsubscribe.
- The entitlement abstraction that separates *"is this user premium?"* from *"how is billing implemented?"*
- The revised startup navigation sequence.
- Remote content delivery (manifest-based) and push notification transport.
- The decommissioning path for BDApps.

**Out of scope:**

- Any modification whatsoever to the existing Amol365 web application or its BDApps PHP scripts (see C-BE-01).
- Prayer time, Qibla, Tasbeeh, Amal Tracker, Hadith, Calendar, Names of Allah, Surah, and Ramadan feature logic. These remain device-local and are affected only by premium gating (§7.6).
- Audio recitation delivery (deferred; see §12.3).
- Server-side analytics dashboards.

### 1.3 Definitions and Abbreviations

| Term | Meaning |
|---|---|
| BDApps | Robi/Airtel developer platform providing carrier billing, SMS, and USSD APIs |
| Carrier billing | Charging a subscription to the user's mobile balance rather than a card |
| `subscriberId` | BDApps subscriber identifier, format `tel:8801XXXXXXXXX` |
| `referenceNo` | Opaque token returned by BDApps OTP request, required to verify that OTP |
| REGISTERED / UNREGISTERED | BDApps `subscriptionStatus` values meaning subscribed / not subscribed |
| S1000 | BDApps `statusCode` denoting a successful operation |
| Entitlement | The app's internal answer to "what may this user access" — `free` or `premium` |
| Gate | A screen that stands between launch and Home |
| Soft gate | A gate the user may dismiss without completing it |
| Hard gate | A gate the user must complete to proceed |
| TTL | Time-to-live; the period a cached value is honoured before revalidation |
| JWT | JSON Web Token, used here as the session credential |
| Frozen contract | An external interface this project consumes but must not modify |

### 1.4 References

- `docs/SRS.md` v2.0 — Namaz Time
- `FEATURES.md` — feature and business plan, including the free/premium tier table
- Amol365 web application — reference implementation of the BDApps flow, at `/amol365`
- BDApps subscription API: `https://developer.bdapps.com/subscription/*`

---

## 2. Current System State

### 2.1 What exists

| Component | State |
|---|---|
| Flutter client | 13 feature modules, feature-first clean architecture, Riverpod, go_router |
| `StorageService` | `SharedPreferences` wrapper; 8 keys defined in `StorageKeys` |
| `flutter_secure_storage` | **In `pubspec.yaml` but unused.** No code references it. |
| `dio` | **In `pubspec.yaml` but unused.** No HTTP call exists anywhere in `lib/`. |
| `connectivity_plus` | In `pubspec.yaml`; no connectivity-aware logic implemented |
| Authentication | **None.** No user model, no auth feature, no token handling. |
| Subscription | **None.** No BDApps code in the Flutter app. |
| Server tier | **None** for this app. |
| `lib/assets/data/` | **Empty.** Every JSON-backed content feature is a shell. |

### 2.2 What exists outside this repository

The Amol365 web application at `/amol365` implements the complete BDApps flow in PHP and is **in production**. Its `bdapps/` directory is a **frozen contract** for the purposes of this document (C-BE-01). Its behaviour, as read from source:

| Script | Method | Request (form-encoded) | Response (JSON) |
|---|---|---|---|
| `check_subscription.php` | POST | `user_mobile` | `{subscriptionStatus, isSubscribed, statusCode, statusDetail, version, subscriberId}` |
| `send_otp.php` | POST | `user_mobile` | `{success, referenceNo, statusCode, statusDetail, version}` |
| `verify_otp.php` | POST | `Otp`, `referenceNo` | `{statusCode, statusDetail, subscriptionStatus, subscriberId, version}` |
| `unsubscribe.php` | POST | `user_mobile` | `{success, statusCode, statusDetail, subscriptionStatus, subscriberId}` |
| `subscription_listener.php` | POST | BDApps callback body | — (BDApps→server notification receiver) |

Observed behaviours that constrain this specification:

| ID | Observation | Consequence |
|---|---|---|
| O-01 | All four scripts normalise `01XXXXXXXXX`, `8801XXXXXXXXX`, `88 01XXXXXXXXX` to `01XXXXXXXXX`, then validate against `/^01[3-9][0-9]{8}$/`. | The client need not normalise, but SHOULD validate to give fast local feedback (FR-S-02). |
| O-02 | `check_subscription.php` returns a precomputed boolean `isSubscribed` (`subscriptionStatus === 'REGISTERED'`). | The client consumes `isSubscribed`; it does not interpret raw BDApps status codes. |
| O-03 | `verify_otp.php` returns BDApps' response verbatim without deciding success. | Success determination (`statusCode === 'S1000'`) happens in the `/v1` layer, not the client (FR-BE-05). |
| O-04 | `send_otp.php` sends hardcoded `applicationMetaData` (`device: 'Samsung S10'`, `os: 'android 8'`, a third-party `appCode`). | Accepted as-is. The Flutter client cannot and need not influence this. Recorded as AL-01. |
| O-05 | `subscription_listener.php` appends callback events to a text file; it updates no database. | Renewal and involuntary-unsubscribe events are **not** persisted by the frozen tier. The `/v1` tier must therefore treat BDApps as the authority and revalidate on a TTL rather than rely on push callbacks (FR-S-14). |
| O-06 | Scripts are session-based (`session_start()`) and CORS-open (`Access-Control-Allow-Origin: *`). | Sessions are irrelevant to a mobile client; the `/v1` tier calls them server-to-server and ignores cookies. |

### 2.3 Baseline gaps

| ID | Gap |
|---|---|
| GB-01 | No server tier exists for this application. |
| GB-02 | No user identity exists. Amal streaks, tasbeeh counts, and bookmarks are device-bound and lost on device change. |
| GB-03 | No entitlement concept exists. `FEATURES.md` defines free and premium tiers, but every feature is currently unconditionally available. |
| GB-04 | Content is bundled-only. Adding a hadith or surah requires shipping an APK. |
| GB-05 | No crash reporting or analytics. Field failures on low-end Android devices are invisible. |
| GB-06 | No push transport. `FEATURES.md` promises daily hadith notifications as a premium feature. |

---

## 3. Overall Description

### 3.1 Product perspective

The application becomes a **thin-server** product: a device-local app that consults a server for exactly three things it cannot determine alone — *who the user is*, *what they are entitled to*, and *what content is current*. Everything else continues to be computed or stored on-device.

```
┌──────────────────────── Flutter client (offline-first) ─────────────────────┐
│  Device-local (no network, ever):                                           │
│    Prayer times (adhan) · Qibla · Tasbeeh · Amal tracker · Hijri calendar   │
│    Bundled content (hadiths, surahs, names of Allah)                        │
│                                                                             │
│  Server-dependent (degrades gracefully):                                    │
│    Identity (M-2) · Entitlement (M-3) · Content updates (M-5)               │
└─────────────────────────────────────────────────────────────────────────────┘
              │ dio, HTTPS, JSON                    │ Firebase SDK
              ▼                                     ▼
┌──────────── Own server (cPanel/VPS) ──────┐  ┌─── Firebase (free tier) ────┐
│  /v1/*   versioned public API             │  │  FCM · Crashlytics ·        │
│  MySQL   users, entitlements, devices     │  │  Analytics · Remote Config  │
│  Static  content manifest + JSON + CDN    │  └─────────────────────────────┘
│                                           │
│  ── frozen, not modified by this project ─┤
│  /bdapps/*.php  → developer.bdapps.com    │
└───────────────────────────────────────────┘
```

### 3.2 Architectural decision

**Decision:** Own server (cPanel PHP + MySQL) for identity, entitlement, and content; Firebase free tier for push, crash reporting, analytics, and remote configuration. Firestore is **not** used as a primary data store.

**Rationale:**

| Factor | Finding |
|---|---|
| BDApps callbacks | Require a stable public HTTPS endpoint. The Firebase equivalent (Cloud Functions) requires the Blaze plan and an international payment card — a material obstacle. cPanel serves this for a fixed annual fee. |
| Data shape | Content is static, read-mostly, and identical for all users — a CDN problem, not a document-database problem. Firestore would charge per read, in perpetuity, for data that never changes. |
| Cost predictability | Revenue is 5 BDT/week/subscriber. A fixed hosting cost is compatible with that; an unbounded usage-metered bill is not. |
| Existing competence | The production BDApps integration is already PHP. Reusing that stack removes an entire class of integration risk. |
| Push / crash / analytics | Firebase is free, unmetered at this scale, and has no self-hosted equivalent worth building. Adopted without reservation. |

**Consequence:** the migration path is preserved. Because the client speaks only to `/v1/*` (C-BE-03), moving from shared cPanel to a VPS is a DNS change, and replacing the backend entirely is an implementation swap behind unchanged repository interfaces.

### 3.3 User classes

| Class | Description | Relevant needs |
|---|---|---|
| Anonymous skipper | Dismisses the subscription gate; may or may not create an account | Must reach Home and use every free feature with minimum friction |
| Free registered user | Has an account, no subscription | Cross-device continuity of their own progress; a discoverable path to subscribe |
| Premium subscriber | Registered and BDApps-subscribed | Uninterrupted premium access, including offline and when BDApps is unreachable |
| Lapsed subscriber | Was subscribed; carrier balance failed or they unsubscribed | Graceful, non-punitive downgrade to free with a clear explanation |
| Low-connectivity user | Rural, intermittent data, low-end Android | Never blocked by a network call for a feature that does not need the network |

### 3.4 Design and implementation constraints

| ID | Constraint |
|---|---|
| C-BE-01 | **The `/amol365/bdapps/` PHP scripts are a frozen contract.** This project SHALL NOT modify, refactor, or "fix" them. The `/v1` tier invokes them unmodified, server-to-server. Any defect found in them is recorded as an accepted limitation (§13), not a work item. |
| C-BE-02 | The Amol365 web application SHALL continue to function unchanged throughout. Both clients share the frozen scripts concurrently. |
| C-BE-03 | The Flutter client SHALL call only `/v1/*` endpoints. It SHALL NOT call `developer.bdapps.com` directly, and SHALL NOT call `/bdapps/*.php` directly. |
| C-BE-04 | BDApps credentials (`app_id`, `password`) SHALL NOT be present in the Flutter binary, in any form, at any time. |
| C-BE-05 | No feature that functions offline today SHALL acquire a network dependency. This is the governing constraint of this document. |
| C-BE-06 | Feature-first clean architecture (`data/`, `domain/`, `presentation/`) SHALL be preserved for all new modules. |
| C-BE-07 | All user-facing strings SHALL be in Bangla, including every error message originating from the server. |
| C-BE-08 | The subscription module SHALL be removable by deleting one directory and substituting one class (M-7). No other module may import from it. |
| C-BE-09 | All network traffic SHALL be HTTPS. Plaintext HTTP SHALL be refused by the client. |
| C-BE-10 | The app SHALL remain installable and usable on Android 6.0 (API 23). |

### 3.5 Assumptions and dependencies

- BDApps `developer.bdapps.com` availability is outside this project's control; the client must degrade gracefully when it is unreachable (EC-09).
- The hosting account supports PHP 7.4+, MySQL 5.7+, outbound cURL, and Let's Encrypt TLS.
- `subscriberId` (the phone number) is a stable identifier for a subscription. Number recycling by the carrier is not handled (AL-04).
- Firebase project setup (google-services.json / GoogleService-Info.plist) is a prerequisite of M-6 and M-5's Remote Config usage.

---

## 4. Module Map

| ID | Module | Depends on | Shippable independently | Removable |
|---|---|---|---|---|
| M-1 | Backend Platform & `/v1` API | — | Yes (server-only) | No |
| M-2 | Identity & Authentication | M-1 | Yes | No |
| M-3 | Subscription & Entitlement | M-1 | Yes | **Yes** (M-7) |
| M-4 | Startup Gate & Navigation | M-2, M-3 | No | No |
| M-5 | Content Sync | M-1 | Yes | Yes |
| M-6 | Push & Telemetry | — (Firebase) | Yes | Yes |
| M-7 | BDApps Decommissioning | M-3 | Yes | — |

**Dependency rule.** M-4 is the only module permitted to know about both M-2 and M-3. M-2 SHALL NOT import from M-3, and M-3 SHALL NOT import from M-2. Feature modules (prayer time, tasbeeh, …) SHALL depend only on the entitlement interface exposed by M-3's domain layer, never on M-3's data layer.

---

## 5. Module M-1 — Backend Platform & `/v1` API

### 5.1 Overview

A versioned JSON API on the existing hosting account, serving as the sole server-side surface the mobile client is aware of. It wraps the frozen BDApps scripts, owns the user database, and serves the content manifest.

### 5.2 Functional Requirements

**FR-BE-01 — Versioned namespace**
All mobile-facing endpoints SHALL live under `/v1/`. The version segment SHALL change only on a breaking contract change. Released APKs pin to a version and SHALL continue to function after `/v2/` is introduced.

**FR-BE-02 — Uniform envelope**
Every response SHALL use:
```json
{ "ok": true,  "data": { … } }
{ "ok": false, "error": { "code": "OTP_INVALID", "message": "ওটিপি সঠিক নয়" } }
```
`error.code` SHALL be a stable machine-readable constant. `error.message` SHALL be Bangla and directly presentable to the user (C-BE-07).

**FR-BE-03 — Endpoint surface**

| Endpoint | Auth | Purpose | Module |
|---|---|---|---|
| `POST /v1/auth/register` | — | Create account | M-2 |
| `POST /v1/auth/login` | — | Obtain tokens | M-2 |
| `POST /v1/auth/refresh` | Refresh token | Rotate access token | M-2 |
| `POST /v1/auth/logout` | Access token | Revoke refresh token | M-2 |
| `POST /v1/auth/forgot-password` | — | Send reset email | M-2 |
| `POST /v1/auth/reset-password` | Reset token | Set new password | M-2 |
| `GET  /v1/auth/me` | Access token | Current user + entitlement | M-2 |
| `POST /v1/subscription/status` | Optional | Check subscription for a number | M-3 |
| `POST /v1/subscription/otp/request` | Optional | Begin OTP subscribe | M-3 |
| `POST /v1/subscription/otp/verify` | Optional | Complete OTP subscribe | M-3 |
| `POST /v1/subscription/cancel` | Access token | Unsubscribe | M-3 |
| `POST /v1/bdapps/notify` | BDApps | Receive carrier callbacks | M-3 |
| `GET  /v1/content/manifest` | — | Content version manifest | M-5 |
| `POST /v1/device/register` | Access token | Register FCM token | M-6 |

**FR-BE-04 — Invocation of frozen scripts**
`/v1/subscription/*` SHALL fulfil requests by invoking the corresponding `/bdapps/*.php` script over local HTTP or by direct `include`, with the request body those scripts already expect (§2.2). The scripts SHALL NOT be modified (C-BE-01). Where a frozen script's response is insufficient, the `/v1` layer SHALL enrich it — never patch the script.

**FR-BE-05 — Translation of BDApps semantics**
The `/v1` layer SHALL translate carrier vocabulary into product vocabulary. The client SHALL never receive `statusCode`, `S1000`, `REGISTERED`, `referenceNo`, or `subscriberId`.

| Frozen response | `/v1` translation |
|---|---|
| `isSubscribed: true` | `entitlement: "premium"` |
| `subscriptionStatus: "REGISTERED"` | `entitlement: "premium"` |
| `verify_otp` → `statusCode: "S1000"` | `ok: true`, `entitlement: "premium"` |
| `verify_otp` → any other `statusCode` | `ok: false`, `error.code: "OTP_INVALID"` |
| `send_otp` → `success: true, referenceNo` | `ok: true`, `txnId` (opaque, server-mapped) |
| cURL failure / timeout / HTML response | `ok: false`, `error.code: "CARRIER_UNAVAILABLE"` |

**FR-BE-06 — `referenceNo` confinement**
The BDApps `referenceNo` SHALL NOT be transmitted to the client. The `/v1` layer SHALL issue an opaque `txnId`, store the `txnId → referenceNo` mapping server-side with a 10-minute expiry, and resolve it on verify.

**FR-BE-07 — Rate limiting**
`/v1/subscription/otp/request` SHALL be limited to 3 requests per phone number per 15 minutes and 20 per IP per hour. `/v1/auth/login` SHALL be limited to 10 attempts per email per 15 minutes. Exceeding a limit SHALL return `RATE_LIMITED` with a Bangla message stating when to retry. *(This limiting lives in the `/v1` tier; it does not modify the frozen scripts.)*

**FR-BE-08 — Request identification**
Every request SHALL carry `X-App-Version`, `X-Platform` (`android` | `ios`), and `X-Device-Id` (an app-generated UUID, `uuid` package). These SHALL be logged for support and abuse triage.

**FR-BE-09 — Minimum supported version**
Every response SHALL include `minSupportedVersion`. A client below it SHALL present a blocking Bangla update prompt. This is the escape hatch for a breaking change that cannot be versioned away.

**FR-BE-10 — Server-side logging hygiene**
Logs written by the `/v1` tier SHALL be stored outside the web root and SHALL NOT record passwords, password hashes, OTP values, `referenceNo` values, or BDApps credentials. *(Applies to new code only; the frozen tier's logging is out of scope per C-BE-01 and recorded as AL-02.)*

**FR-BE-11 — Timeouts**
Outbound calls to the frozen scripts SHALL time out at 20 seconds. The client's own timeout SHALL be 30 seconds, so the server always fails first and returns a typed error rather than the client guessing.

### 5.3 Data Requirements — MySQL schema

```
users
  id              BIGINT PK AUTO_INCREMENT
  email           VARCHAR(190) UNIQUE NOT NULL
  password_hash   VARCHAR(255) NOT NULL          -- password_hash(), bcrypt
  display_name    VARCHAR(100) NULL
  email_verified  TINYINT(1) DEFAULT 0
  created_at      DATETIME
  updated_at      DATETIME
  last_login_at   DATETIME NULL
  status          ENUM('active','suspended','deleted') DEFAULT 'active'

entitlements
  id              BIGINT PK
  user_id         BIGINT NULL FK → users.id     -- NULL: subscribed before registering
  msisdn          VARCHAR(15) NOT NULL           -- normalised 01XXXXXXXXX
  tier            ENUM('free','premium') DEFAULT 'free'
  source          VARCHAR(20) DEFAULT 'bdapps'   -- future: 'iap', 'promo'
  status          VARCHAR(20)                    -- mirrors last known carrier state
  last_checked_at DATETIME
  expires_at      DATETIME NULL
  UNIQUE KEY (msisdn, source)
  INDEX (user_id)

otp_transactions
  txn_id          CHAR(36) PK                    -- opaque, given to client
  msisdn          VARCHAR(15) NOT NULL
  reference_no    VARCHAR(191) NOT NULL          -- never leaves the server
  created_at      DATETIME
  expires_at      DATETIME                       -- created_at + 10 min
  consumed_at     DATETIME NULL
  INDEX (msisdn, created_at)

refresh_tokens
  id              BIGINT PK
  user_id         BIGINT FK → users.id
  token_hash      CHAR(64) UNIQUE                -- SHA-256; raw token never stored
  device_id       VARCHAR(64)
  issued_at       DATETIME
  expires_at      DATETIME
  revoked_at      DATETIME NULL

password_resets
  token_hash      CHAR(64) PK
  user_id         BIGINT FK → users.id
  expires_at      DATETIME                       -- issued_at + 1 hour
  consumed_at     DATETIME NULL

devices
  id              BIGINT PK
  user_id         BIGINT NULL FK → users.id
  device_id       VARCHAR(64) UNIQUE
  fcm_token       VARCHAR(255) NULL
  platform        VARCHAR(10)
  app_version     VARCHAR(20)
  updated_at      DATETIME

bdapps_events                                    -- what the frozen listener does not persist
  id              BIGINT PK
  msisdn          VARCHAR(15)
  status          VARCHAR(30)
  frequency       VARCHAR(30) NULL
  raw_payload     TEXT
  received_at     DATETIME
  INDEX (msisdn, received_at)
```

**Rationale for `entitlements.user_id` being nullable:** the subscription gate precedes login (§8). A user may subscribe by phone number before an account exists. The row is created with `user_id = NULL` and reconciled at first login from the same device (FR-S-12).

### 5.4 Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-BE-01 | Availability | Server unavailability SHALL NOT prevent access to any offline-capable feature (C-BE-05). |
| NFR-BE-02 | Latency | `/v1/auth/*` and `/v1/content/manifest` SHALL respond within 800 ms p95, excluding carrier round-trips. |
| NFR-BE-03 | Latency | `/v1/subscription/*` SHALL respond within 20 s worst case (FR-BE-11), bounded by the carrier. |
| NFR-BE-04 | Capacity | The design SHALL support 20,000 daily active users on shared hosting, given that entitlement is checked at most once per device per 24 h (FR-S-14) and content is served as static files (M-5). |
| NFR-BE-05 | Security | Passwords SHALL be hashed with bcrypt (cost ≥ 10) via `password_hash()`. Plaintext or reversible storage is prohibited. |
| NFR-BE-06 | Security | TLS 1.2+ on all endpoints. HTTP SHALL redirect to HTTPS server-side and be refused client-side (C-BE-09). |
| NFR-BE-07 | Privacy | Phone numbers SHALL be stored only in `entitlements`, `otp_transactions`, and `bdapps_events`, and SHALL NOT be exposed by any read endpoint except masked (`01XXXXX1234`). |
| NFR-BE-08 | Portability | No endpoint SHALL depend on cPanel-specific behaviour. The tier SHALL be relocatable to a VPS without client changes. |

### 5.5 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-BE-01 | Every endpoint in FR-BE-03 returns the FR-BE-02 envelope for both success and failure. |
| AC-BE-02 | `git status` in the Amol365 repository shows no modification to `bdapps/` after this module ships (C-BE-01). |
| AC-BE-03 | The Amol365 web subscribe and login flows continue to work end-to-end (C-BE-02). |
| AC-BE-04 | Static analysis of the release APK finds no BDApps `app_id` or `password` (C-BE-04). |
| AC-BE-05 | No `/v1` response body anywhere contains `referenceNo`, `subscriberId`, or `statusCode` (FR-BE-05, FR-BE-06). |
| AC-BE-06 | A 4th OTP request for one number inside 15 minutes returns `RATE_LIMITED` (FR-BE-07). |
| AC-BE-07 | With `developer.bdapps.com` unreachable, `/v1/subscription/status` returns `CARRIER_UNAVAILABLE` within 20 s — it does not hang or return HTML. |
| AC-BE-08 | An expired `txnId` cannot be used to verify an OTP. |

---

## 6. Module M-2 — Identity & Authentication

### 6.1 Overview

Email/password accounts, giving the user a portable identity so progress survives a device change (GB-02), and giving the product a stable key for future server-side features.

### 6.2 User stories

| ID | Story |
|---|---|
| US-A-01 | As a new user, I want to create an account with my email and a password so my data is not tied to this phone. |
| US-A-02 | As a returning user, I want to stay logged in so I am not asked for credentials every day. |
| US-A-03 | As a user who forgot my password, I want to reset it by email. |
| US-A-04 | As an offline user, I want to open the app and reach Home without a network connection. |
| US-A-05 | As a privacy-conscious user, I want to log out and have my session invalidated. |

### 6.3 Functional Requirements

**FR-A-01 — Registration**
The system SHALL allow account creation with email, password, and optional display name. Email SHALL be validated by format and stored lowercased. Duplicate registration SHALL return `EMAIL_TAKEN` with a Bangla message.

**FR-A-02 — Password policy**
Passwords SHALL be a minimum of 8 characters. No composition rules (mandatory symbols, mixed case) SHALL be imposed — they measurably reduce security by encouraging reuse, and this audience is largely mobile-keyboard-only. Maximum length 128.

**FR-A-03 — Login**
Email + password SHALL return an access token (JWT, 1-hour TTL) and a refresh token (opaque, 90-day TTL). Failure SHALL return `INVALID_CREDENTIALS` — **identical** for unknown email and wrong password, to prevent account enumeration.

**FR-A-04 — Token storage**
Both tokens SHALL be stored in `flutter_secure_storage` (Keystore / Keychain). They SHALL NOT be written to `SharedPreferences`, logs, or crash reports.

**FR-A-05 — Session persistence**
A returning user with a valid refresh token SHALL reach Home without re-entering credentials (US-A-02). The access token SHALL be refreshed transparently on 401 via a `dio` interceptor, with the original request retried once.

**FR-A-06 — Offline session tolerance**
If a stored session exists but the network is unavailable or refresh fails for a network reason, the app SHALL grant access to Home using the cached session (C-BE-05, US-A-04). Only an explicit server rejection (`401 TOKEN_REVOKED`) SHALL force re-login. **A user who has logged in once SHALL never be locked out of offline features by a lack of connectivity.**

**FR-A-07 — Refresh token rotation**
Each refresh SHALL issue a new refresh token and revoke its predecessor. Reuse of a revoked token SHALL revoke the entire chain for that device and require re-login.

**FR-A-08 — Logout**
Logout SHALL revoke the refresh token server-side and clear secure storage. Device-local data (streaks, tasbeeh counts, settings) SHALL be **preserved**, not wiped — it is not owned by the account in this release.

**FR-A-09 — Password reset**
`forgot-password` SHALL send a single-use, 1-hour token by email. The response SHALL be identical whether or not the email exists (anti-enumeration). Consuming the token SHALL revoke all refresh tokens for that user.

**FR-A-10 — Email verification**
Email verification SHALL be recorded (`users.email_verified`) but SHALL NOT gate access in this release. Deliverability from shared hosting is unreliable; blocking on it would strand users.

**FR-A-11 — Bangla error surface**
Every authentication failure SHALL surface a specific Bangla message. Generic exception text, HTTP status codes, and English server strings SHALL NOT reach the UI.

**FR-A-12 — Account deletion**
Settings SHALL expose account deletion. It SHALL soft-delete (`status = 'deleted'`), revoke all tokens, and be confirmed by a Bangla dialog. *(Required by both Google Play and Apple App Store policy.)*

**FR-A-13 — Module structure**
```
lib/features/auth/
  data/         auth_api.dart, auth_repository_impl.dart, token_store.dart
  domain/       auth_repository.dart, app_user.dart, auth_failure.dart
  presentation/ login_screen.dart, register_screen.dart,
                forgot_password_screen.dart, auth_viewmodel.dart
```

### 6.4 Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-A-01 | Cold start with a valid cached session SHALL reach Home within 2 s on a 2 GB-RAM Android 8 device, without waiting on any network call. |
| NFR-A-02 | Token refresh SHALL be invisible: no spinner, no logout, no interruption of the current screen. |
| NFR-A-03 | Concurrent 401s SHALL trigger exactly one refresh; other requests queue behind it. |
| NFR-A-04 | All auth screens SHALL be usable at 200% system font scale without clipping. |

### 6.5 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-A-01 | Registering, killing the app, and relaunching lands on Home with no credential prompt. |
| AC-A-02 | Wrong password and unregistered email produce byte-identical error responses. |
| AC-A-03 | With airplane mode on and a prior session, launch reaches Home; prayer times and qibla work. |
| AC-A-04 | An expired access token is refreshed transparently; the user observes no interruption. |
| AC-A-05 | A revoked refresh token forces re-login exactly once and does not loop. |
| AC-A-06 | Password reset email arrives, the link works once, and reuse is rejected. |
| AC-A-07 | After logout, secure storage contains no tokens, and the amal streak is still intact. |
| AC-A-08 | No token appears in logcat at any log level, or in any Crashlytics report. |

---

## 7. Module M-3 — Subscription & Entitlement

### 7.1 Overview

BDApps carrier-billed subscription, and the entitlement abstraction that isolates the rest of the app from it. **This module is designed to be deleted** (C-BE-08, M-7).

### 7.2 User stories

| ID | Story |
|---|---|
| US-S-01 | As a user, I want to enter my mobile number and be told immediately whether I am already subscribed. |
| US-S-02 | As an unsubscribed user, I want to subscribe by receiving and entering an OTP. |
| US-S-03 | As a user who does not want to subscribe, I want to dismiss the screen and use the free app. |
| US-S-04 | As a user who skipped, I want to find the subscribe option later without reinstalling. |
| US-S-05 | As a subscriber, I want premium features to work offline and when the carrier is unreachable. |
| US-S-06 | As a subscriber, I want to unsubscribe from within the app. |

### 7.3 Functional Requirements — Entitlement abstraction

**FR-S-01 — Entitlement is the only public concept**
The rest of the application SHALL consume a single provider exposing:
```dart
enum Tier { free, premium }
class Entitlement { Tier tier; DateTime? checkedAt; bool isStale; }
```
No feature module SHALL reference BDApps, MSISDN, OTP, or carrier state (C-BE-08).

### 7.4 Functional Requirements — Subscription flow

**FR-S-02 — Phone number entry**
The subscription screen SHALL accept a Bangladeshi mobile number, validating `^01[3-9][0-9]{8}$` locally for immediate feedback before any network call (O-01). The keyboard SHALL be numeric. Input SHALL be formatted for readability but transmitted unformatted.

**FR-S-03 — Status check**
On submit, the app SHALL call `/v1/subscription/status`. If `entitlement == premium`, the flow completes immediately with a success state — **no OTP is requested** (US-S-01).

**FR-S-04 — OTP request**
If not subscribed, the app SHALL call `/v1/subscription/otp/request`, store the returned `txnId` in memory only, and advance to OTP entry.

**FR-S-05 — OTP entry**
A 4–6 digit numeric field with a visible countdown until resend is permitted (60 s), and a resend action thereafter, bounded by FR-BE-07.

**FR-S-06 — OTP verification**
Verification SHALL call `/v1/subscription/otp/verify` with `txnId` and the entered code. Success SHALL persist entitlement (FR-S-13) and complete the flow. Failure SHALL show a specific Bangla message and permit retry without restarting from the number screen.

**FR-S-07 — OTP expiry**
A `txnId` older than 10 minutes SHALL return `OTP_EXPIRED`; the UI SHALL offer to resend rather than dead-ending.

**FR-S-08 — Dismissal (soft gate)**
The screen SHALL display a **cross (✕) in the top-right**. Activating it SHALL dismiss the screen and continue the startup sequence (§8). No penalty, no confirmation dialog, no re-prompt within the same session. The Android system back gesture SHALL behave identically to the cross.

**FR-S-09 — Re-prompt policy**
The gate SHALL be shown automatically on **at most the first three launches**. A counter (`StorageKeys.subGatePromptCount`) SHALL increment on each automatic display. At 3, automatic display SHALL cease permanently. Successful subscription SHALL also stop it. *(Rationale: a daily-use prayer app that nags on every launch is uninstalled.)*

**FR-S-10 — Re-entry points**
Because FR-S-09 permanently silences the gate, the flow SHALL remain reachable from:
1. A প্রিমিয়াম row in Settings, always visible to free users.
2. Any locked premium feature (FR-S-16).
Absent these, a user who dismisses once could never subscribe, and the revenue model would fail.

**FR-S-11 — Unsubscribe**
Settings SHALL offer unsubscribe for premium users, calling `/v1/subscription/cancel` behind a Bangla confirmation dialog. On success, entitlement SHALL drop to `free` immediately and the cache SHALL be invalidated.

**FR-S-12 — Account reconciliation**
Because the gate precedes login (§8), a subscription may be created before an account exists. On first successful login from a device that completed subscription, the client SHALL send its `X-Device-Id`, and the server SHALL bind the orphaned `entitlements` row (`user_id IS NULL`) to that `user_id`. Binding SHALL be idempotent.

### 7.5 Functional Requirements — Entitlement caching

**FR-S-13 — Cache**
Entitlement SHALL be cached in `flutter_secure_storage` as `{tier, msisdn, checkedAt}`. `SharedPreferences` SHALL NOT be used — it is trivially editable on a rooted device.

**FR-S-14 — TTL and revalidation**
Cached entitlement SHALL be honoured for **24 hours**. Revalidation SHALL be attempted on the first launch after expiry, in the background, without blocking the UI. The 24-hour figure follows from O-05: the frozen listener does not persist carrier callbacks, so the carrier must be polled rather than trusted to push.

**FR-S-15 — Grace period**
If revalidation fails for a **network or carrier reason** (`CARRIER_UNAVAILABLE`, timeout, offline), cached premium SHALL be honoured for a further **7 days**, flagged `isStale`. Only an authoritative `free` response from the server SHALL downgrade a user. *(A subscriber who paid must not lose access because a shared host was briefly down, or because they are in a village with no signal — US-S-05.)*

**FR-S-16 — Premium gating**
Features designated premium in `FEATURES.md` SHALL check entitlement before granting access. A locked feature SHALL remain **visible** with a lock affordance and, on activation, open the subscription flow (FR-S-10). Locked features SHALL NOT be hidden — invisible value cannot be sold.

**FR-S-17 — Server-side authority**
The client's cached entitlement SHALL be treated as a UX optimisation only. Any future server-delivered premium content SHALL re-verify entitlement server-side. The client SHALL NOT be the authority on what it may receive.

**FR-S-18 — Module structure**
```
lib/features/subscription/          ← M-7 deletes this entire directory
  data/         subscription_api.dart, bdapps_subscription_repository.dart,
                entitlement_cache.dart
  domain/       subscription_repository.dart   (interface)
                entitlement.dart               (Tier, Entitlement)
                subscription_failure.dart
  presentation/ phone_entry_screen.dart, otp_screen.dart,
                subscription_viewmodel.dart, premium_lock_widget.dart
```

### 7.6 Premium scope

Per `FEATURES.md`. Restated here as the authoritative gating list:

| Feature | Free | Premium |
|---|---|---|
| Prayer times, Qibla, Islamic calendar | ✅ | ✅ |
| Tasbeeh counter | ✅ basic | ✅ full |
| Amal tracker | ✅ 5 items | ✅ 9 items + Tahajjud |
| Hadith of the day | ✅ in-app | ✅ + daily push |
| Surah collection | ✅ 8 popular | ✅ all 114 |
| 99 Names of Allah | ✅ partial | ✅ full + benefits |
| Ramadan special mode | — | ✅ |
| Audio recitation | — | ✅ (deferred, §12.3) |
| Ads | shown | removed |

### 7.7 Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-S-01 | The gate SHALL be dismissible within one interaction at all times, including while a network call is in flight. |
| NFR-S-02 | No screen SHALL block on a carrier call for longer than 20 s (FR-BE-11); a Bangla timeout message with retry SHALL follow. |
| NFR-S-03 | The phone number SHALL be displayed masked (`01XXXXX1234`) everywhere except the entry field itself. |
| NFR-S-04 | Entitlement evaluation SHALL be synchronous from cache — feature gating SHALL never await the network. |
| NFR-S-05 | The module SHALL be deletable per M-7 with no compilation error outside its own directory, verified by test. |

### 7.8 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-S-01 | An already-subscribed number completes at the status check with no OTP sent. |
| AC-S-02 | An unsubscribed number receives an SMS OTP; correct entry yields premium. |
| AC-S-03 | Incorrect OTP shows a Bangla error and allows retry without re-entering the number. |
| AC-S-04 | The ✕ dismisses the gate in one tap and proceeds to Login. |
| AC-S-05 | The gate appears on launches 1–3 and never automatically thereafter (FR-S-09). |
| AC-S-06 | After permanent dismissal, Settings → প্রিমিয়াম still opens the flow. |
| AC-S-07 | Tapping a locked premium feature opens the subscription flow. |
| AC-S-08 | A premium user in airplane mode retains premium access. |
| AC-S-09 | With the server unreachable for 3 days, a premium user retains access (grace period, FR-S-15). |
| AC-S-10 | An authoritative `free` response downgrades the user within one launch. |
| AC-S-11 | Unsubscribing revokes premium immediately and locked features re-lock. |
| AC-S-12 | Subscribing before registering, then registering, binds the entitlement to the new account (FR-S-12). |
| AC-S-13 | Deleting `lib/features/subscription/` and substituting the stub repository yields a clean `flutter analyze` (NFR-S-05). |

### 7.9 Edge cases

| ID | Case | Required behaviour |
|---|---|---|
| EC-09 | BDApps unreachable during status check | `CARRIER_UNAVAILABLE`; gate remains dismissible; user reaches Home as free |
| EC-10 | OTP SMS never arrives | Resend after 60 s, bounded by FR-BE-07; a "did not receive" help affordance |
| EC-11 | App killed between OTP request and entry | `txnId` is memory-only; user restarts from the number screen. Accepted. |
| EC-12 | User enters a number belonging to someone else | BDApps sends the OTP to that number's SIM; possession of the OTP is the proof. Accepted platform behaviour. |
| EC-13 | Number is not on Robi/Airtel | Carrier rejects; Bangla message naming the supported operators |
| EC-14 | Carrier balance insufficient at renewal | Carrier stops the subscription; detected on next revalidation; graceful downgrade with Bangla explanation |
| EC-15 | Two accounts claim the same MSISDN | `UNIQUE (msisdn, source)`; the most recent successful subscribe wins and the prior binding is released |
| EC-16 | Device clock set far forward | TTL logic SHALL use server `checkedAt`, not device time, for expiry comparison where available |
| EC-17 | Subscribed, then logs out, then logs in as a different user | Entitlement is bound to the account, not the device; the second user SHALL NOT inherit premium |
| EC-18 | Reinstall after subscribing | Cache is gone; re-entering the number restores premium via status check without paying again |

---

## 8. Module M-4 — Startup Gate & Navigation

### 8.1 Overview

The startup sequence, which sits above and sequences M-2 and M-3.

### 8.2 Required sequence

```
Splash
  └─► Onboarding            (first launch only — existing feature)
        └─► Subscription gate    (SOFT — ✕ dismisses; ≤3 automatic shows)
              ├─ subscribed ──┐
              └─ dismissed  ──┤
                              ▼
                          Login / Register     (email + password)
                              │
                              ▼
                            Home
```

### 8.3 Functional Requirements

**FR-G-01 — Order**
The subscription gate SHALL precede authentication. Both SHALL precede Home.

**FR-G-02 — Gate is soft**
Subscription is optional in every path (FR-S-08).

**FR-G-03 — Authentication requirement**
Login SHALL be required to reach Home on first use. Thereafter a persisted session SHALL satisfy it (FR-A-05), including offline (FR-A-06).

**FR-G-04 — Skip conditions**
- Onboarding SHALL be shown once (`StorageKeys.onboardingDone`, existing).
- The gate SHALL be skipped entirely when entitlement is already `premium`, or when the prompt count has reached 3 (FR-S-09).
- Login SHALL be skipped when a valid session exists.
- A returning premium user with a session SHALL therefore go Splash → Home.

**FR-G-05 — Redirect logic**
Sequencing SHALL be implemented in the `go_router` `redirect` callback against a single `startupStateProvider`, not by imperative navigation calls scattered across screens.

**FR-G-06 — Back-navigation**
System back on Login SHALL NOT return to the subscription gate, and back on Home SHALL NOT return to Login. Completed startup steps SHALL be removed from the stack.

**FR-G-07 — Deep links**
A deep link received while startup is incomplete SHALL be held and honoured after Home is reached, not dropped (`FEATURES.md` promises deep-linked push notifications).

**FR-G-08 — Cold-start budget**
Startup SHALL NOT block on any network call. Gate and login decisions SHALL be made from local state; server calls happen after Home renders (NFR-A-01, C-BE-05).

### 8.4 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-G-01 | First launch: Splash → Onboarding → Gate → Login → Home. |
| AC-G-02 | Second launch after dismissing and registering: Splash → Home. |
| AC-G-03 | Dismissing the gate leads to Login, not Home (FR-G-01). |
| AC-G-04 | Airplane mode on second launch: Splash → Home; no auth or carrier call blocks it. |
| AC-G-05 | Back from Login does not return to the gate. |
| AC-G-06 | A notification deep link tapped on a cold, logged-out start opens the target screen after login. |
| AC-G-07 | Cold start to Home is under 2 s on the reference low-end device. |

---

## 9. Module M-5 — Content Sync

### 9.1 Overview

Ships content updates without an APK release (GB-04). Directly relevant: `lib/assets/data/` is currently **empty**, and premium value (all 114 surahs, full 99 names, daily hadiths) is content, not code.

### 9.2 Functional Requirements

**FR-C-01 — Bundled baseline**
The app SHALL ship a complete v1 of every content file in `lib/assets/data/`. The app SHALL be fully functional with no network and no sync, forever.

**FR-C-02 — Manifest**
`GET /v1/content/manifest` SHALL return per-file `version`, `url`, `sha256`, and `bytes`.

**FR-C-03 — Differential download**
Only files whose manifest version exceeds the local version SHALL be downloaded.

**FR-C-04 — Integrity**
Every download SHALL be SHA-256 verified before being committed. A mismatch SHALL discard the file and retain the previous version.

**FR-C-05 — Atomic replacement**
Writes SHALL be atomic (temp file + rename). A kill mid-download SHALL never leave corrupt content.

**FR-C-06 — Resolution order**
Content SHALL resolve: downloaded → bundled. A failed sync is always invisible to the user.

**FR-C-07 — Schedule**
Sync SHALL be attempted at most once per 24 hours, only on an unmetered or available connection, and never during startup (FR-G-08).

**FR-C-08 — Entitlement-scoped content**
Premium-only content SHALL be delivered only to entitled users, enforced server-side (FR-S-17).

**FR-C-09 — Static delivery**
Content files SHALL be served as static files, CDN-cacheable, not generated per request (NFR-BE-04).

### 9.3 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-C-01 | A fresh install with no network shows full bundled content. |
| AC-C-02 | Publishing a new `hadiths` version updates the app within one sync cycle. |
| AC-C-03 | A corrupted download is rejected and the previous version is retained. |
| AC-C-04 | Killing the app mid-download leaves content readable and uncorrupted. |
| AC-C-05 | A free user cannot retrieve premium-only content by direct URL. |

---

## 10. Module M-6 — Push & Telemetry

### 10.1 Functional Requirements

**FR-P-01 — FCM**
Firebase Cloud Messaging SHALL be the push transport. Tokens SHALL be registered via `/v1/device/register` and refreshed on rotation.

**FR-P-02 — Daily hadith**
Premium users with the setting enabled SHALL receive one daily hadith push, deep-linking to the hadith screen (`FEATURES.md`).

**FR-P-03 — Notification permission**
Android 13+ `POST_NOTIFICATIONS` SHALL be requested when the user first enables a push feature — never at startup. *(Consistent with `docs/SRS.md` FR-N-25.)*

**FR-P-04 — Local notifications unaffected**
Azan notifications remain **local** (`flutter_local_notifications`, `docs/SRS.md` FR-N-22) and SHALL NOT be routed through FCM. Prayer alerts must never depend on connectivity.

**FR-P-05 — Crash reporting**
Firebase Crashlytics SHALL be integrated, with tokens, passwords, OTPs, and phone numbers excluded from all reports (FR-A-04, NFR-BE-07).

**FR-P-06 — Analytics**
Firebase Analytics SHALL record the conversion funnel: gate shown → number entered → OTP sent → subscribed, plus dismissal at each step. Location data SHALL NOT be collected (`docs/SRS.md` NFR-09).

**FR-P-07 — Remote Config**
Firebase Remote Config SHALL carry feature flags and kill switches, including one to disable the subscription gate entirely without an app release.

### 10.2 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-P-01 | A daily hadith push arrives for an entitled, opted-in user and deep-links correctly. |
| AC-P-02 | A free user receives no premium push. |
| AC-P-03 | Azan notifications fire in airplane mode (FR-P-04). |
| AC-P-04 | A forced test crash appears in Crashlytics with no credential or phone number in the payload. |
| AC-P-05 | The Remote Config kill switch hides the gate on next launch without an app update. |

---

## 11. Module M-7 — BDApps Decommissioning

### 11.1 Overview

The stated requirement that BDApps be temporary and removable. This module is specified now and executed later; specifying it now is what keeps the rest of the design honest.

### 11.2 Functional Requirements

**FR-R-01 — Single deletion point**
Decommissioning SHALL consist of: delete `lib/features/subscription/`, and bind `subscriptionRepositoryProvider` to a replacement implementing the same interface (FR-S-01, FR-S-18).

**FR-R-02 — Import isolation**
No file outside `lib/features/subscription/` SHALL import from `lib/features/subscription/data/`. Only the domain layer is importable, and only for `Entitlement` / `Tier`. **This SHALL be enforced by an automated test that fails the build on violation** — a convention nobody checks is a convention that decays.

**FR-R-03 — Replacement strategies**
The interface SHALL accommodate, without changes to any consuming code:
- `AlwaysPremiumRepository` — BDApps withdrawn, everything free
- `IapSubscriptionRepository` — Play Billing / StoreKit
- `ServerEntitlementRepository` — entitlement from `/v1/auth/me` alone

**FR-R-04 — Data retention**
On decommissioning, `entitlements` rows SHALL be retained for reconciliation and refunds. `otp_transactions` SHALL be purged.

**FR-R-05 — Navigation collapse**
Removal SHALL collapse the startup sequence to Splash → Onboarding → Login → Home with no dead route and no orphaned redirect.

**FR-R-06 — Migration honesty**
If premium is withdrawn rather than replaced, existing subscribers SHALL be notified in Bangla before their next billing cycle, and unsubscribed server-side. Users SHALL NOT continue to be charged for a product that no longer bills them deliberately.

### 11.3 Acceptance criteria

| ID | Criterion |
|---|---|
| AC-R-01 | Deleting the directory and swapping the provider yields a clean `flutter analyze` and a green test suite. |
| AC-R-02 | The import-isolation test fails when a feature module imports the subscription data layer. |
| AC-R-03 | With `AlwaysPremiumRepository`, every premium feature is accessible and no lock UI renders. |
| AC-R-04 | Post-removal startup is Splash → Onboarding → Login → Home. |

---

## 12. Client Data Requirements

### 12.1 New `StorageKeys` (SharedPreferences — non-sensitive only)

| Key | Type | Default | Purpose |
|---|---|---|---|
| `subGatePromptCount` | int | `0` | Automatic gate displays so far (FR-S-09) |
| `subGateDismissedAt` | int (epoch ms) | — | Last dismissal |
| `deviceId` | String | generated | `X-Device-Id`, UUID v4 (FR-BE-08) |
| `contentVersions` | String (JSON map) | `{}` | Per-file content versions (FR-C-03) |
| `lastContentSyncAt` | int (epoch ms) | `0` | Sync schedule (FR-C-07) |
| `pushHadithEnabled` | bool | `false` | Daily hadith opt-in (FR-P-02) |
| `lastAuthEmail` | String | — | Prefill convenience only |

### 12.2 `flutter_secure_storage` (sensitive)

| Key | Purpose |
|---|---|
| `auth_access_token` | JWT, 1 h (FR-A-03) |
| `auth_refresh_token` | Opaque, 90 d (FR-A-03) |
| `entitlement_cache` | `{tier, msisdn, checkedAt}` (FR-S-13) |

**Prohibition:** entitlement and tokens SHALL NEVER be written to `SharedPreferences` (FR-S-13, FR-A-04).

### 12.3 Deferred

Audio recitation (`FEATURES.md` Phase 3) is **not** specified here. When specified, it SHALL be delivered from object storage with cheap egress (Cloudflare R2 / Backblaze B2), never from the cPanel account, whose bandwidth is metered.

---

## 13. Accepted Limitations

Consequences of C-BE-01 (frozen scripts) and of the platform. Recorded deliberately, not overlooked.

| ID | Limitation | Why accepted |
|---|---|---|
| AL-01 | `send_otp.php` transmits hardcoded device metadata (O-04). | Frozen contract. No functional impact on subscription success. |
| AL-02 | The frozen scripts write diagnostic files into their own web-served directory (O-05). | Frozen contract (C-BE-01). Out of scope for this project; new `/v1` code follows FR-BE-10 instead. |
| AL-03 | Carrier callbacks are not persisted by the frozen tier (O-05). | Mitigated by TTL revalidation (FR-S-14) rather than by modifying the frozen tier. |
| AL-04 | Carrier number recycling could transfer an entitlement to a new owner. | Rare; detected at the next revalidation; industry-standard exposure for carrier billing. |
| AL-05 | Email deliverability from shared hosting is unreliable, affecting password reset. | Mitigated by not gating on email verification (FR-A-10). Revisit with a transactional email provider if reset failures are reported. |
| AL-06 | OEM battery managers may delay FCM delivery. | Platform limitation, as already recorded in `docs/SRS.md` §3.5. |

---

## 14. Traceability

| Baseline gap | Closed by |
|---|---|
| GB-01 | M-1 (FR-BE-01 … FR-BE-11) |
| GB-02 | M-2 (FR-A-01, FR-A-03, FR-A-05) |
| GB-03 | M-3 (FR-S-01, FR-S-16) |
| GB-04 | M-5 (FR-C-02 … FR-C-06) |
| GB-05 | M-6 (FR-P-05, FR-P-06) |
| GB-06 | M-6 (FR-P-01, FR-P-02) |

| Stakeholder requirement | Satisfied by |
|---|---|
| Subscription screen first, then login | FR-G-01, §8.2 |
| Cross icon skips to the app | FR-S-08, AC-S-04 |
| Subscription is optional | FR-G-02, FR-S-08, FR-S-09 |
| Reuse existing BDApps endpoints unmodified | C-BE-01, FR-BE-04, AC-BE-02 |
| Email/password login | M-2, FR-A-01, FR-A-03 |
| BDApps removable later | M-7, C-BE-08, FR-R-01 |
| App must scale | NFR-BE-04, NFR-BE-08, FR-C-09 |

| Constraint | Enforced by |
|---|---|
| C-BE-01 | AC-BE-02, AC-BE-03 |
| C-BE-03 | AC-BE-04, AC-BE-05 |
| C-BE-04 | AC-BE-04 |
| C-BE-05 | AC-A-03, AC-G-04, AC-S-08, AC-P-03, AC-C-01 |
| C-BE-08 | AC-S-13, AC-R-01, AC-R-02 |

---

## 15. Release Plan

| Release | Modules | Content | Gate |
|---|---|---|---|
| 3.0 | M-1 | Server tier, `/v1` API, MySQL schema. **No client change.** | AC-BE-01 … AC-BE-08 |
| 3.1 | M-2 | Email/password auth; login inserted before Home | AC-A-01 … AC-A-08 |
| 3.2 | M-3, M-4 | Subscription gate, entitlement, premium gating, full startup sequence | AC-S-01 … AC-S-13, AC-G-01 … AC-G-07 |
| 3.3 | M-6 | FCM, Crashlytics, Analytics, Remote Config | AC-P-01 … AC-P-05 |
| 3.4 | M-5 | Content sync; populate `lib/assets/data/` | AC-C-01 … AC-C-05 |
| — | M-7 | Executed only on withdrawal of BDApps | AC-R-01 … AC-R-04 |

### 15.1 Sequencing rationale

**M-1 ships alone, first.** The server can be built, deployed, and load-tested with no released client depending on it. Bugs found here cost nothing; bugs found after an APK is in the field cost an app update.

**M-2 before M-3**, despite the gate appearing *before* login at runtime. Authentication is the smaller, better-understood, entirely-in-our-control surface; the subscription flow depends on a third-party carrier and is where the field failures will be. Establishing the network stack — `dio`, interceptors, error envelope, secure storage, Bangla error surface — against the simpler dependency means M-3 inherits proven infrastructure. Shipping order is not screen order.

**M-4 ships with M-3**, not separately: the full startup sequence cannot be validated until both gates exist.

**M-6 before M-5** because telemetry is most valuable before the more complex module lands, not after. Shipping content sync blind is how silent field failures go unnoticed for months.

**M-5 last**, and this is a genuine tension worth naming: `lib/assets/data/` is empty **today**, which means every content feature is currently a shell and the premium tier has little to sell. If bundled content (FR-C-01) is not populated during 3.0–3.3, the subscription flow will ship with nothing behind the paywall. **FR-C-01 is therefore a prerequisite of Release 3.2, even though the sync mechanism (FR-C-02 …) is deferred to 3.4.**

### 15.2 Independence

Each release is independently shippable and independently revertible. Release 3.1 introduces a hard gate (login) — it SHALL NOT ship until AC-A-03 and AC-A-06 pass, because a login defect locks every user out of an app that otherwise needs no network at all.

---

## 16. Open Questions

| ID | Question | Blocks |
|---|---|---|
| OQ-01 | Should progress data (streak, tasbeeh, bookmarks) sync to the account? M-2 gives identity but this document does not specify server-side user data. It is the strongest reason a user would *want* an account. | A future module |
| OQ-02 | Is registration required, or should "continue as guest" exist? Currently login is mandatory (FR-G-03), which is friction ahead of any demonstrated value. | Product decision |
| OQ-03 | Should the gate ever appear *after* Home — e.g. on day 3, once the user values the app? Post-value prompts convert markedly better than pre-value ones. | Product decision |
| OQ-04 | Ads for free users are implied by `FEATURES.md` ("Ad-free" as a premium benefit) but no ad network is specified anywhere. | Monetisation scope |
| OQ-05 | iOS: Apple rejects carrier billing for digital content under §3.1.1. The premium tier likely requires StoreKit on iOS, making M-7's `IapSubscriptionRepository` a prerequisite for App Store release, not a future option. | iOS release |

---
