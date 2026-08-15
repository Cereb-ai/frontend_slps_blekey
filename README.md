<!-- 面向 AI agent 的操作指令文件。根文件建议 60 行以内（无实时通道）/ 80 行以内（含 §6）（软目标）。 顶部为服务背景；--- 后为操作指令。 详细内容拆分到同仓 AGENTS.md（不新建子页面）。 -->

# frontend_slps_blekey

`frontend_slps_blekey` 是 SLPS 项目的 Flutter 蓝牙钥匙 App（移动端 + 桌面 + Web ），通过 `dio` 调用 backend-project-slps REST 完成锁/钥匙管理、授权任务，通过 `flutter_blekey_sdk` 与 BLE 硬件钥匙实时通信完成配钥、采集锁号、远程开锁。

* ✅ 负责：App 端锁/钥匙 CRUD UI、`flutter_blekey_sdk` 扫描/连接/读 key info/采集 lockId 流程、远程开锁、授权任务（clearance / sequential unlock）界面、本地缓存
* ❌ 不负责：SLPS 后端契约（backend-project-slps）、BLE SDK 内部实现（flutter_blekey_sdk 本地依赖）

⚠ 症状速查：白屏 → `lib/main.dart` `runZonedGuarded` + `global_error_store`；401 循环 → `lib/api.dart` InterceptorsWrapper Bearer + `/v3/auth/refresh`；BLE `code=-4117` → `adb logcat -s FlutterBlekeySdk` 对比 `connectToKey` `secret/sign/lic`；离线不刷新 → `lib/services/offline_data_store.dart` `debugPrint` 同步日志

依赖的后端服务：* `backend-project-slps` — REST（`/v3/auth/*` + `/slps/*`）+ dio InterceptorsWrapper 注入 `Authorization: Bearer <accessToken>` + `X-Tenant-Id: smart-lock-platform`（实证 `lib/api.dart`）

消费方：终端用户 — Android / iOS / 桌面 / Web 浏览器直接访问

> ⚠ 前端是消费方 + 终端，**不存在服务间调用关系**：终端用户不是「调用方」；「依赖的后端服务」是唯一外部依赖方向。不写「调用方/被调方」段。

背景文档：[AGENTS.md](AGENTS.md) + [docs/api(1).md](docs/api(1).md) 🔗 鉴权/SDK：`flutter_blekey_sdk`（`pubspec.yaml` path 依赖）


---

## 1. Agent 快速介入

前置条件：Flutter SDK ≥ 3.12.1（`pubspec.yaml` `environment.sdk`）；本地依赖 `flutter_blekey_sdk`（path 写死 `pubspec.yaml`，团队需同步调整）；运行时 env **无**（`_baseUrl` / `_tenantId` 硬编 `lib/api.dart`）

启动： `flutter pub get` → `flutter run`

最小验证：`flutter test`（`test/` 含 `offline_access_decision_test.dart` + `widget_test.dart`）+ `flutter analyze`（`analysis_options.yaml`）

入口锚点：入口 `lib/main.dart` ｜路由 `lib/routes.dart`（`onGenerateRoute` 在 `lib/app.dart`）｜状态 `lib/providers.dart` + `lib/states/`（`provider`/`ChangeNotifier`）｜视图 `lib/screens/`（`ble_key` / `clearance` / `home` / `login` / `tasks`）｜API `lib/api.dart`（dio 双实例 + interceptor 刷新）｜本地服务 `lib/services/`｜构建 `pubspec.yaml` + `analysis_options.yaml`（无 Dockerfile / 无 helm chart）

## 2. Playbooks（全文见同仓 AGENTS.md）

Playbook A BLE 钥匙扫描 → 连接 → 读 key info｜B 锁 SDK 采集 lockId 流程｜C 远程开锁 (online switch lock)｜D adb logcat 排查 BLE 报错

⚠ 时效性前置框： ls 确认路径 → grep 符号名 → 历史 PR/ticket 只作背景 ❌ 禁止引用历史 PR 号/已删分支

## 3. Guardrails（完整规则见同仓 AGENTS.md）

> NEVER = 技术红线；ASK = 执行前必须人工确认；ALWAYS = 每次操作必须遵守。

* NEVER：硬编 `_baseUrl` / `_tenantId` 后不 rebuild｜SDK `secret/sign/lic` 改后不重新扫设备
* ASK：涉及 `routes.dart` 路由表变更｜`api.dart` interceptor 鉴权逻辑变更｜`providers.dart` 列表变更
* ALWAYS：env 硬编字段变更后 `flutter build` + 装机验证｜`adb logcat -s FlutterBlekeySdk,FlutterBlekeyApp` 排错先清空再复现｜跨端 API 改动同步 `backend-project-slps` + `frontend-project-slps`

## 4. 环境依赖事实表

> Flutter 移动 App，**不属于模板「静态托管 / 容器化 ArgoCD」二选一形态**（无 Dockerfile / 无 helm chart / 不部署 GCS）。**移动端无运行时 env 机制**，以下字段改源后必须 rebuild：

| 字段 | 当前值 | 说明 |
|-----|-----|-----|
| `lib/api.dart` `_baseUrl` | `https://dev-api.cereb.ai` | REST 入口，改源后 rebuild |
| `lib/api.dart` `_tenantId` | `smart-lock-platform` | `X-Tenant-Id` 头 |
| `lib/api.dart` `connectTimeout` | 15s | dio |
| `pubspec.yaml` `flutter_blekey_sdk` | path 依赖（本地） | 团队需同步改 path |

## 5. 依赖的后端 API

权威契约 → `backend-project-slps` README §5。

| 后端服务 | 调用入口文件 | 鉴权注入方式 |
|------|--------|--------|
| `backend-project-slps` (`/v3/auth/*` + `/slps/*`) | `lib/api.dart` 双 dio 实例 | dio InterceptorsWrapper 注入 `Authorization: Bearer <accessToken>` + `X-Tenant-Id`；401 → `/v3/auth/refresh` 重试一次；refresh 失败回调 `_onUnauthorized` 跳登录 |

## 6. 实时通道

> 本服务无 WebSocket / SSE。BLE 走 `flutter_blekey_sdk` 原生 GATT（非 HTTP/WS 语义），不计入模板「实时通道」。事件流（`scan callback onScanning` / `connectToKey` / `onReport`）见 AGENTS.md。

## 7. 子页面索引

* Playbooks / Guardrails — 全文见同仓 [AGENTS.md](AGENTS.md)
* Reference — API 路径见 [docs/api(1).md](docs/api(1).md)，鉴权/BLE 细节见 [AGENTS.md](AGENTS.md)

## 8. 观测指引

构建产物：`flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` ｜ `flutter build ios` → `build/ios/iphoneos/Runner.app` ｜ `flutter build web` → `build/web/`（仅 dev 调试）

运行时排查：白屏 → `lib/main.dart` `runZonedGuarded` + `lib/states/global_error_store.dart` ｜ 401 循环 → `lib/api.dart` InterceptorsWrapper + `_handleError` 401 retry ｜ BLE `code=-4117` → `adb logcat -s FlutterBlekeySdk` 对比 `connectToKey` `secret/sign/lic` 与 `scan callback onScanning` `keyId/scanRecord` ｜ 离线不刷新 → `adb logcat -s FlutterBlekeyApp` grep `Offline sync`
