# The Menu – Driver App 🛵💨

A premium, high-performance Flutter application built for **The Menu** restaurant delivery partners. This app handles driver authentication, profile management, and delivery status tracking with a sleek, dark-themed interface.

## 🚀 Features
- **Modern UI**: Dark mode glassmorphism design using `Google Fonts` (Lato).
- **Authentication**: Secure login and registration with vehicle details.
- **Real-time Status**: Toggle between Online/Offline status.
- **Backend Integration**: Powered by a Laravel (Sanctum) API.

---

## 🛠️ Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Laravel (PHP)
- **Database**: MySQL
- **State Management**: Provider
- **Icons & Animations**: Cupertino Icons, Lottie

---

## 📦 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.0.0)
- [Laravel Backend](link-to-backend-repo-if-any) (Running locally or on a server)

### 2. Backend Configuration
Ensure your Laravel backend is running. Update the `baseUrl` in `lib/services/api_service.dart`:
- **Android Emulator**: `http://10.0.2.2:8000/api`
- **iOS Simulator / Web**: `http://127.0.0.1:8000/api`
- **Physical Device**: Use your computer's local IP (e.g., `http://192.168.1.XX:8000/api`)

### 3. Installation
```powershell
flutter pub get
```

---

## 📱 Platform Specifics

### Android
- **App Name**: The Menu Driver
- **Package**: `com.example.the_menu_driver_app`
- **Build APK**:
  ```powershell
  flutter build apk --release
  ```

### iOS
- **App Name**: The Menu Driver App
- **Build IPA** (Requires macOS + Xcode):
  ```bash
  flutter build ios --no-codesign
  ```

---

## 🧪 Verification
Run the API verification script to ensure the backend is reachable:
```powershell
dart test/verify_api.dart
```

---

## 🎨 Design System
The app uses a curated **Yellow & Deep Black** palette:
- **Primary**: `#FFDD00` (Yellow)
- **Background**: `#000000` (Pure Black)
- **Surface**: `#121212` (Dark Grey)
