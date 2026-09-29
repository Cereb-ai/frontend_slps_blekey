package com.cereb.flutter_blekey_sdk

import android.content.Context
import android.util.Log
import com.x4a574d.blekey.BleKeySdk
import com.x4a574d.blekey.bean.DateSection
import com.x4a574d.blekey.bean.KeyInfo
import com.x4a574d.blekey.bean.RecordBean
import com.x4a574d.blekey.bean.RecordInfo
import com.x4a574d.blekey.bean.RegisterKeyInfo
import com.x4a574d.blekey.bean.Result as BleKeyResult
import com.x4a574d.blekey.bean.SecretInfo
import com.x4a574d.blekey.bean.Task
import com.x4a574d.blekey.bean.TaskLockInfo
import com.x4a574d.blekey.bean.TaskUser
import com.x4a574d.blekey.bean.TimeSection
import com.x4a574d.blekey.bean.UserKeyInfo
import com.x4a574d.blekey.callback.BleKeyCallback
import com.x4a574d.bletools.callback.BleScanCallback
import com.x4a574d.bletools.data.BleDevice
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.reflect.Array
import java.lang.reflect.Modifier
import java.text.SimpleDateFormat
import java.text.ParsePosition
import java.util.Locale
import java.util.Calendar
import java.util.Date
import java.util.IdentityHashMap

