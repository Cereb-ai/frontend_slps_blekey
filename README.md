# frontend_demo_blekey

A new Flutter project.

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

插件 Android 日志 tag 固定为 `FlutterBlekeySdk`。连接手机后可以这样看厂家 SDK 调用链路：

```bash
adb logcat | grep FlutterBlekeySdk
```

如果想先清空旧日志再复现问题：

```bash
adb logcat -c
adb logcat | grep FlutterBlekeySdk
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
