# 锁服务 API 文档

业务 API 没有版本号。对外通过 v3 ingress 暴露时统一使用项目路径前缀：

```text
/slps
```

前端实际调用：

```http
GET /slps/locks
POST /slps/access/decide
```

Traefik 会 strip 掉 `/slps`，后端实际收到：

```http
GET /locks
POST /access/decide
```

## 鉴权

业务 API 由 v3 auth-center forward-auth middleware 保护。前端和 Android App 应使用 v3 登录 token 调用 `/slps/*`，不要手动伪造鉴权 header。

forward-auth 注入给后端的 header：

- `X-Auth-User`
- `X-Auth-Tenant`
- `X-Auth-Roles`
- `X-Auth-Permissions`

`createdBy` 返回的是 auth-center 用户 ID。前端如果要显示邮箱/姓名，应调用 auth-center 用户列表做映射：

```http
GET /v3/auth/users/?page=1&size=100
```

4G Java sidecar 使用厂商兼容路径 `/api/v1/ekserver/*`，通过 header `token` 鉴权。

## 通用约定

- 外部路径示例使用 `/slps/*`。
- 本服务内部文档里的 `/locks`、`/keys` 等均指 strip prefix 后的后端路径。
- `id` 是后端 UUID，用于 SLPS API 关联。
- `vendorLockId` / `vendorKeyId` 是厂商出厂 ID，用于 USB/蓝牙/4G SDK。
- 空列表返回 `[]`，不会返回 `null`。

## 健康检查

```http
GET /slps/healthz
GET /slps/readyz
```

## 看板统计

权限：

- `lock:insights:read`

```http
GET /slps/insights/summary
```

返回：

```json
{
  "lockCount": 12,
  "keyCount": 5,
  "todayOperationCount": 18,
  "historyOperationCount": 1042,
  "generatedAt": "2026-06-09T12:00:00Z"
}
```

Insight 页面下钻复用普通模块接口：

- 锁/地址列表：`GET /slps/locks`
- 钥匙列表：`GET /slps/keys`
- 最近开关锁记录：`GET /slps/events?operationOnly=true&limit=50`
- 最近任务记录：`GET /slps/authorization-tasks`

## 锁设备

权限：

- 读取：`lock:devices:read`
- 管理：`lock:devices:manage`

```http
GET /slps/locks
GET /slps/locks/{id}
```

列表和详情会带最近一条事件：

```json
{
  "id": "3970036e-ffb9-4b1a-8c78-be80c13c8a65",
  "tenantId": "smart-lock-platform",
  "vendorLockId": "202606050001",
  "name": "Main Gate Lock",
  "status": "installed",
  "metadata": {},
  "createdBy": "usr_e450bf4efa20dbe2",
  "latestEvent": {
    "id": "0bd7cf26-8088-42aa-969d-05b29268a43a",
    "source": "android_app_demo",
    "vendorEventId": "demo-latest-1781003559",
    "lockId": "3970036e-ffb9-4b1a-8c78-be80c13c8a65",
    "keyId": "fb413bad-423e-4270-816c-21654d1471e5",
    "vendorLockId": "202606050001",
    "vendorKeyId": "202606050001",
    "command": 10,
    "eventTime": "2026-06-09T11:12:36Z",
    "result": "success"
  },
  "createdAt": "2026-06-09T10:36:48.106253Z",
  "updatedAt": "2026-06-09T10:36:48.106253Z"
}
```

添加锁：

```http
POST /slps/locks
Content-Type: application/json

{
  "vendorLockId": "202606050001",
  "name": "Main Gate Lock",
  "assetId": "asset-001",
  "siteId": null,
  "metadata": {
    "provisioningFlow": "usb_lock_create",
    "readLockId": {
      "cmd": "ReadLockId",
      "data": {
        "id": "202606050001",
        "dir": 0
      },
      "result": 12,
      "message": ""
    }
  }
}
```

说明：

- `vendorLockId` 是 USB/钥匙采集到的厂商锁号。
- `id` 是后端生成 UUID，创建授权任务时使用这个 UUID。
- `createdBy` 自动来自当前登录用户。
- 锁状态：`uninstalled` 未安装，`installed` 已安装，`damaged` 损坏，`lost` 丢失。

部分更新锁：

```http
PATCH /slps/locks/{id}
Content-Type: application/json

{
  "name": "Main Gate Lock",
  "status": "damaged",
  "assetId": "asset-001",
  "metadata": {}
}
```

说明：

- 只更新传入字段。
- 状态字段也走这个接口即可；`PATCH /slps/locks/{id}/status` 保留兼容。
- 删除锁：`DELETE /slps/locks/{id}`，软删除，返回 204。

## 数字钥匙

