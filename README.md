# Activity 14 — Firebase Cloud Messaging in Flutter

**Student:** Jeremy Henry-Atohengbe  
**Platform:** Android

This app displays a campus update card and changes its title and image
when it receives a valid Firebase Cloud Messaging payload. The screen
shows the last handler, receipt count, message ID, and validation result.

## Setup

1. Install Flutter, the Android SDK, the Firebase CLI, and the FlutterFire CLI.
2. From the project root, run `flutter pub get`. The activity uses
   `firebase_core` 4.x and `firebase_messaging` 16.x.
3. If you need to configure a different Firebase project, run
   `firebase login`, then run the command below with your project ID.

   ```powershell
   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID --platforms=android
   ```

4. Confirm that `lib/firebase_options.dart` exists and that both images
   are present under `assets/images/`.

## Build and Run

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

For device testing, connect an Android phone with USB debugging enabled
and run `flutter run`. Allow notifications when prompted. The debug
terminal prints the current FCM registration token. Use it to target
your test device and redact it from evidence.

## Payload

Use this notification title and body with the two custom data fields
shown below. Enter `asset` and `action` as separate key-value pairs in
the message composer.

```json
{
  "notification": {
    "title": "Campus Event",
    "body": "A new campus event has been posted."
  },
  "data": {
    "action": "update_ui",
    "asset": "promo"
  }
}
```

`asset: promo` selects the orange Campus Event card. `asset: default`
selects the blue Campus Updates card. An unsupported value updates the
receipt details and shows a rejection while preserving the current
title and image.

## Device Test Plan

| Test | Action | Expected evidence |
| --- | --- | --- |
| T1 | Send the valid payload while the app is visible. | `onMessage`, a higher receipt count, and the orange card. |
| T2 | Press Home, send the same payload, and tap the notification. | `onMessageOpenedApp`, a higher receipt count, and the orange card. |
| T3 | Dismiss the app from Recents, send the same payload, and tap the notification. | `getInitialMessage`, receipt count `1`, and the orange card. |
| T4 | Keep the app visible and resend with `asset: unknown` and title `Invalid Payload Test`. | `onMessage`, a higher receipt count, a rejection message, and the same title and image as T3. |
