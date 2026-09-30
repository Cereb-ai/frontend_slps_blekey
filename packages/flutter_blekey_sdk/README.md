# flutter_blekey_sdk_upgraded

A new Flutter plugin project.

## ADB 日志监测

插件 Android 日志 tag 固定为 `FlutterBlekeySdk`。

| Tag                | 来源                    | 内容                                     |
| ------------------ | ----------------------- | ---------------------------------------- |
| `FlutterBlekeySdk` | SDK 原生 Kotlin         | BLE 指令、扫描回调、连接状态             |
| `FlutterBlekeyApp` | App Dart 层（api.dart） | HTTP 请求体/响应体、Token 刷新、错误详情 |

```bash
# 同时看两边（推荐）
adb logcat | grep FlutterBlekey

# 只看 SDK 原生
adb logcat -s FlutterBlekeySdk

# 只看 App Dart
adb logcat -s FlutterBlekeyApp

# 清空旧日志后再复现
adb logcat -c && adb logcat | grep FlutterBlekey
```

重点关注的 SDK 日志行：

- `method in/out` — Flutter 调插件的入口和返回。
- `sdk call in/out` — 插件调用厂家 SDK 的入口和返回。
- `scan callback onScanning` — 扫描到的设备，含 `name`、`mac`、`keyId`、`rssi`。
- `sdk call in connectToKey` — 连接参数，含完整 `mac`、`secret`、`sign`、`lic`。
- `sdk callback ConnectKey` — 连接回调，重点看 `ret`、`code`、`msg`。

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## App task package operations

This vendored wrapper includes the actual `executeOperation` implementation used by the Android app. Keep vendor binaries with this package.

- Operation 6 (`SetUserKey`) requires `lockIds: List<String>`, `timeBlocks: List<Map>` with `from`, `to`, and `times[{from,to}]`, and explicit `isOnline: bool`. It preserves all server windows and rejects missing fields. It no longer creates a seven-day default grant.
- Operation 15 (`SetDateTime`) requires `time: "yyyy-MM-dd HH:mm:ss"` from the platform provisioning config. Date components represent the platform local clock.
- Operation 4 uses `clearAfterRead` (default `false`), the vendor clear-after-read flag, not a pagination switch. The app always passes `false`. It emits `ReadKeyRecords` pages followed by `ReadKeyRecordsComplete`; operation 5 clears all device records. Only clear after every supported record has been uploaded, and preserve mixed/partial batches.
- `RecordBean.total` counts packets; validate unique contiguous `index` values, not record count. Missing or duplicate packets prevent clearing.
- Logs contain operation names and return codes; credential arguments and callback payloads are omitted.
- Method return only acknowledges dispatch. Wait for the matching operation callback and require `ret=true` for success.
