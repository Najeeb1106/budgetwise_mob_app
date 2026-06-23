# BudgetWise

[![Flutter Version](https://img.shields.io/badge/Flutter-v3.9.2+-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![Platform Support](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue?style=flat-square)](#)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

A premium, feature-rich personal finance and budgeting application built using **Flutter**. BudgetWise provides real-time financial tracking, interactive charts, secure local database encryption, smart goal management, and seamless biometric authentication designed to keep your personal data secure.

---

## 📸 Interface Preview

*(Screenshots and screen recordings demonstrating the onboarding flow, transactions list, charts, and budget configuration will be showcased here.)*

---

## ✨ Features

- 📊 **Dynamic Dashboards**: Comprehensive financial overviews with responsive pie charts, line graphs, and transaction trends using `fl_chart`.
- 🔒 **Biometric App Lock**: Fingerprint and Face ID authentication guard your financial files using `local_auth`.
- 📁 **Drift Encryption**: Secure offline-first SQL database running on top of custom-compiled SQLCipher libraries.
- 💡 **Smart Savings Goals**: Visual target metrics helping users define, modify, and track short/long-term financial achievements.
- 🏷️ **Categorized Transaction Lists**: Custom transaction pagination, search controls, and advanced category management options.
- 🔔 **Local Reminders & Notifications**: Scheduled recurring updates to prompt users for daily transaction inputs.
- 🌓 **System Dark & Light Themes**: Harmonious UI styling aligning with system-wide dark mode preferences using Google Fonts.

---

## 🛠️ Tech Stack

- **Core SDK**: Flutter & Dart
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_generator`)
- **Database Engine**: Drift (`drift_dev`) + SQLite + SQLCipher (`sqlcipher_flutter_libs`)
- **Navigation/Routing**: Go Router (`go_router`)
- **Charting Engine**: FL Chart (`fl_chart`)
- **Security & Lock**: Local Auth (`local_auth`) + Flutter Secure Storage (`flutter_secure_storage`)
- **Typography**: Google Fonts (Inter)
- **Icons**: Lucide Icons (`lucide_icons`)

---

## 📂 Folder Structure

```
lib/
├── data/             # Database access layers, Drift definitions, schema migrations
├── main.dart         # Entry point setting up dependencies, local notifications, & themes
├── providers/        # Riverpod providers tracking state (goals, settings, transactions)
├── router.dart       # Navigation config mapping paths via GoRouter
├── screens/          # User interface components grouped by domain/feature
│   ├── analytics/    # Interactive financial graphs and chart visualization
│   ├── budget/       # Budget configuration & limit screens
│   ├── dashboard/    # Main balance, overview cards, and summary stats
│   ├── goal/         # Smart goals list & detailed tracker widgets
│   ├── onboarding/   # Splash-to-tutorial transition page
│   ├── security/     # PIN and biometric locks
│   ├── settings/     # Custom preferences & category manager screen
│   ├── splash/       # Logo presentation loader screen
│   └── transaction/  # List views, transaction detail editors, and pagination
├── services/         # Platform hooks: biometric status checker, local notifications
└── utils/            # Shared converters, date formatters, and style guides
```

---

## 🚀 Getting Started

### Prerequisites

To build and run this application, ensure your environment meets the following dependencies:
- **Flutter SDK**: `>=3.9.2`
- **Dart SDK**: `>=3.9.2`
- **Android Studio / SDK** or **Xcode** (for iOS emulator execution)

### Installation & Execution

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Najeeb1106/budgetwise_mob_app.git
   cd budgetwise_mob_app
   ```

2. **Retrieve Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Code Generation (Drift database mappings)**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Launch Application**:
   - Ensure an active emulator/simulator or physical device is connected.
   - Run the application:
     ```bash
     flutter run
     ```

---

## 🧪 Testing

To run the complete suite of unit and widget test files:
```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
