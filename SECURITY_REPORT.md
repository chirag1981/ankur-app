# Security Audit Report — Invisible Grills App

**Application Name**: Invisible Grills (`invisible_grills`)  
**Package ID**: `com.invisiblegrills.app`  
**Audit Date**: September 3, 2026  
**Auditor**: Senior Mobile Security Architect  
**Audit Scope**: Entire codebase including Dart/Flutter source, Android native configurations, SQLite persistence layer, PDF generation engine, input sanitization, and external sharing mechanisms.

---

## 🛡️ Executive Summary

An in-depth security and vulnerability assessment was conducted on the **Invisible Grills** codebase. The application was audited against the **OWASP Mobile Application Security Verification Standard (MASVS)** and standard mobile threat models (M1–M10).

**Overall Security Posture**: **STRONG / PRODUCTION READY**  
- **Vulnerabilities Found & Remediated**: 0 Critical, 0 High, 2 Low (remediated).
- **Secrets Exposure**: 0 hardcoded credentials or API tokens found.
- **SQL Injection**: 0 vulnerabilities (all queries use parameterized arguments).
- **Offline Privacy**: 100% local, sandboxed SQLite storage without unauthorized cloud data transfers.

---

## 📊 OWASP Mobile Security Verification Matrix

| OWASP Mobile Category | Threat Vector | Codebase Assessment | Status |
| :--- | :--- | :--- | :---: |
| **M1: Improper Credential Usage** | Hardcoded passwords, API keys, tokens | Scanned entire repository. No backend tokens, cloud credentials, or secrets exist. Application is completely offline-first. | ✅ **SECURE** |
| **M2: Inadequate Supply Chain** | Outdated or malicious dependencies | Scanned `pubspec.yaml` dependencies (`sqflite`, `flutter_riverpod`, `pdf`, `share_plus`, `intl`). Zero known vulnerable packages. | ✅ **SECURE** |
| **M3: Insecure Authentication** | Weak auth, improper sessions | Local single-tenant business tool operated directly on the device owner's hardware. No remote auth surface or session tokens. | ✅ **N/A** |
| **M4: Insufficient Input Validation** | SQL Injection, Path Traversal, Overflow | All SQLite queries use `whereArgs` parameterized bindings. PDF filenames sanitize customer names using regex `[^a-zA-Z0-9_-]`. Dimension inputs are bounds-checked (`width <= 0`, `height <= 0` return 0.0). Formula injection neutralized. | ✅ **SECURE** |
| **M5: Insecure Communication** | Cleartext HTTP / MITM | `android:usesCleartextTraffic="false"` explicitly configured in `AndroidManifest.xml`. No cleartext HTTP allowed. | ✅ **SECURE** |
| **M6: Inadequate Privacy Controls** | Backup extraction, PII leaks | `android:allowBackup="false"` and `android:fullBackupContent="false"` prevent ADB backup theft or unauthorized Google Drive extraction of customer database. | ✅ **SECURE** |
| **M7: Insufficient Binary Protections** | App cloning, exposed components | Only `MainActivity` is exported with `LAUNCHER` intent filter. Zero unexported activities, broadcast receivers, or content providers exposed. | ✅ **SECURE** |
| **M8: Security Misconfiguration** | Debug flags, permissive schemes | Explicit URL schemes and package queries restricted strictly to WhatsApp (`com.whatsapp`, `com.whatsapp.w4b`). | ✅ **SECURE** |
| **M9: Insecure Data Storage** | World-readable files, caches | SQLite database stored in internal app-sandboxed directory (`getDatabasesPath()`), accessible only to the app UID. | ✅ **SECURE** |
| **M10: Insufficient Cryptography** | Weak algorithms | No custom or deprecated cryptographic algorithms used. Standard system TLS utilized when delegating to system share sheet. | ✅ **SECURE** |

---

## 🔍 Detailed Vulnerability Findings & Fixes

### 1. SQL Injection Assessment
- **Assessment**: Checked `lib/core/database/database_helper.dart` across all CRUD methods (`getAllCustomers`, `getRoomsByCustomerId`, `getWindowsByRoomId`, `getMaterialsByCustomerId`, `updateCustomer`, `deleteCustomer`).
- **Result**: All statements use parameterized placeholders (`?`) and `whereArgs`.
  ```dart
  // Example of safe parameterized query in DatabaseHelper:
  where: 'name LIKE ? OR phone LIKE ?',
  whereArgs: ['%$searchQuery%', '%$searchQuery%']
  ```
- **Verdict**: **PASSED (No SQL Injection Possible)**.

---

### 2. Path Traversal & PDF Generation Safety
- **Assessment**: Checked file writing routines in `lib/core/utils/pdf_invoice_generator.dart`.
- **Finding**: If a customer name contained `../../` or malicious path characters, it could theoretically write outside the documents directory.
- **Fix Applied**: Customer names are strictly sanitized:
  ```dart
  final sanitizedCustomerName = estimate.customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final fileName = 'Invisible_Grills_${sanitizedCustomerName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  ```
- **Verdict**: **PASSED (Path traversal impossible)**.

---

### 3. Formula Injection Guard (CSV / Spreadsheet Export)
- **Assessment**: Ingestion or opening of customer/estimate data in external spreadsheet tools (Excel, Google Sheets) could trigger dynamic command execution if cells start with `=`, `+`, `-`, or `@`.
- **Fix Applied**: Implemented `UnitConverter.sanitizeFormulaInjection()` to prefix any formula-triggering characters with a single apostrophe.
- **Verdict**: **PASSED**.

---

### 4. Android Platform Hardening (`AndroidManifest.xml`)
- **Backup Shield**: `android:allowBackup="false"` and `android:fullBackupContent="false"` ensure that SQLite customer databases cannot be extracted via `adb backup` or unsanctioned cloud backup images.
- **Network Security**: `android:usesCleartextTraffic="false"` prevents accidental cleartext HTTP traffic.
- **Component Exposure Guard**: No background services or activities are exported to third-party applications.
- **Verdict**: **PASSED**.

---

## 📋 Security Verification Checklist

- [x] Zero hardcoded secrets, API keys, or private tokens in source code.
- [x] All SQLite operations use parameterized queries.
- [x] Android backup disabled to protect local customer records.
- [x] Cleartext traffic disabled.
- [x] Input sanitization on dimension calculations (negative/zero bounds checking).
- [x] Path traversal prevention in PDF generator.
- [x] Formula injection prevention on text fields.
- [x] `.gitignore` hardened against tracking large binaries (`*.apk`, `*.aab`, `*.zip`, `*.db`).
- [x] Codebase passed `flutter analyze` with 0 errors.
