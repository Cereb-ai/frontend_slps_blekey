# AI Agents Configuration

This document describes the AI agent configurations and usage patterns for the SLPS Flutter BLE key app.

## Project Overview

- **Project Name**: frontend_slps_blekey (SLPS Flutter BLE Key App)
- **Framework**: Flutter (Dart)
- **Related Repositories**:
  - `.` (`frontend_slps_blekey`): SLPS Flutter BLE key app (this repository)
  - `../frontend-project-slps`: SLPS frontend project
  - `../backend-project-slps`: SLPS backend project
  - `../flutter_blekey_sdk_upgraded`: Flutter BLE SDK (local dependency)

When a task involves shared APIs, data models, or end-to-end behavior, inspect and coordinate changes across these repositories as needed.

## Claude Code Configuration

### Preferred Agent Types

For this project, use the following agent types based on the task:

| Task Category | Recommended Agent Type |
|--------------|----------------------|
| Code exploration / understanding | `Explore` |
| Complex implementation tasks | `claude` |
| Architecture / planning | `Plan` |
| General research / multi-step tasks | `general-purpose` |
| Code reviews | `code-review` |

### Available Skills

Invoke these skills when relevant:

- `/init` - Initialize or update CLAUDE.md documentation
- `/review` - Review code changes
- `/code-review` - Review code for correctness and quality
- `/security-review` - Security-focused code review
- `/simplify` - Simplify and clean up code
- `/verify` - Verify changes work end-to-end
- `/run` - Launch and drive the app
- `/loop` - Run recurring tasks

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── providers/                # State management (Provider)
├── models/                   # Data models
├── services/                 # API and BLE services
├── screens/                  # UI screens
├── widgets/                  # Reusable widgets
├── utils/                    # Utility functions
└── constants/                # Constants and configs
```

## Common Tasks

### Getting Started

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk --release

# Run tests
flutter test
```

### ADB Log Monitoring

| Tag                | Source           | Content                                  |
| ------------------ | ---------------- | ---------------------------------------- |
| `FlutterBlekeySdk` | SDK Kotlin layer | BLE commands, scan callbacks, connection state |
| `FlutterBlekeyApp` | App Dart layer   | HTTP request/response, token refresh, errors |

```bash
# Watch both (recommended)
adb logcat | grep FlutterBlekey

# SDK only
adb logcat -s FlutterBlekeySdk

# App only
adb logcat -s FlutterBlekeyApp

# Clear logs first
adb logcat -c && adb logcat | grep FlutterBlekey
```

Key logs to watch:
- `method in/out`: Flutter plugin entry/return
- `sdk call in/out`: Vendor SDK calls
- `scan callback onScanning`: Scanned devices with name, mac, key, keyId
- `sdk call in connectToKey`: Connection params (mac, secret, sign, lic)
- `sdk callback ConnectKey`: Vendor SDK connection result (ret, code, msg)

## Key Dependencies

- **State Management**: provider
- **Network**: dio
- **BLE SDK**: flutter_blekey_sdk (local)
- **Permissions**: permission_handler
- **Location**: geolocator
- **Local Storage**: shared_preferences
- **Localization**: flutter_localizations, intl

## App SDK Provisioning Flows

When implementing app-side add/edit for locks and keys, use the in-app `flutter_blekey_sdk` flow before saving SLPS backend records.

### Add Key

```text
scan key -> select MAC -> connectToKey -> readKeyInfo -> fill vendorKeyId/keyType -> POST /slps/keys
```

Implementation notes:

- Scan with `flutter_blekey_sdk` and let the user select the target `mac`.
- Connect with `connectToKey` using the key record's `secret`, numeric `sign`, and `lic`; use the SDK test-page defaults only when the key has no stored connection parameters yet.
- After connection, call `readKeyInfo`.
- Fill `vendorKeyId` from the vendor key id in the SDK result, usually `readKeyInfo.data.id` or `keyId`.
- Map device capability to `keyType`: Bluetooth -> `bluetooth`, fingerprint -> `fingerprint`, 4G/cellular -> `cellular`, display key -> `display`.
- Preserve the raw SDK response in `metadata.readKeyInfo`.
- Save `secret`, numeric `sign` (including `0`), and `lic` as top-level key fields with `POST /slps/keys`; use `lic`, not the legacy `license` alias.
- For edit, do not change the vendor id unless the hardware is re-read intentionally. Update platform fields and per-key connection parameters with `PATCH /slps/keys/{id}`.

### Add Lock

```text
scan key -> connectToKey -> setReadLockIdKey -> user touches lock with key -> read lockId from onReport -> POST /slps/locks
```

Implementation notes:

- Scan and select a key that can collect lock ids.
- Connect with `connectToKey`.
- Call `setReadLockIdKey`.
- Prompt the user to touch the target lock with the key.
- Listen for SDK report/result events. The collected lock id should come from the CMD=19 lock-id collection record.
- Fill `vendorLockId` from the collected lock id.
- Preserve the raw SDK event in `metadata.readLockId`.
- Set `metadata.provisioningFlow` to `app_lock_create`.
- Save with `POST /slps/locks`.
- For edit, keep `vendorLockId` read-only. Update platform fields and metadata with `PATCH /slps/locks/{id}`.

### Current State

- Completed: backend CRUD in the app for keys and locks.
- Not yet completed: embedding the SDK scan/connect/read/collect flows directly into the add/edit sheets. SDK usage currently lives mostly in the vendor test and online switch-lock test screens.

## Related Documentation

- [README.md](README.md) - Main project documentation
- [pubspec.yaml](pubspec.yaml) - Flutter dependencies
- [analysis_options.yaml](analysis_options.yaml) - Linting rules

## Git Workflow

- Check git status and branches in the repository

## Notes for Agents

1. When working on features, coordinate with sibling repositories (frontend-project-slps, backend-project-slps)
2. Follow existing Dart/Flutter patterns in the codebase
3. Reference files using markdown link format: [filename.dart](lib/filename.dart)
4. For line numbers: [filename.dart:42](lib/filename.dart#L42)
5. Before making significant changes, explore the codebase first to understand existing patterns
6. Use the `/verify` skill after implementing features to ensure they work end-to-end
7. Use the `/code-review` skill before committing nontrivial changes
8. When debugging BLE issues, use ADB logcat with FlutterBlekey tag filtering
