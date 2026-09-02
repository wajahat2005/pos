# 🛍️ DueKasir — Offline-First Point of Sale (POS) System

[![Flutter 3.x](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Isar Database](https://img.shields.io/badge/Isar-NoSQL_Offline-40C4FF?style=flat-square&logo=sqlite&logoColor=white)](https://isar.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud_Sync-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg?style=flat-square)](LICENSE)

A cross-platform, offline-first Point of Sale (POS) application built with Flutter and Dart. **DueKasir** provides retail businesses with instant cashier operations, barcode scanning, thermal receipt printing (USB & Bluetooth), offline transaction caching via Isar DB, and optional cloud sync powered by Supabase.

---

## 📌 Features & Capabilities

- ⚡ **Instant Cashier Checkout**: High-speed item search, cart management, discount application, and total calculations.
- 📴 **100% Offline-First Data Store**: Uses **Isar DB** and **SQLite** for zero-latency local operations even without an internet connection.
- 🖨️ **ESC/POS Thermal Printing**: Direct printing support for USB and Bluetooth receipts (esc_pos_utils, print_bluetooth_thermal).
- 📷 **Hardware & Camera Barcode Scanning**: Integrated barcode listener and scanner support for instant product identification.
- 📊 **Financial & Sales Analytics**: Visual revenue metrics, product velocity graphs, and sales reports powered by l_chart.
- 📑 **PDF Invoice & Receipt Generation**: Instant export of receipts and sales summaries to PDF files.
- ☁️ **Cloud Synchronization**: Background data sync with Supabase backend when connectivity is restored.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: Flutter (Desktop, Android, iOS, Windows)
- **State Management**: Signals (signals), Flutter Hooks (lutter_hooks), GetIt (get_it)
- **Local Databases**: Isar DB (isar), SQLite (sqlite3)
- **Cloud Backend**: Supabase (supabase_flutter)
- **UI Components**: Shadcn UI (shadcn_ui), Lucide Icons (lucide_icons_flutter), FL Chart (l_chart)
- **Hardware Integration**: Thermal ESC/POS (esc_pos_utils), Bluetooth Printer, USB Printer

---

## 💻 Installation & Local Setup

### Prerequisites
- Flutter SDK (>=3.3.3) installed on your system.

### 1. Clone Repository
`ash
git clone https://github.com/wajahat2005/pos.git
cd pos
`

### 2. Install Dependencies
`ash
flutter pub get
`

### 3. Run Build Runner (Isar Code Generator)
`ash
dart run build_runner build --delete-conflicting-outputs
`

### 4. Run Application
`ash
# Run on Windows Desktop
flutter run -d windows

# Run on Chrome Web
flutter run -d chrome
`

---

## 📄 License

This repository is distributed under the [MIT License](LICENSE).