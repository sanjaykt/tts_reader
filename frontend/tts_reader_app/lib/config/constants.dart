// constants.dart — centralised configuration values for the app.
//
// CURRENT APPROACH: simple static constants (good for development).
//
// WHEN YOU DEPLOY: graduate to --dart-define so you can pass different
// values at build time without changing code:
//
//   flutter run --dart-define=BASE_URL=https://api.yourserver.com
//   flutter build web --dart-define=BASE_URL=https://api.yourserver.com
//
// Then replace the const below with:
//   static const baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://127.0.0.1:8000');

class AppConstants {
  // Private constructor prevents this class from being instantiated.
  // It's a holder for constants only — no need to ever create an AppConstants object.
  AppConstants._();

  // The base URL of the FastAPI backend.
  // Using 127.0.0.1 instead of localhost avoids a Chrome/macOS issue where
  // localhost resolves to IPv6 (::1) but the server only listens on IPv4.
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Maximum characters allowed for a single TTS request.
  // The backend enforces the same limit — this gives instant feedback in the UI.
  static const int maxTtsChars = 5000;
}
