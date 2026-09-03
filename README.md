# wajahat_POS — Offline-First Point of Sale (POS) System

[![Status](https://img.shields.io/badge/Status-In_Development-orange?style=flat-square)](#)
[![Flutter 3.x](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Isar Database](https://img.shields.io/badge/Isar-NoSQL_Offline-40C4FF?style=flat-square&logo=sqlite&logoColor=white)](https://isar.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud_Sync-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg?style=flat-square)](LICENSE)

> Cross-platform, offline-first Point of Sale application built with Flutter and Dart for cashier operations, thermal receipt printing, and local data persistence.

---

## Overview

wajahat_POS is a desktop and mobile point-of-sale application designed for retail transactions. It operates zero-latency local transaction management via Isar DB and SQLite, with optional cloud backup powered by Supabase.

---

## Implemented Features

* **Cashier Checkout UI:** Product searching, cart management, total calculation, and discount handling.
* **Offline Local Storage:** Local persistence via Isar DB and SQLite.
* **Thermal Printing Integration:** Hardware printing support for USB and Bluetooth printers (esc_pos_utils, print_bluetooth_thermal).
* **Barcode Listener & Scanner:** Scanner support for product lookup.
* **Receipt & Report Generation:** PDF invoice generation and transaction charts (l_chart).
* **Supabase Integration:** Backend sync bindings for remote data backup.

---

## Tech Stack

* **Framework:** Flutter (Windows, Android, iOS)
* **State Management:** Signals (signals), Flutter Hooks (lutter_hooks), GetIt (get_it)
* **Local Storage:** Isar DB (isar), SQLite (sqlite3)
* **Backend Integration:** Supabase (supabase_flutter)
* **UI & Data Viz:** Shadcn UI (shadcn_ui), Lucide Icons, FL Chart (l_chart)

---

## Installation & Setup

`ash
# Clone repository
git clone https://github.com/wajahat2005/pos.git
cd pos

# Install dependencies
flutter pub get

# Run Isar generator
dart run build_runner build --delete-conflicting-outputs

# Launch on Windows
flutter run -d windows
`

---

## License

Distributed under the [MIT License](LICENSE).
