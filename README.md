<p align="center">
  <img src="app-images/Screenshot%202026-09-03%20145323.png" width="650" alt="Wajahat POS Home Dashboard">
</p>

<h1 align="center">Wajahat POS — Open Source POS App</h1>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev/multi-platform"><img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS-blue" alt="Platform"></a>
  <a href="pubspec.yaml"><img src="https://img.shields.io/badge/Version-1.0.1-green.svg" alt="Version"></a>
</p>

---

## 📖 Overview

**Wajahat POS** is a free, open-source Point of Sale (POS) and store management application built with **Flutter & Isar NoSQL Database**. Designed with an **offline-first** architecture, it guarantees reliable operations even without an internet connection, while seamlessly synchronizing data to the cloud whenever online. Perfect for retail shops, supermarkets, small businesses, and warungs.

---

## 📸 Screenshots

| Screenshot | Description | Screenshot | Description |
| :---: | :--- | :---: | :--- |
| ![Home Dashboard](app-images/Screenshot%202026-09-03%20145323.png) | **Home Dashboard**: Quick metrics (Today's Sales, Profit, Bills) & shortcuts. | ![POS Cashier](app-images/Screenshot%202026-09-03%20145415.png) | **POS Cashier**: Instant barcode search & live cart calculation. |
| ![Checkout Modal](app-images/Screenshot%202026-09-03%20145456.png) | **Receipt Preview**: Live checkout details & cashier info. | ![Receipt Footer](app-images/Screenshot%202026-09-03%20145512.png) | **Bill Summary**: Custom receipt footer notes & totals. |
| ![Inventory Management](app-images/Screenshot%202026-09-03%20145202.png) | **Inventory**: Product catalog, stock levels & search. | ![Edit Item](app-images/Screenshot%202026-09-03%20145228.png) | **Product Form**: Price management & low-stock alerts. |
| ![Bills History](app-images/Screenshot%202026-09-03%20145657.png) | **Bills History**: Range filters, pending prints & PDF export. | ![Profit Report](app-images/Screenshot%202026-09-03%20145557.png) | **Profit & Sales Report**: Revenue, total costs & bill breakdown. |
| ![Audit Logs](app-images/Screenshot%202026-09-03%20145620.png) | **System Audit Logs**: Real-time activity tracking & transaction history. | ![Store Settings](app-images/Screenshot%202026-09-03%20144902.png) | **Store Settings**: Business profile, logo upload & receipt setup. |
| ![Printer & Data Tools](app-images/Screenshot%202026-09-03%20144943.png) | **Data & Printer Tools**: Thermal printer testing, database backup/restore & CSV exports. | | |

---

## ✨ Implemented Features

### 🏪 Inventory & Catalog Management
- [x] Full Product CRUD (Add, Edit, Delete, Adjust Stock).
- [x] Instant item search by name, code, SKU, or category.
- [x] Barcode scanning via external hardware (USB / Bluetooth) & mobile camera.
- [x] Stock replenishment requests and low-stock alerts.
- [x] Catalog import and export in CSV format.

### 💳 POS Cashier & Checkout System
- [x] High-performance checkout UI with real-time total calculations.
- [x] Buying price (`hargaDasar`), selling price (`hargaJual`), and line-item overrides.
- [x] Instant thermal receipt printing over USB & Bluetooth (ESC/POS commands).
- [x] Automatic cash drawer opening trigger.
- [x] Customizable receipt header/footer messages & optional sale notes (`keterangan`).

### 👥 Customer & Credit / Debt Tracking
- [x] Customer directory management & quick lookup.
- [x] Debt / Credit tracking (`due_payment`) with installment payment logging.
- [x] Outstanding balance summaries per customer.

### 🔑 Rental Management System
- [x] Rental item catalog & rate configuration.
- [x] Track active rentals, return dates, and overdue items.

### 👷 Employee, Shift & Salary Management
- [x] Multi-user role management and permission settings.
- [x] Employee attendance & shift presence log.
- [x] PIN-protected salary management module *(default PIN: `111111`)*.

### 💸 Operational Expense Tracking
- [x] Record daily store operating expenses (utilities, overhead, maintenance).
- [x] Automated cost deduction for accurate net profit calculation.

### 📊 Analytics & Exportable Reporting
- [x] Daily, weekly, monthly, and custom date range sales reporting.
- [x] Revenue, gross profit, and cost analytics with visual charts (`fl_chart`).
- [x] One-click PDF bill invoice generation & CSV transaction export.

### 📜 System Audit Trail
- [x] Automated activity logging for sales, inventory adjustments, PDF exports, and print states.

### 🔄 Data & Cloud Sync
- [x] Offline-first architecture powered by Isar NoSQL engine.
- [x] Local database backup and restoration.
- [x] Automatic background synchronization to Supabase Cloud Database.

### 📱 Platform Support
| Platform | Status |
| :--- | :--- |
| ✅ Android | Supported |
| ✅ iOS | Supported |
| ✅ Windows | Supported (Desktop `.exe` installer) |
| ✅ macOS | Supported |
| 🔜 Linux | In progress |

---

## 🛠️ Tech Stack & Dependencies

| Category | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Language & Framework** | Dart `>=3.3.3`, Flutter `>=3.3.3` | Multi-platform application framework |
| **Local Database** | [Isar](https://isar.dev) | High-performance offline-first NoSQL engine |
| **Cloud & Sync** | [Supabase](https://supabase.com) | Cloud database synchronization & authentication |
| **State Management** | [Signals](https://pub.dev/packages/signals) | Fine-grained reactive state management |
| **Dependency Injection** | [GetIt](https://pub.dev/packages/get_it) | Service locator pattern |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) | Declarative typed routing |
| **UI Components** | [Shadcn UI](https://pub.dev/packages/shadcn_ui) | Modern component UI library |
| **Charts** | [fl_chart](https://pub.dev/packages/fl_chart) | Sales and profit analytical charts |
| **PDF & Printing** | [pdf](https://pub.dev/packages/pdf), `usb_esc_printer_windows` | Receipt printing and invoice PDF generation |
| **Barcode Scanner** | `flutter_barcode_listener` | Hardware USB/Bluetooth scanner handler |

---

## 🚀 Installation & Setup

### Prerequisites
* Flutter SDK `>=3.3.3` (Stable Channel)
* Dart SDK `>=3.3.3 <4.0.0`
* **Windows Native Desktop Build Requirements**:
  * Visual Studio with **Desktop development with C++** workload (MSVC v143 build tools & Windows SDK).
  * [Inno Setup 6](https://jrsoftware.org/isdl.php) (for compiling installer setup `.exe`).

### Steps to Run

1. **Clone the repository:**
```bash
git clone https://github.com/wajahat2005/pos.git
cd pos
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Run the Isar code generator:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Run in development mode (Windows), passing your Supabase credentials:**
```bash
flutter run -d windows --dart-define=url="YOUR_SUPABASE_URL" --dart-define=anonKey="YOUR_SUPABASE_ANON_KEY"
```

5. **Build Windows Release Executable & Installer:**
```cmd
cd installer
build_installer.bat
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
