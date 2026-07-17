# HCP HRMS — Employee App (Flutter)

Phase 2a foundation: **Login + Home Dashboard** working against the live API
`https://hcperp.in/api/ess/...`. Web/Flask untouched — this is a separate app.

- App name: **HCP HRMS**
- Package: **com.hcphrms.ess**
- Base URL: `https://hcperp.in` (in `lib/services/api.dart`)

---

## What's included (Phase 2a)
- `lib/main.dart` — entry + auth gate (token → Login or Home)
- `lib/theme.dart` — brand colors (blue #2563EB) + fonts
- `lib/services/api.dart` — API client (token stored in SharedPreferences)
- `lib/screens/login.dart` — Login (matches mockup)
- `lib/screens/home.dart` — Dashboard (real `/dashboard` data) + quick actions + bottom nav

Quick-action taps + other bottom-nav tabs show "coming in next update" — those
screens arrive in **Phase 2b** (Attendance, Calendar, Leave) and **Phase 2c**
(Salary, Holidays, Form 16, Team, Approvals).

---

## Setup & build APK (you run this — I don't have the Android SDK)

1. Install Flutter: https://docs.flutter.dev/get-started/install

2. Create the Android project shell with the correct package name:
   ```
   flutter create --org com.hcphrms --project-name hcp_hrms hcp_hrms
   ```
   (This makes the native android/ + ios/ folders with package `com.hcphrms.hcp_hrms`.
   To force exactly `com.hcphrms.ess`, use `--org com.hcphrms` and rename applicationId
   in `android/app/build.gradle` to `com.hcphrms.ess`.)

3. Replace the generated `lib/` and `pubspec.yaml` with the ones from this folder.

4. Get packages:
   ```
   flutter pub get
   ```

5. Run on a device (debug):
   ```
   flutter run
   ```

6. Build the release APK:
   ```
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Set the app display name (HCP HRMS)
In `android/app/src/main/AndroidManifest.xml`, set:
```xml
<application android:label="HCP HRMS" ... >
```

## Internet permission (needed for API)
In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` add:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## Test
1. Deploy the **Phase 1 API** on hcperp.in first (from earlier zip) and confirm
   `POST https://hcperp.in/api/ess/login` returns a token.
2. Run the app → login with an employee's User ID + password → Home shows real data.

Next: confirm Phase 2a works, then I'll deliver **Phase 2b** (Attendance/Calendar/Leave screens).