权限：

- 读取：`lock:keys:read`
- 管理：`lock:keys:manage`

```http
GET /slps/keys
GET /slps/keys/{id}
```

列表和详情会带最近一条事件：

```json
{
  "id": "fb413bad-423e-4270-816c-21654d1471e5",
  "tenantId": "smart-lock-platform",
  "vendorKeyId": "202606050001",
  "keyType": "standard",
  "name": "BLE Key 202606050001",
  "status": "active",
  "metadata": {
    "readKeyInfo": {
      "data": {
        "id": "202606050001",
        "type": 1,
        "typeex": 2,
        "multitask": false,
        "taskCount": 0,
        "taskEnabled": false
      }
    }
  },
  "createdBy": "usr_e450bf4efa20dbe2",
  "latestEvent": {
    "id": "0bd7cf26-8088-42aa-969d-05b29268a43a",
    "source": "android_app_demo",
    "command": 10,
    "eventTime": "2026-06-09T11:12:36Z",
    "result": "success"
  },
  "createdAt": "2026-06-09T10:34:50.342448Z",
  "updatedAt": "2026-06-09T10:34:50.342448Z"
}
```

添加钥匙：

```http
POST /slps/keys
Content-Type: application/json

{
  "vendorKeyId": "202606050001",
  "keyType": "standard",
  "name": "BLE Key 202606050001",
  "assignedUserId": "",
  "ownerUserId": "",
  "metadata": {
    "provisioningFlow": "usb_key_create",
    "readKeyInfo": {
      "cmd": "ReadKeyInfo",
      "data": {
        "id": "202606050001",
        "type": 1,
        "typeex": 2,
        "multitask": false,
        "power": 100
      },
      "result": 16,
      "message": ""
    }
  }
}
```

说明：

- `vendorKeyId` 是厂商钥匙 ID。
- `assignedUserId` / `ownerUserId` 只是业务归属信息，不代表开锁权限。
- 开锁权限只由授权任务决定。
- `metadata.readKeyInfo.data.multitask=false` 表示单任务钥匙。对 `auto` / `4g_remote` 任务，后端会限制同一把钥匙只能有一个 active remote task。
- 钥匙状态：`active` 正常，`damaged` 损坏，`lost` 丢失。

部分更新钥匙：

```http
PATCH /slps/keys/{id}
Content-Type: application/json

{
  "name": "BLE Key 202606050001",
  "keyType": "standard",
  "assignedUserId": "user-id-from-auth-center",
  "ownerUserId": "user-id-from-auth-center",
  "status": "lost",
  "metadata": {}
}
```

说明：

- 只更新传入字段。
- 状态字段也走这个接口即可；`PATCH /slps/keys/{id}/status` 保留兼容。
- 删除钥匙：`DELETE /slps/keys/{id}`，软删除，返回 204。

修改钥匙归属：

```http
PATCH /slps/keys/{id}/assignment
Content-Type: application/json

{
  "assignedUserId": "user-id-from-auth-center",
  "ownerUserId": "user-id-from-auth-center"
}
```

## 授权任务

授权任务是当前系统唯一的授权来源。任务描述谁可以在什么日期、什么每日时间段、什么位置，用哪些钥匙打开哪些锁。

权限：

- 读取：`lock:tasks:read`
- 管理：`lock:tasks:manage`
- 审核：`lock:tasks:review`

```http
GET /slps/authorization-tasks
GET /slps/authorization-tasks?status=pending
```

新建授权任务：

```http
POST /slps/authorization-tasks
Content-Type: application/json

{
  "name": "Mexico Site Weekday Access",
  "description": "Prototype access task",
  "userScope": "selected",
  "userIds": ["user-id-1", "user-id-2"],
  "groupIds": [],
  "keyIds": ["digital-key-uuid"],
  "lockScope": "selected",
  "lockIds": ["lock-device-uuid-1", "lock-device-uuid-2"],
  "timeBlock": {
    "from": "2026-06-09",
    "to": "2026-06-16",
    "times": [
      {
        "from": "09:00:00",
        "to": "18:30:00"
      }
    ]
  },
  "geofenceRequired": true,
  "geofence": {
    "type": "circle",
    "name": "Yuehai Men Center, Nanshan, Shenzhen",
    "latitude": 22.5408,
    "longitude": 113.9343,
    "radiusMeters": 5000
  },
  "offlineAccessAllowed": false,
  "metadata": {}
}
```

字段说明：