/** FlutterBlekeySdkPlugin */
class FlutterBlekeySdkPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private companion object {
    const val TAG = "FlutterBlekeySdk"
    const val DEFAULT_SECRET = "FFFFFFFFFFFFFFFFFFFF"
    const val DEFAULT_LIC = "FFFFFFFFFFFFFFFF"
    const val DEFAULT_NEW_SECRET = "8E8A57AF9FC85EAEEC02"
    const val DEFAULT_USER_KEY_LOCK_IDS = "202307151005,202307150990,202401270221"
    const val DEFAULT_MULTI_TIME_LOCK_IDS = "202307150990"
    const val DEFAULT_TASK_LOCK_ID = "202309070002"
    const val DEFAULT_FINGERPRINT_FEATURE =
      "eJybHeWQxZOwa1HEUWOl3et+FfG+tNPZ96j5pv6BNXq5tYKnNZxnHX3fLnop8qNh6dOKm7nG1zjO5WhNnHcwSFDj47rXQRNj/ZwaPzirXzT3qzj98WVFf1DwrC1XnVWWTg+PPOtgr8/6z8wpvff5i4VTNpvdmnA4Y9e9H9/T7N/YnbB28JPtfJrU7mHimyZgWnfsXX7tkl4ZMZ9/lbIuDa+WL1XJOsIR9q+wTP/OBb6Gtls7ZTKz161altjlHTVx10U+x6MFx260d4k0r/aKl3dXqNVaJ71285uH9S8OKJqU6HiLDWL5UsPKJ30neO+J1STVq3IUMvJyDaT9DAC21fH7"
  }

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var appContext: Context
  private var eventSink: EventChannel.EventSink? = null
  private var initialized = false

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    appContext = flutterPluginBinding.applicationContext
    Log.d(TAG, "plugin attached package=${appContext.packageName}")
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_blekey_sdk")
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_blekey_sdk/events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d(TAG, "method in method=${call.method} args=${call.arguments}")
    when (call.method) {
      "getPlatformVersion" -> {
        val version = "Android ${android.os.Build.VERSION.RELEASE}"
        Log.d(TAG, "method out method=${call.method} result=$version")
        result.success(version)
      }
      "init" -> {
        initSdk()
        Log.d(TAG, "method out method=${call.method} result=true")
        result.success(true)
      }
      "executeOperation" -> executeOperation(call, result)
      "getSdkVersions" -> {
        try {
          initSdk()
          val sdk = BleKeySdk.getInstance()
          val versions = mapOf("jar" to sdk.jarVersion, "so" to sdk.soVersion)
          Log.d(TAG, "method out method=${call.method} result=$versions")
          result.success(versions)
        } catch (error: Throwable) {
          Log.e(TAG, "method error method=${call.method} code=blekey_versions_failed message=${error.message}", error)
          result.error("blekey_versions_failed", error.message, null)
        }
      }
      "startScan" -> {
        val timeoutMs = call.argument<Int>("timeoutMs") ?: 10000
        try {
          initSdk()
          Log.d(TAG, "sdk call in stopScan before startScan")
          BleKeySdk.getInstance().stopScan()
          Log.d(TAG, "sdk call out stopScan before startScan")
          Log.d(TAG, "sdk call in startScan timeoutMs=$timeoutMs")
          BleKeySdk.getInstance().startScan(timeoutMs, scanCallback)
          Log.d(TAG, "sdk call out startScan timeoutMs=$timeoutMs")
          Log.d(TAG, "method out method=${call.method} result=true")
          result.success(true)
        } catch (error: Throwable) {
          Log.e(TAG, "method error method=${call.method} code=blekey_start_scan_failed message=${error.message}", error)
          result.error("blekey_start_scan_failed", error.message, null)
        }
      }
      "stopScan" -> {
        try {
          Log.d(TAG, "sdk call in stopScan")
          BleKeySdk.getInstance().stopScan()
          Log.d(TAG, "sdk call out stopScan")
          Log.d(TAG, "method out method=${call.method} result=true")
          result.success(true)
        } catch (error: Throwable) {
          Log.e(TAG, "method error method=${call.method} code=blekey_stop_scan_failed message=${error.message}", error)
          result.error("blekey_stop_scan_failed", error.message, null)
        }
      }
      else -> {
        Log.w(TAG, "method out method=${call.method} result=notImplemented args=${call.arguments}")
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(TAG, "plugin detached initialized=$initialized")
    try {
      if (initialized) {
        Log.d(TAG, "sdk call in stopScan on detach")
        BleKeySdk.getInstance().stopScan()
        Log.d(TAG, "sdk call out stopScan on detach")
        Log.d(TAG, "sdk call in destory")
        BleKeySdk.getInstance().destory()
        Log.d(TAG, "sdk call out destory")
      }
    } catch (_: Throwable) {
    }
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    eventSink = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    Log.d(TAG, "event listen args=$arguments")
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    Log.d(TAG, "event cancel args=$arguments")
    eventSink = null
  }

  private fun initSdk() {
    if (!initialized) {
      Log.d(TAG, "sdk call in initSdk package=${appContext.packageName}")
      BleKeySdk.getInstance().initSdk(appContext, bleKeyCallback)
      initialized = true
      Log.d(TAG, "sdk call out initSdk initialized=true")
    } else {
      Log.d(TAG, "sdk call in setBleKeyCallback")
      BleKeySdk.getInstance().setBleKeyCallback(bleKeyCallback)
      Log.d(TAG, "sdk call out setBleKeyCallback")
    }
  }

  private fun executeOperation(call: MethodCall, result: Result) {
    val index = call.argument<Int>("index")
    if (index == null) {
      Log.e(
        TAG,
        "operation error method=${call.method} code=blekey_missing_operation message=Missing operation index args=${call.arguments}",
      )
      result.error("blekey_missing_operation", "Missing operation index", null)
      return
    }

    try {
      initSdk()
      val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
      val mac = call.argument<String>("mac") ?: ""
      val sdk = BleKeySdk.getInstance()
      val from = Calendar.getInstance()
      val to = Calendar.getInstance()
      to.add(Calendar.DATE, 7)
      Log.d(
        TAG,
        "operation in index=$index name=${operationName(index)} mac=$mac args=${args.toSafeLogString()}",
      )

      when (index) {
        0 -> {
          val secret = stringArg(args, "secret", DEFAULT_SECRET)
          val sign = intArg(args, "sign", 0)
          val lic = stringArg(args, "lic", DEFAULT_LIC)
          Log.d(TAG, "sdk call in connectToKey mac=$mac secret=${secret.maskForLog()} sign=$sign lic=$lic")
          sdk.connectToKey(mac, secret, sign, lic)
          Log.d(TAG, "sdk call out connectToKey")
        }
        1 -> logSdkCall("disconnectFromKey") { sdk.disconnectFromKey() }
        2 -> logSdkCall("readKeyInfo") { sdk.readKeyInfo() }
        3 -> {
          val oldSecret = stringArg(args, "oldSecret", DEFAULT_SECRET)
          val newSecret = stringArg(args, "newSecret", DEFAULT_SECRET)
          Log.d(TAG, "sdk call in setKeySecret old=${oldSecret.maskForLog()} new=${newSecret.maskForLog()}")
          sdk.setKeySecret(SecretInfo(oldSecret, newSecret))
          Log.d(TAG, "sdk call out setKeySecret")
        }
        4 -> logSdkCall("readKeyRecords") { sdk.readKeyRecords(boolArg(args, "autoContinue", false)) }
        5 -> logSdkCall("clearRecords") { sdk.clearRecords() }
        6 -> logSdkCall("setUserKey") {
          val online = args["isOnline"] as? Boolean
            ?: throw IllegalArgumentException("isOnline is required")
          sdk.setUserKey(userKeyInfo(args), online)
        }
        7 -> logSdkCall("setOnline") { sdk.setOnline() }
        8 -> logSdkCall("setReadLockIdKey") { sdk.setReadLockIdKey() }
        9 -> logSdkCall("setRegisterKey newSecret=${stringArg(args, "newSecret", DEFAULT_NEW_SECRET).maskForLog()}") {
          sdk.setRegisterKey(
            from.time,
            to.time,
            RegisterKeyInfo(SecretInfo(SecretInfo.DEFAULT_SECRET, stringArg(args, "newSecret", DEFAULT_NEW_SECRET))),
          )
        }
        10 -> logSdkCall("setManagerKey from=${from.time} to=${to.time}") { sdk.setManagerKey(from.time, to.time) }
        11 -> logSdkCall("setEventsKey from=${from.time} to=${to.time}") { sdk.setEventsKey(from.time, to.time) }
        12 -> logSdkCall("setBlockListKey") {
          sdk.setBlockListKey(
            from.time,
            to.time,
            stringListArg(args, "blockKeyIds", listOf("000000000001", "000000000002", "000000000003")),
          )
        }
        13 -> logSdkCall("setBlankKey") { sdk.setBlankKey() }
        14 -> logSdkCall("clearBlocklistFlag") { sdk.clearBlocklistFlag() }
        15 -> logSdkCall("setDateTime") {
          sdk.setDateTime(parseDate(args["time"], "yyyy-MM-dd HH:mm:ss"))
        }
        16 -> logSdkCall("setFingers") { sdk.setFingers((1..20).toList()) }
        17 -> logSdkCall("deleteFingerprint fingerIndex=${intArg(args, "fingerIndex", 1)}") {
          sdk.deleteFingerprint(intArg(args, "fingerIndex", 1))
        }
        18 -> logSdkCall("setFingerprint fingerIndex=${intArg(args, "fingerIndex", 1)}") {
          sdk.setFingerprint(
            intArg(args, "fingerIndex", 1),
            stringArg(args, "fingerprintFeature", DEFAULT_FINGERPRINT_FEATURE),
          )
        }
        19 -> logSdkCall("setUserKey multi lockIds=${stringArg(args, "lockIds", DEFAULT_USER_KEY_LOCK_IDS)}") {
          sdk.setUserKey(defaultUserKeyInfo(stringArg(args, "lockIds", DEFAULT_USER_KEY_LOCK_IDS)), true)
        }
        20 -> logSdkCall("setSwitchLockTime unlock=${boolArg(args, "unlock", false)} count=${intArg(args, "switchCount", 1)}") {
          sdk.setSwitchLockTime(boolArg(args, "unlock", false), intArg(args, "switchCount", 1))
        }
        21 -> logSdkCall("setUserKey multiTime lockIds=${stringArg(args, "lockIds", DEFAULT_MULTI_TIME_LOCK_IDS)}") {
          sdk.setUserKey(defaultUserKeyInfo(stringArg(args, "lockIds", DEFAULT_MULTI_TIME_LOCK_IDS)), true)
        }
        22 -> logSdkCall("getFingerprint") { sdk.getFingerprint() }
        23 -> logSdkCall("setFingerprint task fingerIndex=${intArg(args, "fingerIndex", 1)}") {
          sdk.setFingerprint(
            intArg(args, "fingerIndex", 1),
            listOf(stringArg(args, "fingerprintFeature", DEFAULT_FINGERPRINT_FEATURE)),
          )
        }
        24 -> logSdkCall("setTasks taskLockId=${stringArg(args, "taskLockId", DEFAULT_TASK_LOCK_ID)}") {
          sdk.setTasks(listOf(defaultTask(stringArg(args, "taskLockId", DEFAULT_TASK_LOCK_ID))))
        }
        25 -> logSdkCall("delTask taskIds=${intArrayArg(args, "taskIds")?.joinToString()}") { sdk.delTask(intArrayArg(args, "taskIds")) }
        else -> {
          Log.e(
            TAG,
            "operation error index=$index name=${operationName(index)} code=blekey_unknown_operation message=Unknown operation index: $index args=${args.toSafeLogString()}",
          )
          result.error("blekey_unknown_operation", "Unknown operation index: $index", null)
          return
        }
      }

      Log.d(TAG, "operation out index=$index name=${operationName(index)} result=true")
      result.success(true)
    } catch (error: Throwable) {
      Log.e(TAG, "operation error index=$index name=${operationName(index)} code=blekey_execute_failed message=${error.message}", error)
      result.error("blekey_execute_failed", error.message, null)
    }
  }

  private fun parseDate(value: Any?, pattern: String): Date {
    val text = value as? String ?: throw IllegalArgumentException("Missing $pattern value")
    val format = SimpleDateFormat(pattern, Locale.US).apply { isLenient = false }
    val position = ParsePosition(0)
    val parsed = format.parse(text, position)
    require(parsed != null && position.index == text.length) { "Invalid $pattern value" }
    return parsed
  }

  private fun userKeyInfo(args: Map<*, *>): UserKeyInfo {
    val ids = args["lockIds"] as? List<*> ?: throw IllegalArgumentException("lockIds required")
    require(ids.isNotEmpty() && ids.all { it is String && it.matches(Regex("[0-9A-Fa-f]{12}")) })
    val blocks = args["timeBlocks"] as? List<*> ?: throw IllegalArgumentException("timeBlocks required")
    require(blocks.isNotEmpty())
    val sections = blocks.map { value ->
      val block = value as? Map<*, *> ?: throw IllegalArgumentException("Invalid time block")
      val from = parseDate(block["from"], "yyyy-MM-dd")
      val lastDay = parseDate(block["to"], "yyyy-MM-dd")
      require(!lastDay.before(from))
      val to = Calendar.getInstance().apply {
        time = lastDay
        set(Calendar.HOUR_OF_DAY, 23)
        set(Calendar.MINUTE, 59)
        set(Calendar.SECOND, 59)
      }.time
      val times = block["times"] as? List<*> ?: throw IllegalArgumentException("times required")
      require(times.isNotEmpty())
      DateSection(from, to, times.map { item ->
        val time = item as? Map<*, *> ?: throw IllegalArgumentException("Invalid time window")
        TimeSection(
          parseDate("${block["from"]} ${time["from"]}", "yyyy-MM-dd HH:mm:ss"),
          parseDate("${block["from"]} ${time["to"]}", "yyyy-MM-dd HH:mm:ss"),
        )
      })
    }
    return UserKeyInfo(sections, ids.map { it as String })
  }

  private fun defaultUserKeyInfo(lockIdsCsv: String): UserKeyInfo {
    val timeBlocks = mutableListOf<DateSection>()
    val todayStart = Calendar.getInstance()
    todayStart.set(Calendar.HOUR_OF_DAY, 0)
    todayStart.set(Calendar.MINUTE, 0)
    todayStart.set(Calendar.SECOND, 0)
    val todayEnd = Calendar.getInstance()
    todayEnd.set(Calendar.HOUR_OF_DAY, 23)
    todayEnd.set(Calendar.MINUTE, 59)
    todayEnd.set(Calendar.SECOND, 59)
    val dateEnd = Calendar.getInstance()
    dateEnd.add(Calendar.DATE, 7)
    dateEnd.set(Calendar.HOUR_OF_DAY, 23)
    dateEnd.set(Calendar.MINUTE, 59)
    dateEnd.set(Calendar.SECOND, 59)
    timeBlocks.add(
      DateSection(
        todayStart.time,
        dateEnd.time,
        listOf(TimeSection(todayStart.time, todayEnd.time)),
      ),
    )
    return UserKeyInfo(timeBlocks, csv(lockIdsCsv))
  }

  private fun defaultTask(lockId: String): Task {
    val task = Task()
    task.taskId = 2
    task.users = listOf(TaskUser(1, 1), TaskUser(2, 0))

    val from = Calendar.getInstance()
    val to = Calendar.getInstance()
    to.add(Calendar.DATE, 7)
    val dayStart = Calendar.getInstance()
    dayStart.set(Calendar.HOUR_OF_DAY, 0)
    dayStart.set(Calendar.MINUTE, 0)
    dayStart.set(Calendar.SECOND, 0)
    val dayEnd = Calendar.getInstance()
    dayEnd.set(Calendar.HOUR_OF_DAY, 23)
    dayEnd.set(Calendar.MINUTE, 59)
    dayEnd.set(Calendar.SECOND, 59)
    val dateSection = DateSection()
    dateSection.from = from.time
    dateSection.to = to.time
    dateSection.times = listOf(TimeSection(dayStart.time, dayEnd.time))
    task.timeBlocks = listOf(dateSection)

    val lockInfo = TaskLockInfo()
    lockInfo.lockId = lockId
    lockInfo.num = 1
    lockInfo.mode = 1
    lockInfo.dateSectionIndex = listOf(1)
    task.locks = listOf(lockInfo)
    return task
  }

  private val scanCallback = object : BleScanCallback() {
    override fun onScanStarted(success: Boolean) {
      Log.d(TAG, "scan callback onScanStarted success=$success")
      eventSink?.success(mapOf("type" to "scanStarted", "success" to success))
    }

    override fun onScanning(bleDevice: BleDevice) {
      Log.d(TAG, "scan callback onScanning device=${bleDevice.toSafeLogString()}")
      eventSink?.success(
        mapOf(
          "type" to "device",
          "device" to bleDevice.toMap()
        )
      )
    }

    override fun onScanFinished(scanResultList: MutableList<BleDevice>) {
      Log.d(TAG, "scan callback onScanFinished count=${scanResultList.size}")
      eventSink?.success(
        mapOf(
          "type" to "scanFinished",
          "devices" to scanResultList.map { it.toMap() }
        )
      )
    }
  }

  private val bleKeyCallback = object : BleKeyCallback {
    override fun onConnectToKey(result: BleKeyResult<*>) = emitResult("ConnectKey", result)
    override fun onDisconnectFromKey(result: BleKeyResult<*>) = emitResult("DisconnectKey", result)
    override fun onSetDateTime(result: BleKeyResult<*>) = emitResult("SetDateTime", result)
    override fun onReadKeyRecords(result: BleKeyResult<RecordBean>) = emitResult("ReadKeyRecords", result)
    override fun onReadKeyRecordsComplete(result: BleKeyResult<*>) = emitResult("ReadKeyRecordsComplete", result)
    override fun onReport(result: BleKeyResult<RecordInfo>) = emitResult("Report", result)
    override fun onClearRecords(result: BleKeyResult<*>) = emitResult("ClearRecords", result)
    override fun onSetBlankKey(result: BleKeyResult<*>) = emitResult("SetBlankKey", result)
    override fun onSetManagerKey(result: BleKeyResult<*>) = emitResult("SetManagerKey", result)
    override fun onSetUserKey(result: BleKeyResult<*>) = emitResult("SetUserKey", result)
    override fun onSetEventsKey(result: BleKeyResult<*>) = emitResult("SetEventsKey", result)
    override fun onSetBlockListKey(result: BleKeyResult<*>) = emitResult("SetBlockListKey", result)
    override fun onSetReadLockIdKey(result: BleKeyResult<*>) = emitResult("SetReadLockIdKey", result)
    override fun onSetRegisterKey(result: BleKeyResult<*>) = emitResult("SetRegisterKey", result)
    override fun onClearBlocklistFlag(result: BleKeyResult<*>) = emitResult("ClearBlocklistFlag", result)
    override fun onReadKeyInfo(result: BleKeyResult<KeyInfo>) = emitResult("ReadKeyInfo", result)
    override fun onSetKeySecret(result: BleKeyResult<*>) = emitResult("SetKeySecret", result)
    override fun onSetOnline(result: BleKeyResult<*>) = emitResult("SetOnline", result)
    override fun onSetFingers(result: BleKeyResult<*>) = emitResult("SetFingers", result)
    override fun onDeleteFingerprint(result: BleKeyResult<*>) = emitResult("DeleteFingerprint", result)
    override fun onSetFingerprint(result: BleKeyResult<*>) = emitResult("SetFingerprint", result)
    override fun onSetSwitchLockTime(result: BleKeyResult<*>) = emitResult("SetSwitchLockTime", result)
    override fun onSetTasks(result: BleKeyResult<*>) = emitResult("SetTasks", result)
    override fun onDelTask(result: BleKeyResult<*>) = emitResult("DelTask", result)
    override fun onGetFingerPrint(result: BleKeyResult<String>) = emitResult("GetFingerPrint", result)
    override fun onSetFingerVerifyType(result: BleKeyResult<*>) = emitResult("SetFingerVerifyType", result)
    override fun onSetTaskType(result: BleKeyResult<*>) = emitResult("SetTaskType", result)
    override fun onGetTaskList(result: BleKeyResult<MutableList<Int>>) = emitResult("GetTaskList", result)
    override fun onSetUnlockDirection(result: BleKeyResult<*>) = emitResult("SetUnlockDirection", result)
    override fun onSetTaskEnable(result: BleKeyResult<*>) = emitResult("SetTaskEnable", result)
  }

  private fun emitResult(name: String, result: BleKeyResult<*>) {
    Log.d(TAG, "sdk callback $name result=${result.toSafeLogString()}")
    eventSink?.success(
      mapOf(
        "type" to "operationResult",
        "name" to name,
        "result" to result.toMap(),
      ),
    )
  }

  private fun BleDevice.toMap(): Map<String, Any?> {
    return mapOf(
      "name" to name,
      "mac" to mac,
      "key" to key,
      "keyId" to keyId,
      "scanRecord" to scanRecord?.joinToString("") { "%02X".format(it.toInt() and 0xFF) },
      "rssi" to rssi,
      "timestampNanos" to timestampNanos
    )
  }

  private fun BleKeyResult<*>.toMap(): Map<String, Any?> {
    val serializedObj = serializeValue(obj)
    return mapOf(
      "ret" to isRet,
      "code" to code,
      "msg" to msg,
      "obj" to serializedObj,
      "objText" to obj?.toString(),
    )
  }

  private fun serializeValue(value: Any?, depth: Int = 0, seen: MutableSet<Int> = mutableSetOf()): Any? {
    if (value == null) return null
    if (depth >= 5) return value.toString()

    return when (value) {
      is String, is Number, is Boolean -> value
      is Char -> value.toString()
      is Date -> value.time
      is Enum<*> -> value.name
      is Map<*, *> -> value.entries.associate { (key, nestedValue) ->
        key?.toString().orEmpty() to serializeValue(nestedValue, depth + 1, seen)
      }
      is Iterable<*> -> value.map { item -> serializeValue(item, depth + 1, seen) }
      is IntArray -> value.map { item -> item }
      is LongArray -> value.map { item -> item }
      is DoubleArray -> value.map { item -> item }
      is FloatArray -> value.map { item -> item }
      is BooleanArray -> value.map { item -> item }
      is ShortArray -> value.map { item -> item.toInt() }
      is ByteArray -> value.joinToString("") { "%02X".format(it.toInt() and 0xFF) }
      else -> serializeObject(value, depth, seen)
    }
  }

  private fun serializeObject(value: Any, depth: Int, seen: MutableSet<Int>): Any? {
    val identity = System.identityHashCode(value)
    if (!seen.add(identity)) {
      return "<circular:${value.javaClass.simpleName}>"
    }

    try {
      if (value.javaClass.isArray) {
        val size = Array.getLength(value)
        return (0 until size).map { index ->
          serializeValue(Array.get(value, index), depth + 1, seen)
        }
      }

      val fields = linkedMapOf<String, Any?>()
      var currentClass: Class<*>? = value.javaClass
      while (currentClass != null && currentClass != Any::class.java) {
        currentClass.declaredFields
          .filterNot { field -> Modifier.isStatic(field.modifiers) || field.isSynthetic }
          .forEach { field ->
            runCatching {
              field.isAccessible = true
              fields.putIfAbsent(field.name, serializeValue(field.get(value), depth + 1, seen))
            }
          }
        currentClass = currentClass.superclass
      }
      if (fields.isEmpty()) {
        return value.toString()
      }
      fields["__class__"] = value.javaClass.name
      return fields
    } finally {
      seen.remove(identity)
    }
  }

  private fun stringArg(args: Map<*, *>, key: String, fallback: String): String {
    return (args[key] as? String)?.takeIf { it.isNotBlank() } ?: fallback
  }

  private fun intArg(args: Map<*, *>, key: String, fallback: Int): Int {
    return when (val value = args[key]) {
      is Int -> value
      is Number -> value.toInt()
      is String -> value.toIntOrNull() ?: fallback
      else -> fallback
    }
  }

  private fun boolArg(args: Map<*, *>, key: String, fallback: Boolean): Boolean {
    return when (val value = args[key]) {
      is Boolean -> value
      is String -> value.equals("true", ignoreCase = true)
      else -> fallback
    }
  }

  private fun stringListArg(args: Map<*, *>, key: String, fallback: List<String>): List<String> {
    return when (val value = args[key]) {
      is List<*> -> value.mapNotNull { it?.toString() }.filter { it.isNotBlank() }.ifEmpty { fallback }
      is String -> csv(value).ifEmpty { fallback }
      else -> fallback
    }
  }

  private fun intArrayArg(args: Map<*, *>, key: String): IntArray? {
    val list = when (val value = args[key]) {
      is List<*> -> value.mapNotNull {
        when (it) {
          is Int -> it
          is Number -> it.toInt()
          is String -> it.toIntOrNull()
          else -> null
        }
      }
      is String -> csv(value).mapNotNull { it.toIntOrNull() }
      else -> emptyList()
    }
    return list.takeIf { it.isNotEmpty() }?.toIntArray()
  }

  private fun logSdkCall(name: String, block: () -> Unit) {
    Log.d(TAG, "sdk call in $name")
    block()
    Log.d(TAG, "sdk call out $name")
  }

  private fun operationName(index: Int?): String {
    return when (index) {
      0 -> "connectToKey"
      1 -> "disconnectFromKey"
      2 -> "readKeyInfo"
      3 -> "setKeySecret"
      4 -> "readKeyRecords"
      5 -> "clearRecords"
      6 -> "setUserKey"
      7 -> "setOnline"
      8 -> "setReadLockIdKey"
      9 -> "setRegisterKey"
      10 -> "setManagerKey"
      11 -> "setEventsKey"
      12 -> "setBlockListKey"
      13 -> "setBlankKey"
      14 -> "clearBlocklistFlag"
      15 -> "setDateTime"
      16 -> "setFingers"
      17 -> "deleteFingerprint"
      18 -> "setFingerprint"
      19 -> "setUserKeyMulti"
      20 -> "setSwitchLockTime"
      21 -> "setUserKeyMultiTime"
      22 -> "getFingerprint"
      23 -> "setFingerprintTask"
      24 -> "setTasks"
      25 -> "delTask"
      else -> "unknown"
    }
  }

  private fun Map<*, *>.toSafeLogString(): String {
    return entries.joinToString(prefix = "{", postfix = "}") { entry ->
      "${entry.key}=${entry.value}"
    }
  }

  private fun String.maskForLog(): String = this

  private fun BleDevice.toSafeLogString(): String {
    return "name=$name mac=$mac key=$key keyId=$keyId rssi=$rssi " +
      "scanRecord=${scanRecord?.joinToString("") { "%02X".format(it.toInt() and 0xFF) }} " +
      "timestampNanos=$timestampNanos"
  }

  private fun BleKeyResult<*>.toSafeLogString(): String {
    return "ret=$isRet code=$code msg=$msg obj=${serializeValue(obj)} objText=${obj?.toString()}"
  }

  private fun csv(value: String): List<String> {
    return value.split(',', '\n', '，').map { it.trim() }.filter { it.isNotEmpty() }
  }
}
