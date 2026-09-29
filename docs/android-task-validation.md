# Android 蓝牙任务包改造验证

## 范围

依据 [当前 Wiki 契约](https://wiki.dev.cereb.ai/doc/slps-android-app-dk47B4UPxZ)，对照后端 `origin/dev a075112`。修改留在本地，未创建 PR、未部署。

App 改为服务端任务包授权，取消网络失败后本地放行；新增离线硬件写入、回执和版本提示；SDK 源码及厂商依赖放入仓库；删除旧任务 API 和顺序任务页面。联签任务继续使用原有 clearance 页面。

## 自动验证

| 检查 | 结果 |
|---|---|
| `flutter analyze` | PASS，无问题 |
| `flutter test` | PASS，24 项 |
| 后端临时数据库 `go test ./...` | PASS，包含全部 migration 与 16 路并发事件去重 |
| 旧 API / 本地授权路径检索 | `lib/` 中无 `/slps/tasks`、`sequential-unlock-tasks`、`decideOfflineAccess`、旧 `task['timeBlock']` |
| `git diff --check` | PASS |
| Android `./gradlew assembleDebug --offline --console=plain` | PASS，包含最新 Kotlin wrapper 和 Dart 改动 |

测试覆盖：任务包模式/时间字段校验、全部锁号和多个时间窗保留、SDK 确认前不进入 Online、页面关闭中止后续写入、各步骤失败阻止继续、硬件 ID 不匹配、回执版本/载荷变化、历史批次不完整不清除、硬件记录稳定 ID、缺失时间拒绝、非 CMD=10 拒绝、JWT/tenant/platform UUID、UTC 时间序列化。

SDK `Result(int)` 的字节码确认：非负 SDK 返回值会设置 `ret=true`；App 因此以 `ret` 判断回调成功，避免 `ret=false,code=0` 被错误放行。

仓库说明中的 `/verify` 技能在当前可用技能和本地技能目录中均未找到，本次直接执行上述验证。未提交代码，因此尚未进入提交前 `/code-review` 阶段。

## 配套后端

工作目录：`../backend-slps-android-ble-task-safety`，分支 `fix/android-ble-task-safety`。原 `backend-project-slps` 分支及原升级 SDK 的未提交改动保持原样。

- 创建/修改时拒绝离线与手机定位同时开启；已有不安全任务的 BLE 包返回 403。
- `android_app` 事件按 tenant/source/vendorEventId 事务串行去重，重复请求返回同一个事件。不新增数据库迁移。
- 测试数据库仅绑定本机，验证结束后已停止。

## 尚需真机确认

ADB 当前无设备连接，以下均未验收：

- 手机/App 断开后，授权钥匙在日期和每日窗口内开关授权锁；范围外拒绝。
- 实际 SDK 校时、写任务、连接/断开回调及记录页格式。
- 离线操作后重连补读；断网重试；重复补读不重复入库（需先部署配套后端）。
- 403/404 的现场权限场景，新增钥匙扫描/读取和新增锁 CMD=19 回归。

已有离线任务不能通过服务端删除立即撤销；必须重新连接覆盖或等待硬件任务过期。包含其他命令的混合历史批次保留在钥匙上，避免清除尚未处理的 CMD=19 等记录。

## 测试 APK

路径：`build/app/outputs/flutter-apk/app-debug.apk`，Debug 构建，使用现有 dev API。

SHA-256：`cacb7b9a14c03e29c3e922cdf11aaaab8670876d630fb2c4caa779c89d3d41b2`。

首次在线构建遇到 Maven 依赖下载等待，使用临时 Gradle repository filter 跳过 Google 仓库中的 Kotlin 包查询后下载成功；最终构建使用标准仓库配置及已下载缓存执行 `assembleDebug --offline`，无仓库镜像配置改动。
