# SmartExpense - Premium Financial Tracker & Planner

SmartExpense is a state-of-the-art, feature-rich personal finance and expense tracking application built using Flutter. Designed with rich aesthetics, a WCAG AA-compliant design system, dynamic animations, and multi-currency exchange conversion, it provides a premium user experience for managing personal economies, budgets, and loans.

---

## 🚀 Key Features & Capabilities

### 1. Unified Professional Dashboard
- **Financial Health Score:** Real-time health calculation based on savings rate, budget limits, and transaction frequency.
- **Smart Insights:** Interactive cards recommending budget adjustments and highlighting abnormal spending patterns.
- **Advanced Charts:** Interactive multi-tab data visualizations featuring daily trends, monthly comparisons, and category-wise distributions powered by [Syncfusion](https://pub.dev/packages/syncfusion_flutter_charts) and [FL Chart](https://pub.dev/packages/fl_chart).

### 2. Transaction & Budget Management
- **Incomes & Expenses:** Complete categorization and logging of transactions.
- **Budget Limits:** Create monthly budgets per category with custom progress bars.
- **Semantic Alert System:** Colors shift dynamically through safe (green), warning (amber), critical (red), and overspent (dark red) states depending on the budget consumption percentage.
- **Swipe-to-Delete:** Enhanced transaction lists featuring slide-to-delete actions.
- **Recurring Transactions:** Automate repetitive incomes and expenses on weekly, monthly, or yearly schedules.

### 3. Google Drive Sync & Firebase Cloud Storage
- **Authentication:** Support for Firebase Email/Password Auth, Verification Flow, and Google Sign-In.
- **Google Drive Backup:** Sync and backup transactions, categories, and application states to the user's Google Drive storage.
- **Cloud Firestore:** Real-time synchronization across devices using Firebase Firestore.

### 4. Advanced CSV Import & Export
- **Import Formats:**
  - **Standard format:** Column structures matching `Title,Amount,Date,Category,Notes`.
  - **Custom format:** Monthly category expenditure grids with daily breakdown fields.
- **Template Generation:** Generates sample templates locally and opens them automatically.
- **Interactive Demo Screen:** Dedicated screen for testing CSV parsers and verifying raw records before committing to database import.
- **Yearly Reports:** Export full-year logs as PDF documents (formatted for physical printing) or standard CSV sheets.

### 5. Multi-Currency & Live Exchange Rates
- **Supported Currencies:** PKR, USD, EUR, and JPY.
- **Conversion Service:** Dynamic calculations utilizing ExchangeRate-API.
- **Primary Currency Selection:** Save and view all global totals converted to a primary default currency of choice.

### 6. Dynamic Theme System (Material 3)
- **High Contrast Contrast Ratios:** All background-text pairings strictly adhere to WCAG AA guidelines (minimum 4.5:1 ratio).
- **Tabular Figures:** Numbers formatted with OpenType font features to ensure financial amounts align perfectly in lists and tables.
- **Elevation Depth System:** Customized light and dark elevations to represent layout hierarchies using custom box shadows.
- **Micro-Animations:** Fluid layout entries, state transitions, and responsive gesture-bounce effects.

---

## 📂 Project Architecture & Directory Structure

The project decouples business logic, state propagation, and layout design across modular packages:

```
lib/
├── firebase_options.dart         # Generated Firebase setup options
├── main.dart                     # App entry point, MultiProvider configurations
├── models/                       # Data structures and serialization
│   ├── budget.dart
│   ├── expense.dart
│   ├── income.dart
│   ├── loan.dart
│   ├── payment.dart
│   └── recurring_transaction.dart
├── screens/                      # Interactive presentation views
│   ├── dashboard_screen.dart
│   ├── professional_dashboard_screen.dart
│   ├── csv_demo_screen.dart
│   ├── enhanced_login_screen.dart
│   ├── email_verification_screen.dart
│   ├── settings_screen.dart
│   └── ...
├── services/                     # Business logic and platform services
│   ├── analytics_service.dart
│   ├── auth_service.dart
│   ├── budget_service.dart
│   ├── csv_service.dart
│   ├── currency_conversion_service.dart
│   ├── google_drive_service.dart
│   └── ...
├── theme/                        # Design System tokens and custom utilities
│   ├── app_colors.dart
│   ├── app_theme.dart
│   ├── typography.dart
│   ├── spacing.dart
│   └── animations.dart
└── widgets/                      # Modular and reusable UI widgets
    ├── glass_container.dart
    ├── circular_expense_chart.dart
    ├── budget_progress_card.dart
    ├── orbital_speed_dial.dart
    └── ...
```

---

## 🛠️ Technology Stack & Dependencies

The application relies on a modern Flutter architecture:

- **SDK constraints:** `>=3.8.0 <4.0.0`
- **State Management:** [Provider](https://pub.dev/packages/provider) combined with dependency injection via `ProxyProvider` (linking authorization, preferences, and services).
- **Visuals & Charts:** `syncfusion_flutter_charts`, `fl_chart`, `shimmer`, `animations`, `flutter_staggered_animations`.
- **Cloud and Security:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`.
- **Integrations:** `googleapis`, `googleapis_auth`, `file_picker`, `csv`, `pdf`, `printing`.
- **Local Storage:** `shared_preferences`, `path_provider`.

---

## 🚀 Getting Started & Local Setup

### Prerequisites
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version matching the SDK constraint above).
2. Install [Java/JDK 17](https://adoptium.net/temurin/releases/?version=17) or higher (configured as `JAVA_HOME`).
3. Setup an Android emulator, iOS simulator, or a web browser.

### Clone and Configure API Keys
To run the live currency exchange feature, build the application with a valid ExchangeRate-API key passed as a Dart compiler definition:

```bash
# Clone the repository
git clone https://github.com/SaimSuhailQu/smartexpense.git
cd smartexpense

# Retrieve dependencies
flutter pub get

# Run the app with the API key defined
flutter run --dart-define=EXCHANGE_RATE_API_KEY=YOUR_EXCHANGE_RATE_API_KEY
```

> [!NOTE]
> **Linux Development:** Since Firebase does not have native support on Linux desktop platforms, the application automatically runs in **bypassed local demo mode** when compiled/run under a Linux kernel. This allows full dashboard, CSV, offline budgeting, and styling testing without startup crashes.

### Gradle & JDK Configuration (Recent Fixes)
The Android Gradle builds have been upgraded to compile on modern targets:
- **JDK Target:** Java 17 compatibility.
- **Android Gradle Plugin (AGP):** `8.7.3`
- **Kotlin Plugin:** `1.9.25`
- **Gradle Wrapper:** `8.12`

If you encounter JVM version mismatch warnings, clean the environment before running a fresh compile:
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk
```

---

## 🧪 Testing

The codebase includes widgets and unit tests under the `/test` directory. Run them using the standard Flutter testing runner:

```bash
flutter test
```

For the custom CSV importing flows, you can test parsing capabilities without connecting to databases by navigating to the **CSV Demo screen** on the dashboard.

---

## 🎨 Theme & Design System Documentation

For detailed guides about styling constants and typography standards:
- Refer to [DESIGN_SYSTEM.md](file:///home/shin/smartexpense/DESIGN_SYSTEM.md) for custom colors, accessibility rules, and figures spacing.
- Refer to [THEME_QUICK_REFERENCE.md](file:///home/shin/smartexpense/THEME_QUICK_REFERENCE.md) for quickly looking up primary, secondary, and elevated surface tokens.
- Refer to [THEME_SYSTEM_ENHANCEMENTS.md](file:///home/shin/smartexpense/THEME_SYSTEM_ENHANCEMENTS.md) for information regarding how light/dark themes are computed dynamically.
- Refer to [FIXES_APPLIED.md](file:///home/shin/smartexpense/FIXES_APPLIED.md) to inspect history of build issues and Kotlin/Java version fixes.
