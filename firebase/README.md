# Firebase push setup (customer app)

Push uses **Firebase Cloud Messaging**. Without these files/env vars, the app still runs; push simply no-ops.

## 1. Firebase project

1. Create (or open) a Firebase project and add **iOS** (`com.wherethevibesat`) + **Android** (`com.wherethevibesat`) apps.
2. Download:
   - `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`
   - `google-services.json` → `android/app/google-services.json`
3. In Xcode: enable **Push Notifications** and **Background Modes → Remote notifications** for the Runner target.
4. Upload an APNs key in Firebase Console → Project settings → Cloud Messaging.

## 2. Admin sender (FCM HTTP v1)

In `web-app-admin/.env.local` (from a Firebase service account JSON):

```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@....iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

## 3. Database

Apply migration `038_push_notifications.sql` on the shared Supabase project.

## 4. Smoke test

1. Sign in on a physical device (simulator push is limited).
2. Confirm a row in `device_push_tokens`.
3. Admin → Messages → check **Push to phone** → Send now.
