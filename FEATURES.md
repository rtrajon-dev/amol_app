# ইসলামিক আমল — Feature & Business Plan

## App Overview

**App Name:** ইসলামিক আমল (Islamic Amol)  
**Package:** com.bdapps.islamic_amol  
**Platform:** Android (primary), iOS  
**Target Market:** Bangladeshi Muslims on Robi/Airtel via BDApps  
**Language:** Bangla UI, Arabic content, English transliteration  

---

## Architecture

### Pattern: Feature-first Clean Architecture

```
lib/
├── main.dart                        # Entry point
├── bootstrap.dart                   # App initialization
├── app/
│   ├── app.dart                     # Root MaterialApp widget
│   ├── router/                      # go_router navigation
│   │   ├── app_router.dart
│   │   └── app_routes.dart
│   ├── theme/                       # Theme & colors
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   ├── services/                    # App-wide services
│   │   ├── notification_service.dart
│   │   └── storage_service.dart
│   ├── di/                          # Dependency injection (Riverpod providers)
│   │   └── providers.dart
│   ├── utils/                       # Shared utilities
│   │   └── prayer_time_utils.dart
│   └── shell/                       # Main scaffold with bottom nav
│       ├── main_shell.dart
│       └── widgets/bottom_nav_bar.dart
├── global_widgets/                  # Reusable UI components
│   ├── primary_button.dart
│   ├── section_header.dart
│   └── loading_indicator.dart
├── features/                        # Feature modules
│   ├── home/
│   ├── prayer_time/
│   ├── tasbeeh/
│   ├── dua/
│   ├── amal_tracker/
│   ├── qibla/
│   ├── hadith/
│   ├── islamic_calendar/
│   ├── names_of_allah/
│   ├── surah/
│   ├── ramadan/
│   ├── onboarding/
│   └── settings/
└── assets/
    ├── fonts/         # Kalpurush (Bangla), Amiri (Arabic)
    ├── images/        # App icon, splash, onboarding
    ├── icons/         # SVG icons
    └── data/          # JSON data files (duas, hadiths, names)
```

### Each Feature Contains:
```
feature_name/
├── data/
│   ├── services/      # API calls, local DB, asset loading
│   └── repositories/  # Repository implementations
├── domain/
│   ├── models/        # Data models / entities
│   └── repositories/  # Repository interfaces
└── presentation/
    ├── view/          # Screen widgets
    ├── viewmodel/     # Riverpod providers / notifiers
    └── widgets/       # Feature-specific widgets
```

### State Management: Riverpod
- `Provider` — synchronous dependencies
- `FutureProvider` — async one-time data
- `NotifierProvider` — mutable state with methods
- `StateProvider` — simple single-value state

### Navigation: go_router
- `ShellRoute` — wraps all main screens with bottom nav
- Named routes via `AppRoutes` constants
- Deep link support for BDApps push notifications

---

## Key Packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation & deep links |
| `adhan` | Prayer time calculation (Karachi/Hanafi method) |
| `hijri` | Hijri ↔ Gregorian calendar conversion |
| `geolocator` | Location for prayer times & qibla |
| `sensors_plus` | Compass sensor for Qibla direction |
| `flutter_local_notifications` | Azan alarms & daily reminders |
| `shared_preferences` | Local persistence (amal streak, settings) |
| `flutter_secure_storage` | Secure token storage (subscription) |
| `google_fonts` | Hind font (Bangla UI) |
| `flutter_screenutil` | Responsive sizing |
| `dio` | HTTP client (future API calls) |

---

## Features

### 1. নামাজের সময়সূচী (Prayer Time)
- GPS-based prayer time calculation using `adhan` package
- Calculation method: Karachi (Hanafi madhab — standard for BD)
- Fallback to Dhaka coordinates if location denied
- 5 daily prayers + Sunrise displayed
- Azan notifications via `flutter_local_notifications`
- District-wise manual city selection (future)

### 2. তাসবিহ কাউন্টার (Digital Tasbeeh)
- Preset tasbeeh: Subhanallah, Alhamdulillah, Allahu Akbar, Istighfar, La ilaha illallah
- Haptic feedback on each count
- Target count with auto-reset on completion
- Session total tracking
- Custom target setting (future)

### 3. দৈনিক দোয়া (Dua Library)
- Categories: Morning Azkar, Evening Azkar, After Prayer, Daily Life, Protection, Food, Sleep, Travel, Sickness
- Arabic text + Bangla transliteration + Bangla meaning
- Source reference (Bukhari, Muslim, etc.)
- Favorite/bookmark system
- Share functionality
- Copy to clipboard
- Data source: `assets/data/duas.json` (offline, no internet needed)

### 4. আমল ট্র্যাকার (Amal Tracker)
- Daily checklist: Fajr, Dhuhr, Asr, Maghrib, Isha, Quran, Morning Azkar, Evening Azkar, Tahajjud
- Streak counter — consecutive days of completed amal
- Daily progress bar
- Celebratory state when all completed
- Auto-reset at midnight
- Premium items: Tahajjud, Qiyamul Layl

### 5. কিবলা (Qibla Finder)
- Compass-based using `sensors_plus` magnetometer
- Qibla bearing calculated via `adhan` library
- Animated compass arrow UI
- Calibration instructions

### 6. হাদিস অফ দ্য ডে
- Daily hadith rotation from `assets/data/hadiths.json`
- Arabic + Bangla translation + narrator + source
- Share to social media
- Push notification delivery via BDApps API (premium)

