# Garmin Integration - Developer Implementation Guide

## Overview
This guide explains how to implement the native platform code for Garmin SDK integration in SafeStride. The Flutter service layer is already complete; you need to implement the platform-specific Android and iOS handlers.

## Project Structure

```
lib/services/garmin_connect_service.dart  ✅ COMPLETE (Flutter)
lib/screens/garmin_device_screen.dart     ✅ COMPLETE (Flutter)
android/
  app/src/main/kotlin/GarminPlugin.kt     ⚠️ TO IMPLEMENT
ios/
  Runner/GarminPlugin.swift                ⚠️ TO IMPLEMENT
```

## Flutter Service (Already Implemented)

The `GarminConnectService` provides:
- MethodChannel: `com.safestride/garmin`
- EventChannel: `com.safestride/garmin_events`
- 20+ methods for device communication

### Method Channel API

```dart
// Device Discovery
Future<List<Map<String, dynamic>>> scanForDevices(int durationSeconds)
Future<bool> stopScan()

// Connection Management
Future<bool> connectToDevice(String deviceId)
Future<bool> disconnectDevice()
Future<bool> isConnected()

// Device Information
Future<String?> getConnectedDeviceId()
Future<String?> getDeviceName()
Future<Map<String, dynamic>?> getDeviceInfo()
Future<int?> getBatteryLevel()

// Workout Control
Future<bool> startWorkout(String workoutType, Map<String, dynamic>? config)
Future<Map<String, dynamic>?> stopWorkout()
Future<bool> pauseWorkout()
Future<bool> resumeWorkout()

// Real-time Data
Future<int?> getCurrentHeartRate()
Future<Map<String, dynamic>?> getCurrentLocation()

// Data Sync
Future<List<Map<String, dynamic>>> syncHistoricalData(int days)

// Configuration
Future<bool> setHeartRateZones(Map<String, List<int>> zones)
Future<bool> sendWorkoutToDevice(Map<String, dynamic> workout)
Future<bool> enableLiveTracking(bool enabled)
```

### Event Channel API

Stream events (JSON format):
```json
{
  "type": "heart_rate" | "location" | "workout_update" | "device_disconnected",
  "data": { ... }
}
```

Event Types:
1. **heart_rate**: `{"bpm": 145, "timestamp": 1234567890}`
2. **location**: `{"latitude": 40.7, "longitude": -74.0, "altitude": 10.5, "speed": 3.2, "timestamp": 1234567890}`
3. **workout_update**: `{"distance_meters": 5200, "duration_seconds": 1800, "calories": 312, "pace": 6.2, "cadence": 170}`
4. **device_disconnected**: `{"reason": "connection_lost"}`

## Android Implementation

### 1. Add Garmin SDK Dependency

**File**: `android/app/build.gradle.kts`

```kotlin
dependencies {
    // Existing dependencies...
    
    // Garmin Connect Mobile SDK
    implementation("com.garmin.connectiq:ciq-companion-app-sdk:2.0.3")
    
    // Bluetooth & Location
    implementation("com.google.android.gms:play-services-location:21.0.1")
}
```

**Permissions**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <!-- Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    
    <!-- Location permission (required for BLE scanning) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Feature declarations -->
    <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
    
    <application>
        <!-- Your app content -->
    </application>
</manifest>
```

### 2. Create Garmin Plugin

**File**: `android/app/src/main/kotlin/com/safestride/akura_mobile/GarminPlugin.kt`

```kotlin
package com.safestride.akura_mobile

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.exception.InvalidStateException
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

class GarminPlugin(private val context: Context, private val flutterEngine: FlutterEngine) {
    
    companion object {
        private const val CHANNEL = "com.safestride/garmin"
        private const val EVENT_CHANNEL = "com.safestride/garmin_events"
    }
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    
    private var connectIQ: ConnectIQ? = null
    private var connectedDevice: IQDevice? = null
    private var workoutSession: WorkoutSession? = null
    
    private val bluetoothManager: BluetoothManager by lazy {
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    }
    
