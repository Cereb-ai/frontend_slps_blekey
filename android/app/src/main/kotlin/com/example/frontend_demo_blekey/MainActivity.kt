package com.example.frontend_demo_blekey

import android.bluetooth.BluetoothAdapter
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "frontend_demo_blekey/bluetooth",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
                "requestEnableBluetooth" -> {
                    requestEnableBluetooth()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isBluetoothEnabled(): Boolean {
        return try {
            BluetoothAdapter.getDefaultAdapter()?.isEnabled == true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun requestEnableBluetooth() {
        try {
            if (!isBluetoothEnabled()) {
                startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
            }
        } catch (_: Exception) {
        }
    }
}
