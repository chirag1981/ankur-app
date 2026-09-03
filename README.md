# Invisible Grills — Estimation, Quotation & Invoice App

A modern, offline-first mobile application built for the **Invisible Grills & Balcony Safety Solutions** business. Enables fast room-by-room window and balcony measurements, automatic unit conversion (inches to feet and sq. ft), automatic material computation, discount application, and instant PDF invoice/quotation sharing over WhatsApp.

---

## 🌟 Core Features

- 📐 **Room & Measurement Hierarchy**:
  - `Customer ➔ Rooms ➔ Windows / Grills ➔ Material & Labor Cost`
  - Input width and height directly in **inches** — real-time automatic conversion to **feet** and **total square feet** `(W" × H") / 144 × Qty`.
- 🔩 **Preconfigured Invisible Grills Materials**:
  - **Channel**: Aluminium profile track channel (calculated automatically by total sq. ft).
  - **Wire**: High-tensile marine grade SS 316 wire (calculated automatically by total sq. ft).
  - **Bolt**: Anchor fasteners and expansion bolts (calculated per window/grill unit).
  - **Chokdi**: Cross stiffeners and spacer chokdi clamps (calculated per window/grill unit).
  - **Labor**: Professional fitting and installation labor (calculated automatically by total sq. ft).
- 💰 **Flexible Pricing & Discounts**:
  - Instant discount application in **Flat ₹** or **Percentage (%)**.
  - Advance payment recording with automatic balance due calculation.
  - Switch between **Quotation / Estimate** and **Tax Invoice** formats.
- 📄 **Official PDF Generation & WhatsApp Sharing**:
  - Itemized measurement schedule table + materials breakdown.
  - Terms & conditions, business header, and signature sign-offs.
  - Single-tap sharing directly to WhatsApp with customer greeting and formatted text summary.
- 🔒 **100% Offline & Private**:
  - Local SQLite storage (`invisible_grills.db`) with foreign-key cascade protection.
  - Zero sensitive customer data sent to third-party servers.

---

## 🛠 Tech Stack

- **Framework**: Flutter 3.29.x (Dart 3.7.x)
- **Architecture**: Feature-First Clean Architecture + Flutter Riverpod
- **Database**: SQLite via `sqflite` (relational models with foreign keys)
- **PDF Engine**: `pdf` & `printing`
- **Design System**: Material 3 with customized Slate & Emerald palette
