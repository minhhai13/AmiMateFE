# amimate

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AmiMate local API

The app uses `http://localhost:8080/api/v1` as its default API base URL for
local development with the iOS Simulator. Override it at build/run time with:

```sh
flutter run --dart-define=AMIMATE_BASE_URL=http://localhost:8080/api/v1
```

The value must be an absolute HTTP or HTTPS URL containing the API prefix.
# AmiMateFE
