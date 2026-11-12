# Campus Transit

A student transport application for Walter Sisulu University.

## Run in a browser

Install Flutter, then run these commands from the project directory:

```shell
flutter pub get
flutter run -d chrome
```

## Deploy to Firebase Hosting

The Firebase project `campustransit-26c45` is configured for Hosting. Sign in
with an account that has access to the project, then build and deploy:

```shell
firebase login
flutter build web --release
firebase deploy --only hosting --project campustransit-26c45
```
