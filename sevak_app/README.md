# SevakAI 🤝

**SevakAI** is a premium, AI-powered volunteer coordination platform built with Flutter, Firebase, and Riverpod. 

## 🚀 Getting Started for Collaborators

To contribute to this project, you need to set up your local development environment to connect to our Firebase backend.

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.22.0 or higher recommended)
- Android Studio / VS Code
- A valid Java Keystore (Debug Keystore) on your local machine.

### 2. Environment & Firebase Setup (CRITICAL)
For security reasons, environment variables and Firebase configuration files are **NOT** included in this repository. 

1. **Environment Variables**: Copy `.env.example` to a new file named `.env` in the root directory and fill in the required API keys (contact the administrator for these).
2. **Firebase Config**: Reach out to the project administrator to get the following two files:
   - `google-services.json`: Place this inside the `android/app/` directory.
   - `firebase_options.dart`: Place this inside the `lib/` directory.

### 3. Google Sign-In Authentication Setup
Google Sign-In will **crash** on your local machine if your local Android Debug SHA-1 fingerprint is not registered in our Firebase Console.

Please contact the project administrator privately to:
1. Provide them with your local machine's SHA-1 and SHA-256 keys.
2. Receive the properly configured `google-services.json` file to place in your `android/app/` directory.

### 4. Running the App

1. Install all dependencies:
   ```bash
   flutter pub get
   ```

2. Generate code (for Riverpod/Freezed if applicable):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## 🏗️ Architecture

This project follows a **Feature-first Clean Architecture** pattern using Riverpod for state management:
- `lib/core/`: Theming, utilities, and global configurations.
- `lib/features/`: Isolated feature modules (e.g., `auth`, `home`).
  - `data/`: Data sources, repositories, and DTOs.
  - `domain/`: Business logic, entities, and repository interfaces.
  - `presentation/`: UI components, pages, and Riverpod controllers.

---
*If you encounter any issues with a "black screen" or Google Sign-In instantly closing, please double-check Step 3!*