- `userScope`: `all` 或 `selected`
- `lockScope`: `all` 或 `selected`
- `syncMode`: 后端根据钥匙类型自动推导。蓝牙钥匙返回 `bluetooth_phone`，4G/remote 钥匙返回 `4g_remote`。前端创建任务时可以不传。
- `timeBlock`: 单个授权时间块，不是数组。
- `timeBlock.from` / `timeBlock.to`: 授权日期范围，格式 `yyyy-MM-dd`。
- `timeBlock.times`: 当前必须且只能包含一个每日时间段。
- `timeBlock.times[0].from` / `timeBlock.times[0].to`: 每日工作时间范围，格式 `HH:mm:ss`，也兼容 `HH:mm` 输入并在后端归一化成 `HH:mm:ss`。
- 每日时间窗按后端配置 `ACCESS_DECISION_TIMEZONE` 解释，默认 `Asia/Hong_Kong`。
- `geofenceRequired=false` 时可以不传 `geofence`，或传 `{}`。
- `geofenceRequired=true` 时建议使用圆形范围，包含 `latitude`、`longitude`、`radiusMeters`。
- 新建任务默认 `status=pending`。只有审核通过变成 `active` 后，才会参与手机开锁鉴权和 4G 任务下发。
- 筛选待审核任务：`GET /slps/authorization-tasks?status=pending`。

审核授权任务：

```http
PATCH /slps/authorization-tasks/{id}/review
Content-Type: application/json

{
  "decision": "approve",
  "note": "Reviewed for demo test"
}
```

说明：

- `decision`: 只允许 `approve` 或 `reject`。
- `approve` 后任务状态变为 `active`。
- `reject` 后任务状态变为 `rejected`。
- `note` 是管理员审核批注，可以为空。
- 返回任务会包含 `reviewedBy`、`reviewedAt`、`reviewNote`。
- 普通用户不配置 `lock:tasks:review`，调用会返回 403。

4G/auto 单任务限制：

- 如果钥匙 metadata 里 `multitask=false`，后端不允许同一把钥匙同时存在多个 active 的 `auto` / `4g_remote` 授权任务。
- `bluetooth_phone` 不受这个限制。
- 如果 metadata 里没有 multitask 字段，后端暂不限制，避免误拦旧数据。
- 当前兼容读取以下路径：
  - `metadata.multitask`
  - `metadata.readKeyInfo.multitask`
  - `metadata.readKeyInfo.data.multitask`

单任务冲突时返回：

```json
{
  "error": {
    "code": "bad_request",
    "message": "key digital-key-uuid does not support multitask and already has active remote task task-uuid (Task Name)"
  }
}
```

## 开锁前鉴权

Android App 在执行蓝牙开锁前调用。手机端负责拿定位并判断 geofence，然后把结果传给后端。后端基于 `authorization_tasks` 判断用户、钥匙、锁、日期范围、每日时间窗、GPS 要求和任务状态。

权限：

- `lock:tasks:evaluate`

```http
POST /slps/access/decide
Content-Type: application/json

{
  "keyId": "digital-key-uuid",
  "lockId": "lock-device-uuid",
  "at": "2026-06-10T10:00:00+08:00",
  "geofenceSatisfied": true,
  "clientTraceId": "optional-client-trace-id"
}
```

说明：

- `userId` 可不传，后端默认使用当前登录用户。
- `at` 可不传，后端默认使用当前时间。
- 如果任务 `geofenceRequired=true`，手机端必须先检查定位，并传 `geofenceSatisfied=true` 才能允许。
- 如果任务没有 GPS 要求，`geofenceSatisfied` 不影响结果。

允许：

```json
{
  "allowed": true,
  "taskId": "authorization-task-uuid"
}
```

拒绝示例：

```json
{
  "allowed": false,
  "taskId": "authorization-task-uuid",
  "reasons": [
    "outside task daily time window"
  ]
}
```

可能的 reason：

- `no active authorization task`
- `outside task date range`
- `outside task daily time window`
- `geofence not satisfied`

## 开关锁记录

权限：

- 读取：`lock:events:read`
- 管理：`lock:events:manage`

```http
GET /slps/events?limit=50
```

查询参数：

- `limit`: 默认 50，最大 200
- `operationOnly=true`: 只返回开关锁记录，厂商命令 `command=10`
- `lockId`: 按锁 UUID 过滤
- `keyId`: 按钥匙 UUID 过滤

示例：

```http
GET /slps/events?operationOnly=true&limit=50
GET /slps/events?lockId=lock-device-uuid&operationOnly=true
GET /slps/events?keyId=digital-key-uuid&operationOnly=true
```

上传事件：

