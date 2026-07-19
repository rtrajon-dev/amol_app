# Firebase setup — Amol365 (M-6)

**Status: code complete, NOT activated.** The app currently runs with Firebase
disabled and behaves normally. Everything below is what you do once, in the
Firebase console, to switch it on.

---

## Why the app still works without it

`FirebaseService.initialize()` is wrapped in a try/catch. Without config files
it fails, logs a debug line, and sets `isAvailable = false`. Every other
service checks that flag and becomes a no-op.

That is deliberate, not defensive padding: per C-BE-05, prayer times, qibla,
tasbeeh, and the amal tracker need no network at all. **A missing analytics
backend must never be able to stop someone praying on time.**

The same holds for azan (FR-P-04): those notifications are local, scheduled
on-device via `flutter_local_notifications`, and never travel through FCM.
Firebase being down, misconfigured, or absent cannot delay a prayer alert.

---

## What you need to do

### 1. Create the Firebase project

console.firebase.google.com → **Add project** → name it `amol365`.

Google Analytics: **enable it** — FR-P-06 depends on it and it is free.

### 2. Register the Android app

- **Package name:** `com.bdapps.amol365` — must match exactly
- Download **`google-services.json`**
- Put it at **`android/app/google-services.json`**

### 3. Register the iOS app (only if shipping iOS)

- **Bundle ID:** `com.bdapps.amol365`
- Download **`GoogleService-Info.plist`**
- Add it to `ios/Runner/` **through Xcode** (drag into the Runner target) —
  copying the file in Finder alone does not add it to the build

### 4. Apply the Gradle plugin

This step is **currently omitted on purpose**: applying it without
`google-services.json` present makes the Android build fail. Do it only after
step 2.

`android/settings.gradle.kts` — add to the `plugins` block:

```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
id("com.google.firebase.crashlytics") version "3.0.2" apply false
```

`android/app/build.gradle.kts` — add to its `plugins` block:

```kotlin
id("com.google.gms.google-services")
id("com.google.firebase.crashlytics")
```

### 5. Verify

```bash
flutter clean && flutter run
```

Look for `Firebase: initialised` in the logs. If you instead see
`Firebase: unavailable`, the config file is missing or in the wrong place —
the app will still run, just without push, crashes, or analytics.

---

## Remote Config — set these up

Console → **Remote Config** → add these parameters. Until you do, the local
defaults apply and behaviour is exactly what shipped.

| Parameter | Type | Default | What it does |
|---|---|---|---|
| `subscription_gate_enabled` | Boolean | `true` | **Kill switch.** Set `false` to disable the subscription gate app-wide without a release — use during a BDApps outage or if billing is suspended (FR-P-07). |
| `subscription_gate_max_prompts` | Number | `3` | How many times the gate appears automatically (FR-S-09). Tune once real conversion data exists. |
| `daily_hadith_push_enabled` | Boolean | `false` | Turn on once `hadiths.json` is populated (see `docs/CONTENT.md`). |

The kill switch is the one worth setting up first — it is the only way to stop
the gate reaching users if something goes wrong with billing, short of an
emergency release that takes days to reach everyone.

---

## What gets collected — and what must not

### Analytics events (FR-P-06)

The subscription funnel, defined in `AnalyticsEvents`:

`sub_gate_shown` (with `promptNumber`) → `sub_gate_dismissed` →
`sub_phone_submitted` → `sub_otp_requested` → `sub_subscribed`
· `sub_already_subscribed` · `sub_otp_failed` (with error `code`) · `sub_cancelled`

`promptNumber` is the point of the whole thing: it tells you whether prompts 2
and 3 convert anyone or merely annoy. Without it, FR-S-09's limit of 3 is a
guess you can never check.

### Never recorded

| Never | Why |
|---|---|
| Access / refresh tokens | FR-A-04 — a token in a crash report is a live credential |
| Passwords, OTP values | FR-P-05 |
| `referenceNo`, BDApps credentials | FR-BE-06, C-BE-04 |
| Full phone numbers | NFR-S-03 — masked only, and preferably not at all |
| **Location / coordinates** | `docs/SRS.md` NFR-09 — coordinates never leave the device, full stop |

`sub_otp_failed` records the error **code**, never the code the user typed.

---

## Sending the daily hadith

Not built yet, and blocked on content (`docs/CONTENT.md`). When it is:

- Send from a server-side scheduled job, targeting devices whose
  `pushHadithEnabled` is true **and** whose entitlement is premium (FR-P-02).
- Entitlement must be checked **server-side** (FR-S-17). The client's cached
  tier decides what the UI shows; it must never decide what the server sends.
- Include `{"route": "/hadith"}` in the data payload — `PushService` reads
  `route` and deep-links on tap, holding it until the router is ready if the
  app was launched cold (FR-G-07).

---

## Cost

Everything used here is on the Firebase **free (Spark) tier**: FCM is
unlimited, Crashlytics and Analytics are free, Remote Config is free.

No Blaze plan, and therefore **no international credit card** — which is the
whole reason `docs/SRS-Backend-Auth-Subscription.md` §3.2 put identity and
entitlement on your own cPanel server instead of Cloud Functions.