    private val bluetoothAdapter: BluetoothAdapter by lazy {
        bluetoothManager.adapter
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var scanCallback: ScanCallback? = null
    private val discoveredDevices = mutableListOf<IQDevice>()
    
    fun initialize() {
        // Setup MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
        
        // Setup EventChannel
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
        
        // Initialize Garmin ConnectIQ SDK
        initializeConnectIQ()
    }
    
    private fun initializeConnectIQ() {
        try {
            connectIQ = ConnectIQ.getInstance(context, ConnectIQ.IQConnectType.WIRELESS)
            connectIQ?.initialize(context, true, object : ConnectIQ.ConnectIQListener {
                override fun onSdkReady() {
                    // SDK initialized successfully
                }
                
                override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus?) {
                    sendError("SDK initialization failed: ${status?.name}")
                }
                
                override fun onSdkShutDown() {
                    // SDK shut down
                }
            })
        } catch (e: Exception) {
            sendError("Failed to initialize ConnectIQ: ${e.message}")
        }
    }
    
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanForDevices" -> scanForDevices(call, result)
            "stopScan" -> stopScan(result)
            "connectToDevice" -> connectToDevice(call, result)
            "disconnectDevice" -> disconnectDevice(result)
            "isConnected" -> isConnected(result)
            "getConnectedDeviceId" -> getConnectedDeviceId(result)
            "getDeviceName" -> getDeviceName(result)
            "getDeviceInfo" -> getDeviceInfo(result)
            "getBatteryLevel" -> getBatteryLevel(result)
            "startWorkout" -> startWorkout(call, result)
            "stopWorkout" -> stopWorkout(result)
            "pauseWorkout" -> pauseWorkout(result)
            "resumeWorkout" -> resumeWorkout(result)
            "getCurrentHeartRate" -> getCurrentHeartRate(result)
            "getCurrentLocation" -> getCurrentLocation(result)
            "syncHistoricalData" -> syncHistoricalData(call, result)
            "setHeartRateZones" -> setHeartRateZones(call, result)
            "sendWorkoutToDevice" -> sendWorkoutToDevice(call, result)
            "enableLiveTracking" -> enableLiveTracking(call, result)
            else -> result.notImplemented()
        }
    }
    
    // === Device Discovery ===
    
    private fun scanForDevices(call: MethodCall, result: MethodChannel.Result) {
        val durationSeconds = call.argument<Int>("durationSeconds") ?: 10
        
        if (!checkBluetoothPermissions()) {
            result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
            return
        }
        
        discoveredDevices.clear()
        
        try {
            // Get known Garmin devices
            val knownDevices = connectIQ?.knownDevices ?: emptyList()
            discoveredDevices.addAll(knownDevices)
            
            // Start BLE scan for additional devices
            startBLEScan()
            
            // Stop scan after duration
            handler.postDelayed({
                stopBLEScan()
                
                // Return discovered devices
                val devicesJson = JSONArray()
                discoveredDevices.forEach { device ->
                    devicesJson.put(JSONObject().apply {
                        put("deviceId", device.deviceIdentifier.toString())
                        put("deviceName", device.friendlyName ?: "Unknown Device")
                        put("deviceModel", device.deviceModel)
                        put("signalStrength", "Strong") // Placeholder
                    })
                }
                result.success(devicesJson.toString())
            }, (durationSeconds * 1000).toLong())
            
        } catch (e: Exception) {
            result.error("SCAN_FAILED", "Failed to scan: ${e.message}", null)
        }
    }
    
    private fun startBLEScan() {
        if (!bluetoothAdapter.isEnabled) return
        
        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult?) {
                result?.device?.let { device ->
                    // Check if it's a Garmin device
                    if (isGarminDevice(device)) {
                        // Add to discovered list if not already present
                        // Convert BluetoothDevice to IQDevice (implementation specific)
                    }
                }
            }
        }
        
        try {
            bluetoothAdapter.bluetoothLeScanner?.startScan(scanCallback)
        } catch (e: SecurityException) {
            sendError("Bluetooth scan failed: ${e.message}")
        }
    }
    
    private fun stopBLEScan() {
        try {
            scanCallback?.let {
                bluetoothAdapter.bluetoothLeScanner?.stopScan(it)
            }
            scanCallback = null
        } catch (e: Exception) {
            // Ignore
        }
    }
    
    private fun stopScan(result: MethodChannel.Result) {
        stopBLEScan()
        result.success(true)
    }
    
    private fun isGarminDevice(device: BluetoothDevice): Boolean {
        val name = device.name ?: return false
        return name.contains("Garmin", ignoreCase = true) ||
               name.contains("Forerunner", ignoreCase = true) ||
               name.contains("Fenix", ignoreCase = true) ||
               name.contains("Vivoactive", ignoreCase = true) ||
               name.contains("Venu", ignoreCase = true)
    }
    
    // === Connection Management ===
    
    private fun connectToDevice(call: MethodCall, result: MethodChannel.Result) {
        val deviceId = call.argument<String>("deviceId")
        
        if (deviceId == null) {
            result.error("INVALID_ARGUMENT", "deviceId is required", null)
            return
        }
        
        try {
            // Find device in discovered list
            val device = discoveredDevices.find { 
                it.deviceIdentifier.toString() == deviceId 
            }
            
            if (device == null) {
                result.error("DEVICE_NOT_FOUND", "Device not found", null)
                return
            }
            
            // Register for device events
            connectIQ?.registerForDeviceEvents(device) { device, status ->
                when (status) {
                    IQDevice.IQDeviceStatus.CONNECTED -> {
                        connectedDevice = device
                        result.success(true)
                    }
                    IQDevice.IQDeviceStatus.NOT_CONNECTED -> {
                        sendEvent("device_disconnected", JSONObject().apply {
                            put("reason", "connection_lost")
                        })
                    }
                    else -> {}
                }
            }
            
        } catch (e: Exception) {
            result.error("CONNECTION_FAILED", "Failed to connect: ${e.message}", null)
        }
    }
    
    private fun disconnectDevice(result: MethodChannel.Result) {
        try {
            connectedDevice?.let { device ->
                connectIQ?.unregisterForDeviceEvents(device)
                connectedDevice = null
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("DISCONNECT_FAILED", "Failed to disconnect: ${e.message}", null)
        }
    }
    
    private fun isConnected(result: MethodChannel.Result) {
        result.success(connectedDevice != null)
    }
    
    // === Device Information ===
    
    private fun getConnectedDeviceId(result: MethodChannel.Result) {
        result.success(connectedDevice?.deviceIdentifier?.toString())
    }
    
    private fun getDeviceName(result: MethodChannel.Result) {
        result.success(connectedDevice?.friendlyName)
    }
    
    private fun getDeviceInfo(result: MethodChannel.Result) {
        val device = connectedDevice
        if (device == null) {
            result.success(null)
            return
        }
        
        val info = JSONObject().apply {
            put("model", device.deviceModel)
            put("firmware", "1.0.0") // Get actual firmware version
            put("serialNumber", device.deviceIdentifier.toString())
        }
        result.success(info.toString())
    }
    
    private fun getBatteryLevel(result: MethodChannel.Result) {
        // Get battery level from device
        // This requires specific IQ App communication
        result.success(85) // Placeholder
    }
    
    // === Workout Control ===
    
    private fun startWorkout(call: MethodCall, result: MethodChannel.Result) {
        val workoutType = call.argument<String>("workoutType") ?: "running"
        val config = call.argument<Map<String, Any>>("config") ?: emptyMap()
        
        try {
            workoutSession = WorkoutSession(workoutType, config)
            workoutSession?.start()
            
            // Start sending workout data events
            startWorkoutDataStream()
            
            result.success(true)
        } catch (e: Exception) {
            result.error("WORKOUT_START_FAILED", "Failed to start workout: ${e.message}", null)
        }
    }
    
    private fun stopWorkout(result: MethodChannel.Result) {
        try {
            val summary = workoutSession?.stop()
            stopWorkoutDataStream()
            
            val summaryJson = JSONObject().apply {
                put("distance_meters", summary?.distanceMeters ?: 0)
                put("duration_seconds", summary?.durationSeconds ?: 0)
                put("calories", summary?.calories ?: 0)
                put("average_heart_rate", summary?.averageHeartRate ?: 0)
                put("max_heart_rate", summary?.maxHeartRate ?: 0)
                put("track_points", summary?.trackPoints ?: JSONArray())
            }
            
            result.success(summaryJson.toString())
        } catch (e: Exception) {
            result.error("WORKOUT_STOP_FAILED", "Failed to stop workout: ${e.message}", null)
        }
    }
    
    private fun pauseWorkout(result: MethodChannel.Result) {
        workoutSession?.pause()
        result.success(true)
    }
    
    private fun resumeWorkout(result: MethodChannel.Result) {
        workoutSession?.resume()
        result.success(true)
    }
    
    // === Real-time Data ===
    
    private fun getCurrentHeartRate(result: MethodChannel.Result) {
        val hr = workoutSession?.getCurrentHeartRate()
        result.success(hr)
    }
    
    private fun getCurrentLocation(result: MethodChannel.Result) {
        val location = workoutSession?.getCurrentLocation()
        if (location != null) {
            val locationJson = JSONObject().apply {
                put("latitude", location.latitude)
                put("longitude", location.longitude)
                put("altitude", location.altitude)
                put("speed", location.speed)
                put("timestamp", location.timestamp)
            }
            result.success(locationJson.toString())
        } else {
            result.success(null)
        }
    }
    
    private fun startWorkoutDataStream() {
        // Send periodic workout updates via EventChannel
        val updateRunnable = object : Runnable {
            override fun run() {
                workoutSession?.let { session ->
                    // Send heart rate
                    sendEvent("heart_rate", JSONObject().apply {
                        put("bpm", session.getCurrentHeartRate())
                        put("timestamp", System.currentTimeMillis())
                    })
                    
                    // Send location
                    session.getCurrentLocation()?.let { loc ->
                        sendEvent("location", JSONObject().apply {
                            put("latitude", loc.latitude)
                            put("longitude", loc.longitude)
                            put("altitude", loc.altitude)
                            put("speed", loc.speed)
                            put("timestamp", System.currentTimeMillis())
                        })
                    }
                    
                    // Send workout update
                    sendEvent("workout_update", JSONObject().apply {
                        put("distance_meters", session.getCurrentDistance())
                        put("duration_seconds", session.getCurrentDuration())
                        put("calories", session.getCurrentCalories())
                        put("pace", session.getCurrentPace())
                        put("cadence", session.getCurrentCadence())
                    })
                }
                
                handler.postDelayed(this, 1000) // Update every second
            }
        }
        handler.post(updateRunnable)
    }
    
    private fun stopWorkoutDataStream() {
        handler.removeCallbacksAndMessages(null)
    }
    
    // === Data Sync ===
    
    private fun syncHistoricalData(call: MethodCall, result: MethodChannel.Result) {
        val days = call.argument<Int>("days") ?: 7
        
        // Fetch historical activities from device
        // This requires IQ App communication
        
        val activities = JSONArray()
        // Populate with actual data
        
        result.success(activities.toString())
    }
    
    // === Configuration ===
    
    private fun setHeartRateZones(call: MethodCall, result: MethodChannel.Result) {
        val zones = call.argument<Map<String, List<Int>>>("zones")
        
        // Send HR zones to device via IQ App
        
        result.success(true)
    }
    
    private fun sendWorkoutToDevice(call: MethodCall, result: MethodChannel.Result) {
        val workout = call.argument<Map<String, Any>>("workout")
        
        // Send workout structure to device
        
        result.success(true)
    }
    
    private fun enableLiveTracking(call: MethodCall, result: MethodChannel.Result) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        
        // Enable/disable live tracking
        
        result.success(true)
    }
    
    // === Helper Methods ===
    
    private fun checkBluetoothPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_SCAN
        ) == PackageManager.PERMISSION_GRANTED &&
        ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun sendEvent(type: String, data: JSONObject) {
        val event = JSONObject().apply {
            put("type", type)
            put("data", data)
        }
        handler.post {
            eventSink?.success(event.toString())
        }
    }
    
    private fun sendError(message: String) {
        handler.post {
            eventSink?.error("GARMIN_ERROR", message, null)
        }
    }
    
    fun dispose() {
        stopBLEScan()
        disconnectDevice(object : MethodChannel.Result {
            override fun success(result: Any?) {}
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
            override fun notImplemented() {}
        })
        connectIQ?.shutdown(context)
        methodChannel.setMethodCallHandler(null)
    }
}

