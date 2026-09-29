# frontend_demo_blekey

A new Flutter project.

## 关联项目

当前仓库与上一层目录中的以下仓库共同组成同一个 SLPS 项目：

- `../frontend-project-slps`：SLPS 前端项目。
- `../backend-project-slps`：SLPS 后端项目。
- `.`（`frontend_slps_blekey`）：SLPS Flutter 蓝牙钥匙 App，即当前仓库。

涉及共享 API、数据模型或端到端功能时，需要根据实际情况同步检查和协调这些仓库中的实现。

## App 端锁/钥匙添加编辑流程

目标：添加/编辑锁和钥匙时，优先通过 app 内的 `flutter_blekey_sdk` 采集真实设备信息，再调用 SLPS 后端保存平台记录。

### 新增钥匙

流程：

```text
扫描钥匙 -> 选择 MAC -> connectToKey -> readKeyInfo -> 回填 vendorKeyId/keyType -> 保存 /slps/keys
```

实现要点：

- 使用 `flutter_blekey_sdk` 扫描附近蓝牙钥匙，用户选择目标 `mac`。
- 调用厂家 SDK `connectToKey` 时优先使用当前钥匙记录自己的 `secret`、数字类型 `sign` 和 `lic`；仅在尚未保存这些字段时使用测试页默认值。
- 连接成功后调用 `readKeyInfo`。
- 从 `readKeyInfo` 结果回填：
  - `vendorKeyId`: 钥匙厂商 ID，例如 `keyId` 或 `readKeyInfo.data.id`。
  - `keyType`: 根据设备能力映射，蓝牙钥匙为 `bluetooth`，指纹钥匙为 `fingerprint`，4G/屏显钥匙为 `cellular` 或 `display`。
  - `metadata.readKeyInfo`: 保存厂家 SDK 原始返回，方便排查。
- 用户确认名称、归属用户、状态以及连接参数后，调用 `POST /slps/keys`；`sign` 必须按数字发送并保留合法值 `0`，许可字段统一使用 `lic`，不使用旧别名 `license`。
- 编辑钥匙时，如果不重新读取硬件，保持 `vendorKeyId` 不变；平台字段及每把钥匙自己的 `secret`、`sign`、`lic` 通过 `PATCH /slps/keys/{id}` 更新。

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

## Android 蓝牙任务包与离线下载

契约：[Android App 蓝牙授权与离线任务下发](https://wiki.dev.cereb.ai/doc/slps-android-app-dk47B4UPxZ)。后端基线为 `a075112`。

- 钥匙控制页读取 `/slps/keys/{UUID}/current-task-package` 和钥匙详情 `currentTask`，验证实体钥匙 ID，按平台 `/provisioning/config` 的 `keyLocalTime` 校时。
- Online：使用任务包全部锁号和时间窗；每把锁用平台 UUID 调 `/access/decide`，时间为 UTC RFC3339。需要围栏时获取 GPS，并把定位精度纳入圆形围栏判定。任何失败均停止；SetUserKey 成功后调用 SetOnline，保持连接。
- Offline：只有离线任务才提供下载操作，写入 `isOnline=false`，不调用 SetOnline。校时、写入均须收到成功回调；随后保存任务 ID、版本、SHA-256 和下载时间，并断开连接。版本或载荷变化提示更新。
- 当前任务为 400/403/404 或网络失败时清除可执行状态。缓存用于展示和保存回执，不参与本地授权；删除旧顺序任务接口与页面。
- 实时及历史 CMD=10 记录使用相同的硬件字段生成事件 ID。沿用按钥匙持久化的补传队列，保留升级前待上传记录；不使用接收时间替代缺失硬件时间。仅在历史读取完整、全部上传成功、没有混入其他命令记录、没有新的实时报告且未进入在线模式时清除钥匙记录。失败保留队列和钥匙记录。
- “我的 → 钥匙任务与下载回执”展示服务端当前任务及本机下载回执；具体写入仍在钥匙控制页。

### SDK 与构建

SDK 源码、JBleKey.jar 和四种 ABI 库随仓库放在 `packages/flutter_blekey_sdk`，来源为本机实际使用的升级版 wrapper。App 使用仓库内相对路径，无需其他开发者目录。Kotlin 操作 6 显式接收 `lockIds`、`timeBlocks`、`isOnline`；操作 15 显式接收平台时间，缺失参数直接报错。厂商测试页调用这两个操作时也需传完整参数。

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

### 联调条件与硬件验收

配套后端修改位于独立工作目录 `../backend-slps-android-ble-task-safety`（分支 `fix/android-ble-task-safety`）：拒绝 Offline + geofence，并对 `source=android_app` 的相同 `vendorEventId` 用事务锁串行去重，重试返回原事件，无数据库迁移。后端未部署前，不能宣称断网重试可端到端去重。

真机需验证：断开 App 后授权锁在时间窗内可开关，非授权锁/日期外/时间窗外拒绝；重连补读、网络失败后重试；403/404 清空任务；校时和写入失败不记成功；新增钥匙 ReadKeyInfo 和新增锁 CMD=19 回归。服务端删除任务不能即时撤销已写入的离线授权。
