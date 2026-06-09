# Agent Notes

## App SDK Provisioning Flows

When implementing app-side add/edit for locks and keys, use the in-app `flutter_blekey_sdk` flow before saving SLPS backend records.

### Add Key

```text
scan key -> select MAC -> connectToKey -> readKeyInfo -> fill vendorKeyId/keyType -> POST /slps/keys
```

Implementation notes:

- Scan with `flutter_blekey_sdk` and let the user select the target `mac`.
- Connect with `connectToKey` using the same `secret`, `sign`, and `lic` defaults used by the existing SDK test pages.
- After connection, call `readKeyInfo`.
- Fill `vendorKeyId` from the vendor key id in the SDK result, usually `readKeyInfo.data.id` or `keyId`.
- Map device capability to `keyType`: Bluetooth -> `bluetooth`, fingerprint -> `fingerprint`, 4G/cellular -> `cellular`, display key -> `display`.
- Preserve the raw SDK response in `metadata.readKeyInfo`.
- Save the platform record with `POST /slps/keys`.
- For edit, do not change the vendor id unless the hardware is re-read intentionally. Update platform fields with `PATCH /slps/keys/{id}`.

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