// === Helper Classes ===

data class WorkoutData(
    val distanceMeters: Double,
    val durationSeconds: Int,
    val calories: Int,
    val averageHeartRate: Int,
    val maxHeartRate: Int,
    val trackPoints: List<TrackPoint>
)

data class TrackPoint(
    val latitude: Double,
    val longitude: Double,
    val altitude: Double,
    val speed: Double,
    val timestamp: Long
)

class WorkoutSession(
    private val workoutType: String,
    private val config: Map<String, Any>
) {
    private var startTime: Long = 0
    private var pauseTime: Long = 0
    private var totalPausedDuration: Long = 0
    private var isRunning = false
    private var isPaused = false
    
    private val trackPoints = mutableListOf<TrackPoint>()
    private var totalDistance = 0.0
    private var totalCalories = 0
    
    fun start() {
        startTime = System.currentTimeMillis()
        isRunning = true
    }
    
    fun pause() {
        if (isRunning && !isPaused) {
            pauseTime = System.currentTimeMillis()
            isPaused = true
        }
    }
    
    fun resume() {
        if (isPaused) {
            totalPausedDuration += System.currentTimeMillis() - pauseTime
            isPaused = false
        }
    }
    
    fun stop(): WorkoutData {
        isRunning = false
        return WorkoutData(
            distanceMeters = totalDistance,
            durationSeconds = getCurrentDuration(),
            calories = totalCalories,
            averageHeartRate = calculateAverageHR(),
            maxHeartRate = calculateMaxHR(),
            trackPoints = trackPoints
        )
    }
    
    fun getCurrentHeartRate(): Int {
        // Get from device sensor
        return 145 // Placeholder
    }
    
    fun getCurrentLocation(): TrackPoint? {
        // Get from GPS
        return null // Placeholder
    }
    
    fun getCurrentDistance(): Double = totalDistance
    
    fun getCurrentDuration(): Int {
        if (!isRunning) return 0
        val elapsed = System.currentTimeMillis() - startTime - totalPausedDuration
        return (elapsed / 1000).toInt()
    }
    
    fun getCurrentCalories(): Int = totalCalories
    
    fun getCurrentPace(): Double {
        if (totalDistance == 0.0) return 0.0
        return getCurrentDuration() / (totalDistance / 1000.0)
    }
    
    fun getCurrentCadence(): Int {
        // Get from device sensor
        return 170 // Placeholder
    }
    
    private fun calculateAverageHR(): Int {
        // Calculate from collected HR data
        return 145 // Placeholder
    }
    
    private fun calculateMaxHR(): Int {
        // Find max from collected HR data
        return 175 // Placeholder
    }
}
```

### 3. Register Plugin in MainActivity

**File**: `android/app/src/main/kotlin/com/safestride/akura_mobile/MainActivity.kt`

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var garminPlugin: GarminPlugin? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Garmin plugin
        garminPlugin = GarminPlugin(this, flutterEngine)
        garminPlugin?.initialize()
    }
    
    override fun onDestroy() {
        garminPlugin?.dispose()
        super.onDestroy()
    }
}
```

