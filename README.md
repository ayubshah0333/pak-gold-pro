# Pak Gold Pro (Sarafa Rates & Calculator)

A Flutter application built for Pakistani jewelers, bullion traders, and gold buyers, featuring live Sarafa market rates, jewelry billing, scrap gold melting calculations, traditional unit conversions, and custom shop-branded WhatsApp receipts.

## Features

- **Live Sarafa Market Rates:** Displays 24K, 22K, 21K, and 18K gold rates per Tola, per 10 Grams, and per Gram with manual rate override support.
- **Jewelry Purchase & Bill Calculator:** Calculates Net Weight (*Safi Wazan*) after gemstone (*Nageena*) deduction, making charges (*Mazdoori* — flat, per-gram, or percentage), and discounts.
- **Old Gold / Scrap Melter Calculator:** Supports 24K down to 8K and custom karats (1K–23K), melting loss (*Katan*) in percent or grams, and net cash payout calculation.
- **Gold Unit Converter:** Converts between Tola, Masha, Ratti, Grams, and Milligrams using Pakistani Sarafa standards (`1 Tola = 11.664 g`).
- **Shop Profile & WhatsApp Receipts:** Jewelers can configure their shop name and contact details so generated receipts and *Parchas* carry their shop branding.
- **Saved Parchas & History:** Offline calculation history with search, filtering (All, Jewelry, Scrap Melter), copy, and WhatsApp sharing.

## Tech Stack

- **Framework:** Flutter (Dart SDK `^3.13.5`)
- **Packages:** `intl`, `shared_preferences`, `url_launcher`, `http`, `google_mobile_ads`
- **Android Application ID:** `com.pakgoldpro.calculator`

## Project Structure

```text
lib/
├── main.dart
├── models/
│   ├── calculation_record.dart
│   └── jewelry_bill.dart
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── jewelry_calculator_screen.dart
│   ├── scrap_calculator_screen.dart
│   ├── unit_converter_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── gold_rate_service.dart
│   ├── gold_math_service.dart
│   ├── preferences_service.dart
│   ├── sarafa_storage.dart
│   ├── ad_service.dart
│   └── ad_config.dart
├── theme/
│   └── app_theme.dart
├── utils/
│   └── gold_math.dart
└── widgets/
    └── banner_ad_widget.dart
```

## Getting Started

1. Ensure Flutter is installed and configured (`flutter doctor`).
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run tests:
   ```bash
   flutter test
   ```
4. Run the app:
   ```bash
   flutter run
   ```

> **Note:** Release signing files (`android/key.properties`, `*.jks`) and build outputs (`PLAYSTORE_RELEASE_FILES/`, `build/`) are excluded via `.gitignore` for security.
