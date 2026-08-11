# GymMate AI — Auth Module Setup

This is the foundation for the GymMate AI Flutter app: email/password
signup+login, forgot password, Google Sign-In, and a Firestore user
profile document created automatically on signup.

## 1. Connect this code to your existing Firebase project

```bash
# in the project root (where pubspec.yaml is)
flutter pub get

dart pub global activate flutterfire_cli
flutterfire configure
```

`flutterfire configure` will:
- List your existing Firebase projects — pick the one you already created
- Ask which platforms to register (Android / iOS / Web)
- Overwrite `lib/firebase_options.dart` with your real project's keys
- Drop `android/app/google-services.json` and/or
  `ios/Runner/GoogleService-Info.plist` into place automatically

**Don't skip this step** — the `firebase_options.dart` in this project
is a placeholder template, not real credentials.

## 2. Enable sign-in providers in the Firebase Console

Go to **Firebase Console → Authentication → Sign-in method** and enable:
- **Email/Password**
- **Google**

## 3. Google Sign-In extra setup

**Android:** Add your SHA-1 (and SHA-256 for release builds) fingerprint
in **Firebase Console → Project Settings → Your apps → Android app**.
Get it with:
```bash
cd android && ./gradlew signingReport
```

**iOS:** Add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as
a URL scheme in `ios/Runner/Info.plist` (FlutterFire CLI usually handles
most of this, but double-check `Info.plist` has the URL scheme entry).

## 4. Firestore Security Rules

In **Firebase Console → Firestore Database → Rules**, use at minimum:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

This makes sure a user can only read/write their own profile document —
important since later modules (workout history, progress, diet plans)
will likely live in subcollections under `users/{uid}/...`.

## 5. Run it

```bash
flutter run
```

## What's included

| File | Purpose |
|---|---|
| `lib/main.dart` | Firebase init + `AuthGate` that auto-routes between Login/Home based on sign-in state |
| `lib/services/auth_service.dart` | Signup, login, forgot password, Google Sign-In, sign out |
| `lib/services/firestore_service.dart` | Create/read/update/stream the `users/{uid}` profile document |
| `lib/models/user_model.dart` | User profile model — already includes the fitness fields (age, height, weight, goal, experience) so the Profile & Assessment modules can plug in without a schema change |
| `lib/screens/login_screen.dart` | Login UI |
| `lib/screens/signup_screen.dart` | Signup UI |
| `lib/screens/forgot_password_screen.dart` | Password reset UI |
| `lib/screens/home_screen.dart` | Placeholder post-login screen streaming the live profile from Firestore |

## Firestore schema so far

```
users (collection)
  {uid} (document)
    uid, name, email, photoUrl
    age, gender, heightCm, weightKg
    fitnessGoal, experienceLevel, workoutDaysPerWeek
    foodPreference, medicalConditions[]
    createdAt
```

Next modules (Profile onboarding form, AI Fitness Assessment, Workout
Recommendation Engine) will read/write to this same document, and later
ones (Workout History, Progress Dashboard) will likely use subcollections
like `users/{uid}/workoutHistory/{date}`.

## Next step

Once this is running and you can sign up / log in / reset password /
sign in with Google and see your name show up on the Home screen, the
natural next module to build is the **Profile / Onboarding form** (age,
height, weight, goal, experience) — that's what feeds the BMI calculation
and the AI Workout Recommendation Engine.