## iOS Implementation

### 1. Add Garmin SDK via CocoaPods

**File**: `ios/Podfile`

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Garmin Health SDK
  pod 'GarminHealthKit', '~> 1.0'
end
```

Run: `cd ios && pod install`

### 2. Add Permissions

**File**: `ios/Runner/Info.plist`

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>SafeStride needs Bluetooth to connect to your Garmin watch</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>SafeStride needs location access to track your workouts</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>SafeStride needs location access to track your workouts</string>
```

### 3. Create Garmin Plugin

**File**: `ios/Runner/GarminPlugin.swift`

```swift
import Flutter
import UIKit
import CoreBluetooth
import GarminHealthKit

class GarminPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CBCentralManagerDelegate {
    
    private static let CHANNEL = "com.safestride/garmin"
    private static let EVENT_CHANNEL = "com.safestride/garmin_events"
    
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var discoveredDevices: [CBPeripheral] = []
    
    private var workoutSession: WorkoutSession?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = GarminPlugin()
        
        instance.methodChannel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        
        instance.eventChannel = FlutterEventChannel(
            name: EVENT_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        instance.eventChannel?.setStreamHandler(instance)
        
        instance.initialize()
    }
    
    private func initialize() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Method Channel Handler
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "scanForDevices":
            scanForDevices(call: call, result: result)
        case "stopScan":
            stopScan(result: result)
        case "connectToDevice":
            connectToDevice(call: call, result: result)
        case "disconnectDevice":
            disconnectDevice(result: result)
        case "isConnected":
            isConnected(result: result)
        case "getConnectedDeviceId":
            getConnectedDeviceId(result: result)
        case "getDeviceName":
            getDeviceName(result: result)
        case "getDeviceInfo":
            getDeviceInfo(result: result)
        case "getBatteryLevel":
            getBatteryLevel(result: result)
        case "startWorkout":
            startWorkout(call: call, result: result)
        case "stopWorkout":
            stopWorkout(result: result)
        case "pauseWorkout":
            pauseWorkout(result: result)
        case "resumeWorkout":
            resumeWorkout(result: result)
        case "getCurrentHeartRate":
            getCurrentHeartRate(result: result)
        case "getCurrentLocation":
            getCurrentLocation(result: result)
        case "syncHistoricalData":
            syncHistoricalData(call: call, result: result)
        case "setHeartRateZones":
            setHeartRateZones(call: call, result: result)
        case "sendWorkoutToDevice":
            sendWorkoutToDevice(call: call, result: result)
        case "enableLiveTracking":
            enableLiveTracking(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle Bluetooth state changes
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, 
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if Garmin device
        if isGarminDevice(peripheral) && !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
        }
    }
    
    // MARK: - Device Discovery
    
    private func scanForDevices(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let duration = args["durationSeconds"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        
        discoveredDevices.removeAll()
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        
        // Stop scan after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
            self.stopBLEScan()
            
            // Return discovered devices
            let devices = self.discoveredDevices.map { peripheral -> [String: Any] in
                return [
                    "deviceId": peripheral.identifier.uuidString,
                    "deviceName": peripheral.name ?? "Unknown Device",
                    "deviceModel": "Garmin",
                    "signalStrength": "Strong"
                ]
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: devices),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                result(jsonString)
            } else {
                result("[]")
            }
        }
    }
    
    private func stopBLEScan() {
        centralManager?.stopScan()
    }
    
    private func stopScan(result: @escaping FlutterResult) {
        stopBLEScan()
        result(true)
    }
    
    private func isGarminDevice(_ peripheral: CBPeripheral) -> Bool {
        guard let name = peripheral.name?.lowercased() else { return false }
        return name.contains("garmin") ||
               name.contains("forerunner") ||
               name.contains("fenix") ||
               name.contains("vivoactive") ||
               name.contains("venu")
    }
    
    // MARK: - Connection Management
    
    private func connectToDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceId = args["deviceId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "deviceId required", details: nil))
            return
        }
        
        // Find device
        let uuid = UUID(uuidString: deviceId)
        let peripheral = discoveredDevices.first { $0.identifier == uuid }
        
        guard let device = peripheral else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
            return
        }
        
        centralManager?.connect(device, options: nil)
        connectedPeripheral = device
        result(true)
    }
    
    private func disconnectDevice(result: @escaping FlutterResult) {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
            connectedPeripheral = nil
        }
        result(true)
    }
    
    private func isConnected(result: @escaping FlutterResult) {
        result(connectedPeripheral != nil)
    }
    
    // MARK: - Device Information
    
    private func getConnectedDeviceId(result: @escaping FlutterResult) {
        result(connectedPeripheral?.identifier.uuidString)
    }
    
    private func getDeviceName(result: @escaping FlutterResult) {
        result(connectedPeripheral?.name)
    }
    
    private func getDeviceInfo(result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripheral else {
            result(nil)
            return
        }
        
        let info: [String: Any] = [
            "model": peripheral.name ?? "Unknown",
            "firmware": "1.0.0",
            "serialNumber": peripheral.identifier.uuidString
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: info),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            result(jsonString)
        } else {
            result(nil)
        }
    }
    
    private func getBatteryLevel(result: @escaping FlutterResult) {
        result(85) // Placeholder
    }
    
    // MARK: - Workout Control
    
    private func startWorkout(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let workoutType = args["workoutType"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        
        workoutSession = WorkoutSession(workoutType: workoutType)
        workoutSession?.start()
        startWorkoutDataStream()
        result(true)
    }
    
    private func stopWorkout(result: @escaping FlutterResult) {
        let summary = workoutSession?.stop()
        stopWorkoutDataStream()
        
        if let summary = summary {
            let summaryDict: [String: Any] = [
                "distance_meters": summary.distanceMeters,
                "duration_seconds": summary.durationSeconds,
                "calories": summary.calories,
                "average_heart_rate": summary.averageHeartRate,
                "max_heart_rate": summary.maxHeartRate
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: summaryDict),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                result(jsonString)
                return
            }
        }
        result(nil)
    }
    
    private func pauseWorkout(result: @escaping FlutterResult) {
        workoutSession?.pause()
        result(true)
    }
    
    private func resumeWorkout(result: @escaping FlutterResult) {
        workoutSession?.resume()
        result(true)
    }
    
    // MARK: - Real-time Data
    
    private func getCurrentHeartRate(result: @escaping FlutterResult) {
        result(workoutSession?.getCurrentHeartRate())
    }
    
    private func getCurrentLocation(result: @escaping FlutterResult) {
        result(nil) // Placeholder
    }
    
    private func startWorkoutDataStream() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let session = self.workoutSession else {
                timer.invalidate()
                return
            }
            
            // Send heart rate
            self.sendEvent(type: "heart_rate", data: [
                "bpm": session.getCurrentHeartRate(),
                "timestamp": Int(Date().timeIntervalSince1970 * 1000)
            ])
            
            // Send workout update
            self.sendEvent(type: "workout_update", data: [
                "distance_meters": session.getCurrentDistance(),
                "duration_seconds": session.getCurrentDuration(),
                "calories": session.getCurrentCalories()
            ])
        }
    }
    
    private func stopWorkoutDataStream() {
        // Timer will invalidate when session is nil
    }
    
    // MARK: - Stubs for remaining methods
    
    private func syncHistoricalData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("[]") // Placeholder
    }
    
    private func setHeartRateZones(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(true)
    }
    
    private func sendWorkoutToDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(true)
    }
    
    private func enableLiveTracking(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(true)
    }
    
    // MARK: - Helper Methods
    
    private func sendEvent(type: String, data: [String: Any]) {
        let event: [String: Any] = [
            "type": type,
            "data": data
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: event),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            eventSink?(jsonString)
        }
    }
}

// MARK: - WorkoutSession Class

class WorkoutSession {
    private let workoutType: String
    private var startTime: Date?
    private var pauseTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var isRunning = false
    private var isPaused = false
    
    private var totalDistance: Double = 0
    private var totalCalories: Int = 0
    
    init(workoutType: String) {
        self.workoutType = workoutType
    }
    
    func start() {
        startTime = Date()
        isRunning = true
    }
    
    func pause() {
        guard isRunning && !isPaused else { return }
        pauseTime = Date()
        isPaused = true
    }
    
    func resume() {
        guard isPaused else { return }
        if let pauseTime = pauseTime {
            totalPausedDuration += Date().timeIntervalSince(pauseTime)
        }
        isPaused = false
    }
    
    func stop() -> WorkoutSummary {
        isRunning = false
        return WorkoutSummary(
            distanceMeters: totalDistance,
            durationSeconds: getCurrentDuration(),
            calories: totalCalories,
            averageHeartRate: 145,
            maxHeartRate: 175
        )
    }
    
    func getCurrentHeartRate() -> Int {
        return 145 // Placeholder
    }
    
    func getCurrentDistance() -> Double {
        return totalDistance
    }
    
    func getCurrentDuration() -> Int {
        guard let start = startTime else { return 0 }
        let elapsed = Date().timeIntervalSince(start) - totalPausedDuration
        return Int(elapsed)
    }
    
    func getCurrentCalories() -> Int {
        return totalCalories
    }
}

struct WorkoutSummary {
    let distanceMeters: Double
    let durationSeconds: Int
    let calories: Int
    let averageHeartRate: Int
    let maxHeartRate: Int
}
```

### 4. Register Plugin in AppDelegate

**File**: `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // Register Garmin plugin
    GarminPlugin.register(with: registrar(forPlugin: "GarminPlugin")!)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Deploy Database Migration

Run the Garmin migration SQL:

```powershell
# Connect to Supabase
# Run: database/migration_garmin_integration.sql
```

## Test the Integration

1. **Hot Reload**: Press `R` in Flutter terminal
2. **Navigate**: Dashboard → More → Garmin Device
3. **Scan**: Tap "Scan for Devices"
4. **Connect**: Select your Garmin watch
5. **Sync**: Tap "Sync Data"

## Next Steps

1. Implement actual Garmin SDK communication (replace placeholders)
2. Add proper HR/GPS sensor reading
3. Implement workout synchronization with Garmin Connect
4. Add error handling and retry logic
5. Test with real Garmin devices

## Resources

- [Garmin Connect Mobile SDK Docs](https://developer.garmin.com/connect-iq/sdk/)
- [Garmin Health SDK iOS](https://developer.garmin.com/health-sdk/overview/)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