```http
POST /slps/events
Content-Type: application/json

{
  "source": "android_app",
  "deviceId": "phone-or-key-id",
  "vendorEventId": "optional-vendor-event-id",
  "lockId": "lock-device-uuid",
  "keyId": "digital-key-uuid",
  "vendorLockId": "202606050001",
  "vendorKeyId": "202606050001",
  "command": 10,
  "flag": 0,
  "flag1": 1,
  "status": 1,
  "eventTime": "2026-06-09T10:31:00Z",
  "result": "success",
  "rawPayload": {
    "flow": "phone_gps_ble_key_unlock",
    "gps": {
      "latitude": 22.5408,
      "longitude": 113.9343,
      "radiusMeters": 5000
    }
  }
}
```

说明：

- Event 是开锁/关锁后的记录，不负责鉴权。
- Event 不需要配置 GPS fence，也不强制上传 GPS。
- 如果前端/App 想做审计，可以把实际 GPS 放在 `rawPayload.gps`。

## Provisioning 配置

Web portal 在 USB 添加锁/钥匙前调用。返回本地 USB WebSocket 地址、4G key server 地址和厂商默认参数。

权限：

- `lock:provisioning:read`

```http
GET /slps/provisioning/config
```

返回：

```json
{
  "usb": {
    "websocketUrl": "ws://127.0.0.1:50018",
    "serviceName": "Key2000CService"
  },
  "keyServer": {
    "host": "34.59.130.165",
    "port": 9951
  },
  "vendorDefaults": {
    "secret": "FFFFFFFFFFFFFFFFFFFF",
    "sign": 1,
    "lic": "FFFFFFFFFFFFFFFF"
  },
  "time": {
    "timezone": "Asia/Hong_Kong",
    "serverUtc": "2026-06-09T12:20:00Z",
    "keyLocalTime": "2026-06-09 20:20:00",
    "keyLocalDate": "2026-06-09",
    "keyLocalOffset": "+08:00"
  },
  "commands": {
    "initSdk": "InitSdk",
    "readKey": "ReadKeyInfo",
    "readLockId": "ReadLockId",
    "setHost": "SetHost",
    "setUserKey": "SetUserKey"
  }
}
```

前端使用 `keyServer.host` 和 `keyServer.port` 调厂商 USB SDK 的 `SetHost`，把 4G key server 写入钥匙。

前端同步钥匙时间时使用 `time.keyLocalTime`。锁/钥匙端不配置 timezone，只写入这个本地时间；后端根据 `time.timezone` 把任务的 `timeBlock` 输出成钥匙能识别的本地日期/时间。

## 4G Java Sidecar APIs

这些接口不是给前端直接调用的，是给同 Pod 内的 `EkServer.jar` sidecar 调用的。路径保留厂商兼容前缀 `/api/v1/ekserver`。

调用 header：

```http
token: <EKSERVER_TOKEN>
X-Tenant-ID: <tenant-id>
```

本地测试时，如果没有传 `X-Tenant-ID`，默认租户是 `default`。

接口：

```http
GET /api/v1/ekserver/users/{deviceId}/{taskType}
GET /api/v1/ekserver/tasks/{deviceId}/{taskType}
GET /api/v1/ekserver/tasks/callback/{deviceId}/{taskType}
POST /api/v1/ekserver/records/{deviceId}/{reportType}
GET /api/v1/ekserver/syscode/{deviceId}/{taskType}
GET /api/v1/ekserver/heartbeat/{deviceId}
```

用途：

- `/tasks`: sidecar 拉取 4G 钥匙的授权任务，数据来自 `authorization_tasks`。当前返回该钥匙最新 active 的 `auto` / `4g_remote` 任务。
- `/tasks/callback`: sidecar 通知任务同步回调。
- `/records`: sidecar 上传 4G 钥匙开关锁记录。
- `/syscode`: sidecar 获取系统码/secret。
- `/heartbeat`: 4G 钥匙或 sidecar 心跳。
- `/users`: 预留给指纹/人员数据下载，MVP 可以先空返回。

4G 任务返回示例：

```json
{
  "crypto": 0,
  "resultCode": 0,
  "msg": "success",
  "data": {
    "taskId": 123456,
    "lockIds": ["202606050001"],
    "timeBlocks": [
      {
        "from": "2026-06-09 00:00:00",
        "to": "2026-06-16 23:59:59",
        "times": [
          {
            "from": "09:00",
            "to": "18:30"
          }
        ]
      }
    ]
  }
}
```

记录上传示例：

```http
POST /api/v1/ekserver/records/202606050001/0
Content-Type: application/json
token: <EKSERVER_TOKEN>
X-Tenant-ID: smart-lock-platform

{
  "data": [
    {
      "cmd": 10,
      "flag": 0,
      "lockid": "202606050001",
      "time": "2026-06-09 10:31:00",
      "status": 0,
      "userids": "",
      "taskid": 1,
      "finger": 0,
      "flag1": 0,
      "keyid": "202606050001",
      "isevent": 1
    }
  ]
}
```
