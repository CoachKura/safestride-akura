package com.akura.safestride.akura_mobile

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GarminPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private val scannedDevices = mutableMapOf<String, Map<String, Any>>()
    private var isScanning = false
    private var eventSink: EventChannel.EventSink? = null
    
    private val handler = Handler(Looper.getMainLooper())
    private val scanDuration = 10000L // 10 seconds

    companion object {
        private const val CHANNEL_NAME = "com.safestride/garmin"
        private const val EVENT_CHANNEL_NAME = "com.safestride/garmin_events"
        private const val GARMIN_NAME_PREFIX = "Garmin"
        private const val FORERUNNER_PREFIX = "Forerunner"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
        
        initializeBluetooth()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun initializeBluetooth() {
        context?.let { ctx ->
            val bluetoothManager = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bluetoothAdapter = bluetoothManager?.adapter
            bluetoothLeScanner = bluetoothAdapter?.bluetoothLeScanner
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "scanDevices" -> scanDevices(call, result)
            "scanBluetoothDevices" -> scanBluetoothDevices(call, result)
            "scanWiFiDevices" -> scanWiFiDevices(result)
            "connectDevice" -> connectDevice(call, result)
            "disconnect" -> disconnect(result)
            "getDeviceInfo" -> getDeviceInfo(result)
            "getBatteryLevel" -> getBatteryLevel(result)
            "syncHistoricalData" -> syncHistoricalData(call, result)
            "startWorkout" -> startWorkout(call, result)
            "stopWorkout" -> stopWorkout(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth is not available on this device", null)
            return
        }
        
        if (!bluetoothAdapter!!.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is disabled", null)
            return
        }
        
        result.success(true)
    }

    private fun scanDevices(call: MethodCall, result: MethodChannel.Result) {
        val connectionType = call.argument<String>("connectionType") ?: "both"
        
        when (connectionType) {
            "bluetooth" -> scanBluetoothDevices(call, result)
            "wifi" -> scanWiFiDevices(result)
            "both" -> {
                // For "both", primarily use Bluetooth scan
                scanBluetoothDevices(call, result)
            }
            else -> result.error("INVALID_TYPE", "Invalid connection type", null)
        }
    }

    private fun scanBluetoothDevices(call: MethodCall, result: MethodChannel.Result) {
        if (!checkBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }

        if (isScanning) {
            result.error("SCAN_IN_PROGRESS", "A scan is already in progress", null)
            return
        }

        scannedDevices.clear()
        isScanning = true

        val scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                processScanResult(scanResult)
            }

            override fun onBatchScanResults(results: List<ScanResult>) {
                results.forEach { processScanResult(it) }
            }

            override fun onScanFailed(errorCode: Int) {
                isScanning = false
                result.error("SCAN_FAILED", "Bluetooth scan failed with error code: $errorCode", null)
            }
        }

        try {
            val scanSettings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()

            bluetoothLeScanner?.startScan(null, scanSettings, scanCallback)

            // Stop scanning after duration
            handler.postDelayed({
                if (isScanning) {
                    try {
                        bluetoothLeScanner?.stopScan(scanCallback)
                    } catch (e: Exception) {
                        // Ignore
                    }
                    isScanning = false
                    result.success(scannedDevices.values.toList())
                }
            }, scanDuration)

        } catch (e: SecurityException) {
            isScanning = false
            result.error("PERMISSION_DENIED", "Bluetooth scan permission denied", e.message)
        } catch (e: Exception) {
            isScanning = false
            result.error("SCAN_ERROR", "Failed to start scan", e.message)
        }
    }

    private fun processScanResult(scanResult: ScanResult) {
        try {
            val device = scanResult.device
            val deviceName = device.name ?: return

            // Filter for Garmin devices only
            if (!deviceName.contains(GARMIN_NAME_PREFIX, ignoreCase = true) &&
                !deviceName.contains(FORERUNNER_PREFIX, ignoreCase = true)) {
                return
            }

            val rssi = scanResult.rssi
            val signalStrength = calculateSignalStrength(rssi)

            val deviceInfo = mapOf(
                "id" to device.address,
                "name" to deviceName,
                "connection_type" to "bluetooth",
                "signal_strength" to signalStrength,
                "rssi" to rssi
            )

            scannedDevices[device.address] = deviceInfo

            // Notify Flutter about new device
            eventSink?.success(mapOf(
                "event" to "deviceFound",
                "device" to deviceInfo
            ))

        } catch (e: SecurityException) {
            // Permission denied during scan result processing
        } catch (e: Exception) {
            // Other errors
        }
    }

    private fun calculateSignalStrength(rssi: Int): Int {
        return when {
            rssi >= -50 -> 100
            rssi >= -60 -> 90
            rssi >= -70 -> 75
            rssi >= -80 -> 50
            rssi >= -90 -> 25
            else -> 10
        }
    }

    private fun scanWiFiDevices(result: MethodChannel.Result) {
        // WiFi scanning for Garmin devices requires mDNS discovery
        // This is more complex and requires network service discovery
        // For now, return empty list
        result.success(emptyList<Map<String, Any>>())
    }

    private fun connectDevice(call: MethodCall, result: MethodChannel.Result) {
        val deviceId = call.argument<String>("deviceId")
        val connectionType = call.argument<String>("connectionType") ?: "bluetooth"

        if (deviceId == null) {
            result.error("INVALID_DEVICE", "Device ID is required", null)
            return
        }

        // For actual Garmin SDK integration, you would use:
        // - Garmin Connect IQ SDK for data sync
        // - Garmin Health SDK for real-time data
        // This requires Garmin developer account and API keys

        // For now, simulate connection through standard Bluetooth
        try {
            val device = bluetoothAdapter?.getRemoteDevice(deviceId)
            
            if (device == null) {
                result.error("DEVICE_NOT_FOUND", "Device not found", null)
                return
            }

            // Successful connection placeholder
            // In production, establish actual BLE GATT connection here
            result.success(true)

        } catch (e: Exception) {
            result.error("CONNECTION_FAILED", "Failed to connect to device", e.message)
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        // Disconnect from Garmin device
        // In production, close GATT connection here
        result.success(true)
    }

    private fun getDeviceInfo(result: MethodChannel.Result) {
        // Query device information
        // In production, read device characteristics via GATT
        val deviceInfo = mapOf(
            "model" to "Forerunner 265",
            "firmware" to "Unknown",
            "battery" to 0
        )
        result.success(deviceInfo)
    }

    private fun getBatteryLevel(result: MethodChannel.Result) {
        // Read battery level from device
        // In production, read battery characteristic via GATT
        result.success(0)
    }

    private fun syncHistoricalData(call: MethodCall, result: MethodChannel.Result) {
        val days = call.argument<Int>("days") ?: 7
        
        // Sync workout data from Garmin device
        // In production, use Garmin Connect IQ SDK to fetch activities
        result.success(emptyList<Map<String, Any>>())
    }

    private fun startWorkout(call: MethodCall, result: MethodChannel.Result) {
        val workoutType = call.argument<String>("workoutType") ?: "running"
        
        // Send command to start workout on watch
        // In production, use Garmin device communication protocol
        result.success(true)
    }

    private fun stopWorkout(result: MethodChannel.Result) {
        // Send command to stop workout on watch
        // In production, retrieve workout summary from device
        result.success(mapOf(
            "duration" to 0,
            "distance" to 0.0,
            "calories" to 0
        ))
    }

    private fun checkBluetoothPermissions(): Boolean {
        val context = context ?: return false
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADMIN) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }
}
