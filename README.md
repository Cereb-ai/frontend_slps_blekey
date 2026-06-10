# frontend_demo_blekey

A new Flutter project.

## App 端锁/钥匙添加编辑流程

目标：添加/编辑锁和钥匙时，优先通过 app 内的 `flutter_blekey_sdk` 采集真实设备信息，再调用 SLPS 后端保存平台记录。

### 新增钥匙

流程：

```text
扫描钥匙 -> 选择 MAC -> connectToKey -> readKeyInfo -> 回填 vendorKeyId/keyType -> 保存 /slps/keys
```

实现要点：

- 使用 `flutter_blekey_sdk` 扫描附近蓝牙钥匙，用户选择目标 `mac`。
- 调用厂家 SDK `connectToKey`，连接参数沿用测试页当前默认值：`secret`、`sign`、`lic`。
- 连接成功后调用 `readKeyInfo`。
- 从 `readKeyInfo` 结果回填：
  - `vendorKeyId`: 钥匙厂商 ID，例如 `keyId` 或 `readKeyInfo.data.id`。
  - `keyType`: 根据设备能力映射，蓝牙钥匙为 `bluetooth`，指纹钥匙为 `fingerprint`，4G/屏显钥匙为 `cellular` 或 `display`。
  - `metadata.readKeyInfo`: 保存厂家 SDK 原始返回，方便排查。
- 用户确认名称、归属用户、状态后，调用 `POST /slps/keys`。
- 编辑钥匙时，如果不重新读取硬件，只允许编辑平台字段：`name`、`keyType`、`assignedUserId`、`ownerUserId`、`status`、`metadata`，并调用 `PATCH /slps/keys/{id}`。

### 新增锁

流程：

```text
扫描钥匙 -> connectToKey -> setReadLockIdKey -> 用户拿钥匙碰锁 -> 从 onReport 拿 lockId -> 保存 /slps/locks
```

实现要点：

- 使用 `flutter_blekey_sdk` 扫描并选择一把可用于采集锁号的钥匙。
- 调用 `connectToKey` 连接钥匙。
- 调用 `setReadLockIdKey`，把钥匙设置成采集锁号模式。
- 提示用户拿钥匙去碰目标锁。
- 监听 SDK `onReport`/`operationResult` 事件，从 CMD=19 的采集锁号记录中取 `lockId`。
- 回填：
  - `vendorLockId`: 采集到的锁号。
  - `metadata.readLockId`: 保存厂家 SDK 原始事件。
  - `metadata.provisioningFlow`: `app_lock_create`。
- 用户确认锁名称、位置等平台字段后，调用 `POST /slps/locks`。
- 编辑锁时，厂商锁号 `vendorLockId` 不可修改；只更新平台字段和 metadata，调用 `PATCH /slps/locks/{id}`。

### 当前实现状态

- 已完成：app 端锁/钥匙列表的后端 CRUD：`POST/PATCH/DELETE /slps/keys` 和 `POST/PATCH/DELETE /slps/locks`。
- 待完成：把上面的 SDK 扫描、连接、读取、采集流程嵌入新增/编辑弹窗。目前 SDK 仍主要在厂家测试页和在线开锁测试页中使用。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## ADB 日志监测

| Tag                | 来源            | 内容                                     |
| ------------------ | --------------- | ---------------------------------------- |
| `FlutterBlekeySdk` | SDK 原生 Kotlin | BLE 指令、扫描回调、连接状态             |
| `FlutterBlekeyApp` | App Dart 层     | HTTP 请求体/响应体、Token 刷新、错误详情 |

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

重点看这些日志：

- `method in/out`：Flutter 调插件的入口和返回。
- `sdk call in/out`：插件调用厂家 SDK 的入口和返回。
- `scan callback onScanning`：扫描到的设备，包含 `name`、`mac`、`key`、`keyId`、`scanRecord`、`rssi`。
- `sdk call in connectToKey`：连接参数，包含完整 `mac`、`secret`、`sign`、`lic`。
- `sdk callback ConnectKey`：厂家 SDK 连接回调，重点看 `ret`、`code`、`msg`。

例如遇到 `code=-4117, msg=device sign failure` 时，先对比：

- APK 是否是当前 build 出来的包。
- `connectToKey` 里的 `secret/sign/lic` 是否和文档或厂家给的一致。
- 扫描日志里的 `keyId`、`scanRecord` 是否和同事现场扫到的数据一致。
