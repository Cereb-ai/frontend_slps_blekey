# Agent Notes

## Related Projects

This repository is part of the same SLPS project as the following sibling repositories in the parent directory:

- `../frontend-project-slps`: SLPS frontend project.
- `../backend-project-slps`: SLPS backend project.
- `.` (`frontend_slps_blekey`): SLPS Flutter BLE key app (this repository).

When a task involves shared APIs, data models, or end-to-end behavior, inspect and coordinate changes across these repositories as needed.

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