### 7. ইসলামিক ক্যালেন্ডার
- Hijri date display using `hijri` package
- Important Islamic dates: Eid, Ramadan, Shab-e-Barat, Shab-e-Qadr, Ashura
- Countdown to next Islamic event

### 8. আল্লাহর ৯৯ নাম
- Arabic name + transliteration + Bangla meaning + benefits
- Grid/list view
- Memorization progress tracking (future)
- Data source: `assets/data/names_of_allah.json`

### 9. সূরা সংকলন (Surah Collection)
- Popular short surahs: Fatiha, Ikhlas, Falaq, Nas, Ayatul Kursi, Ya-Sin, Al-Mulk, Ar-Rahman
- Arabic text (Amiri font) + Bangla translation + transliteration
- Verse-by-verse display with numbering
- Bookmarking last read verse
- Data source: `assets/data/surahs.json`

### 10. রমজান স্পেশাল
- Sehri & Iftar time countdown (uses prayer time data: Fajr = Sehri, Maghrib = Iftar)
- Ramadan-specific amal checklist: Tarawih, Quran (1 para/day), Iftar dua, etc.
- Ramadan day counter
- Laylat-ul-Qadr reminder (last 10 nights)

### 11. অনবোর্ডিং
- 3-screen introduction with emoji illustrations
- Permission requests: Location, Notifications
- City selection for users who deny location

### 12. সেটিংস
- City/location selection
- Prayer calculation method
- Azan notification toggle per prayer
- Dark/light mode
- Arabic font size
- Language (Bangla / English)
- Subscription management

---

## Monetization Model (BDApps)

### Free Tier
| Feature | Free |
|---|---|
| Prayer times | ✅ |
| Tasbeeh counter | ✅ (basic) |
| Dua library | ✅ (limited — 30 duas) |
| Qibla | ✅ |
| Hadith of the day | ✅ |
| Islamic calendar | ✅ |
| Amal tracker | ✅ (basic 5 items) |

### Premium Tier — সাপ্তাহিক ৫ টাকা (Weekly 5 BDT)
| Feature | Premium |
|---|---|
| Full dua library (200+ duas) | ✅ |
| Full amal tracker (9 items + Tahajjud) | ✅ |
| Hadith push notifications daily | ✅ |
| Audio recitation for duas | ✅ |
| All 114 surahs | ✅ |
| 99 names of Allah full | ✅ |
| Ramadan special mode | ✅ |
| Ad-free | ✅ |

### BDApps Integration Points
- **Carrier Billing API** — weekly subscription charge (5 BDT)
- **Push Notification API** — daily hadith, Ramadan alerts
- **SMS API** — prayer time alerts for feature phone users (future)
- **Subscription API** — manage subscribe/unsubscribe lifecycle

### Revenue Projection (Conservative)
| Users | Weekly Rate | Monthly Revenue |
|---|---|---|
| 1,000 subscribers | 5 BDT | ~20,000 BDT |
| 5,000 subscribers | 5 BDT | ~100,000 BDT |
| 10,000 subscribers | 5 BDT | ~200,000 BDT |

*BDApps revenue share: ~70% developer, 30% Robi*

---

## Data Files Required (assets/data/)

```
duas.json           — { id, arabic, transliteration, bangla, source, category }
hadiths.json        — { id, arabic, bangla, narrator, source, bookRef }
names_of_allah.json — { number, arabic, transliteration, bangla, meaning }
surahs.json         — { number, arabicName, banglaName, verseCount, ayahs[] }
```

---

## Font Requirements (assets/fonts/)

| Font | Use |
|---|---|
| `kalpurush.ttf` | Bangla UI text |
| `Amiri-Regular.ttf` | Arabic text display |
| `Amiri-Bold.ttf` | Arabic headings |

Download from: Google Fonts (Amiri), omicronlab.com (Kalpurush)

---

## Bottom Navigation Tabs

| Tab | Screen | Icon |
|---|---|---|
| হোম | HomeScreen | home |
| আমল | AmalTrackerScreen | checklist |
| দোয়া | DuaScreen | menu_book |
| তাসবিহ | TasbeehScreen | loop |
| রমজান | RamadanScreen | star |

Additional screens accessible via home grid or more menu:
Prayer Time, Qibla, Hadith, Islamic Calendar, 99 Names, Surah, Settings

---

## Development Roadmap

### Phase 1 — MVP (Current)
- [x] Project structure & architecture
- [ ] Prayer time with GPS
- [ ] Tasbeeh counter
- [ ] Dua library (30 duas, JSON)
- [ ] Basic amal tracker
- [ ] Onboarding flow

### Phase 2 — Core Features
- [ ] Azan notifications
- [ ] Qibla compass
- [ ] Islamic calendar with events
- [ ] Hadith of the day
- [ ] BDApps subscription integration

### Phase 3 — Premium & Polish
- [ ] Full dua library (200+)
- [ ] All 114 surahs
- [ ] 99 names of Allah
- [ ] Audio recitation
- [ ] Ramadan special mode
- [ ] Push notifications via BDApps API
- [ ] Widget support (prayer time home screen widget)

### Phase 4 — Growth
- [ ] Social sharing (WhatsApp, Facebook)
- [ ] Bengali TTS for duas
- [ ] Offline Quran audio
- [ ] BDApps App Store optimization
