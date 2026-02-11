# Android WiFi Implementation for Garmin Integration

## Overview
This guide shows how to implement WiFi device discovery and connection for Garmin watches in addition to Bluetooth. WiFi offers extended range and faster data transfer.

## Prerequisites
- Android API Level 21+ (Android 5.0)
- Location permission (required for WiFi scanning)
- Same WiFi network for phone and watch

## Gradle Dependencies

**File**: `android/app/build.gradle.kts`

```kotlin
dependencies {
    // Existing dependencies...
    
    // Garmin Connect Mobile SDK
    implementation("com.garmin.connectiq:ciq-companion-app-sdk:2.0.3")
    
    // Network Service Discovery
    implementation("androidx.core:core-ktx:1.12.0")
    
    // WiFi & Network
    implementation("com.google.android.gms:play-services-location:21.0.1")
}
```

## Permissions

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <!-- Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    
    <!-- WiFi permissions -->
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Location permission (required for both BLE and WiFi scanning) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <application>
        <!-- Your app content -->
    </application>
</manifest>
```

## Updated GarminPlugin.kt

**File**: `android/app/src/main/kotlin/com/safestride/akura_mobile/GarminPlugin.kt`

Add WiFi scanning capabilities:

```kotlin
package com.safestride.akura_mobile

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket

class GarminPlugin(private val context: Context, private val flutterEngine: FlutterEngine) {
    
    companion object {
        private const val CHANNEL = "com.safestride/garmin"
        private const val SERVICE_TYPE = "_garmin._tcp."
    }
    
    private lateinit var methodChannel: MethodChannel
    private val handler = Handler(Looper.getMainLooper())
    
    // WiFi components
    private val wifiManager: WifiManager by lazy {
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }
    
    private val nsdManager: NsdManager by lazy {
        context.getSystemService(Context.NSD_SERVICE) as NsdManager
    }
    
    private var discoveryListener: NsdManager.DiscoveryListener? = null
    private val discoveredWiFiDevices = mutableListOf<GarminWiFiDevice>()
    
    fun initialize() {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }
    
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanDevices" -> scanDevices(call, result)
            "scanWiFiDevices" -> scanWiFiDevices(call, result)
            "scanBluetoothDevices" -> scanBluetoothDevices(call, result)
            "connectDevice" -> connectDevice(call, result)
            else -> result.notImplemented()
        }
    }
    
    // === Combined Scan (WiFi + Bluetooth) ===
    
    private fun scanDevices(call: MethodCall, result: MethodChannel.Result) {
        val duration = call.argument<Int>("duration") ?: 10
        val connectionType = call.argument<String>("connectionType") ?: "both"
        
        val allDevices = mutableListOf<JSONObject>()
        
        when (connectionType) {
            "wifi" -> {
                scanWiFiDevicesInternal(duration) { wifiDevices ->
                    allDevices.addAll(wifiDevices)
                    result.success(JSONArray(allDevices).toString())
                }
            }
            "bluetooth" -> {
                scanBluetoothDevicesInternal(duration) { btDevices ->
                    allDevices.addAll(btDevices)
                    result.success(JSONArray(allDevices).toString())
                }
            }
            "both" -> {
                // Scan both simultaneously
                var wifiComplete = false
                var btComplete = false
                val wifiDevices = mutableListOf<JSONObject>()
                val btDevices = mutableListOf<JSONObject>()
                
                scanWiFiDevicesInternal(duration) { devices ->
                    wifiDevices.addAll(devices)
                    wifiComplete = true
                    if (btComplete) {
                        allDevices.addAll(wifiDevices + btDevices)
                        result.success(JSONArray(allDevices).toString())
                    }
                }
                
                scanBluetoothDevicesInternal(duration) { devices ->
                    btDevices.addAll(devices)
                    btComplete = true
                    if (wifiComplete) {
                        allDevices.addAll(wifiDevices + btDevices)
                        result.success(JSONArray(allDevices).toString())
                    }
                }
            }
            else -> result.error("INVALID_TYPE", "Invalid connection type", null)
        }
    }
    
    // === WiFi Scanning ===
    
    private fun scanWiFiDevices(call: MethodCall, result: MethodChannel.Result) {
        val duration = call.argument<Int>("duration") ?: 10
        scanWiFiDevicesInternal(duration) { devices ->
            result.success(JSONArray(devices).toString())
        }
    }
    
    private fun scanWiFiDevicesInternal(
        durationSeconds: Int,
        callback: (List<JSONObject>) -> Unit
    ) {
        if (!checkWiFiPermissions()) {
            callback(emptyList())
            return
        }
        
        discoveredWiFiDevices.clear()
        
        // Start network service discovery
        discoveryListener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {
                // Discovery started
            }
            
            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                if (isGarminService(serviceInfo)) {
                    resolveService(serviceInfo)
                }
            }
            
            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                // Service lost, remove from list
                discoveredWiFiDevices.removeAll { it.serviceName == serviceInfo.serviceName }
            }
            
            override fun onDiscoveryStopped(serviceType: String) {
                // Discovery stopped
            }
            
            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                // Failed to start
                callback(emptyList())
            }
            
            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                // Failed to stop
            }
        }
        
        try {
            nsdManager.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
            
            // Stop discovery after duration
            handler.postDelayed({
                stopWiFiDiscovery()
                
                // Convert to JSON
                val devices = discoveredWiFiDevices.map { device ->
                    JSONObject().apply {
                        put("id", device.deviceId)
                        put("name", device.deviceName)
                        put("connection_type", "wifi")
                        put("ip_address", device.ipAddress)
                        put("port", device.port)
                        put("signal_strength", calculateSignalStrength(device.ipAddress))
                    }
                }
                
                callback(devices)
            }, (durationSeconds * 1000).toLong())
            
        } catch (e: Exception) {
            callback(emptyList())
        }
    }
    
    private fun resolveService(serviceInfo: NsdServiceInfo) {
        val resolveListener = object : NsdManager.ResolveListener {
            override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                // Resolution failed
            }
            
            override fun onServiceResolved(resolvedService: NsdServiceInfo) {
                val device = GarminWiFiDevice(
                    deviceId = resolvedService.serviceName,
                    deviceName = resolvedService.serviceName,
                    serviceName = resolvedService.serviceName,
                    ipAddress = resolvedService.host.hostAddress ?: "",
                    port = resolvedService.port
                )
                
                if (!discoveredWiFiDevices.any { it.deviceId == device.deviceId }) {
                    discoveredWiFiDevices.add(device)
                }
            }
        }
        
        try {
            nsdManager.resolveService(serviceInfo, resolveListener)
        } catch (e: Exception) {
            // Resolution failed
        }
    }
    
    private fun stopWiFiDiscovery() {
        try {
            discoveryListener?.let {
                nsdManager.stopServiceDiscovery(it)
            }
            discoveryListener = null
        } catch (e: Exception) {
            // Ignore
        }
    }
    
    private fun isGarminService(serviceInfo: NsdServiceInfo): Boolean {
        val name = serviceInfo.serviceName.lowercase()
        return name.contains("garmin") ||
               name.contains("forerunner") ||
               name.contains("fenix") ||
               name.contains("vivoactive") ||
               name.contains("venu")
    }
    
    private fun calculateSignalStrength(ipAddress: String): Int {
        // Ping device to check connectivity
        return try {
            val socket = Socket()
            val startTime = System.currentTimeMillis()
            socket.connect(InetSocketAddress(ipAddress, 80), 2000)
            val latency = System.currentTimeMillis() - startTime
            socket.close()
            
            // Calculate strength based on latency
            when {
                latency < 50 -> 100  // Excellent
                latency < 100 -> 80  // Good
                latency < 200 -> 60  // Fair
                else -> 40           // Weak
            }
        } catch (e: Exception) {
            20  // Very weak or unreachable
        }
    }
    
    // === Bluetooth Scanning ===
    
    private fun scanBluetoothDevices(call: MethodCall, result: MethodChannel.Result) {
        val duration = call.argument<Int>("duration") ?: 10
        scanBluetoothDevicesInternal(duration) { devices ->
            result.success(JSONArray(devices).toString())
        }
    }
    
    private fun scanBluetoothDevicesInternal(
        durationSeconds: Int,
        callback: (List<JSONObject>) -> Unit
    ) {
        // Implement Bluetooth scanning (similar to previous implementation)
        // Refer to GARMIN_DEVELOPER_GUIDE.md for full Bluetooth implementation
        
        // Placeholder: Return empty list
        handler.postDelayed({
            callback(emptyList())
        }, (durationSeconds * 1000).toLong())
    }
    
    // === Device Connection ===
    
    private fun connectDevice(call: MethodCall, result: MethodChannel.Result) {
        val deviceId = call.argument<String>("deviceId")
        val connectionType = call.argument<String>("connectionType") ?: "bluetooth"
        val ipAddress = call.argument<String>("ipAddress")
        
        if (deviceId == null) {
            result.error("INVALID_ARGUMENT", "deviceId is required", null)
            return
        }
        
        when (connectionType) {
            "wifi" -> connectViaWiFi(deviceId, ipAddress, result)
            "bluetooth" -> connectViaBluetooth(deviceId, result)
            else -> result.error("INVALID_TYPE", "Invalid connection type", null)
        }
    }
    
    private fun connectViaWiFi(
        deviceId: String,
        ipAddress: String?,
        result: MethodChannel.Result
    ) {
        if (ipAddress == null) {
            result.error("INVALID_ARGUMENT", "ipAddress required for WiFi connection", null)
            return
        }
        
        try {
            // Test connection to device
            val socket = Socket()
            socket.connect(InetSocketAddress(ipAddress, 8080), 5000)
            
            // Connection successful
            socket.close()
            result.success(true)
            
        } catch (e: Exception) {
            result.error("CONNECTION_FAILED", "WiFi connection failed: ${e.message}", null)
        }
    }
    
    private fun connectViaBluetooth(deviceId: String, result: MethodChannel.Result) {
        // Implement Bluetooth connection (refer to GARMIN_DEVELOPER_GUIDE.md)
        result.success(false)
    }
    
    // === Helper Methods ===
    
    private fun checkWiFiPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    fun dispose() {
        stopWiFiDiscovery()
        methodChannel.setMethodCallHandler(null)
    }
}

// === Data Classes ===

data class GarminWiFiDevice(
    val deviceId: String,
    val deviceName: String,
    val serviceName: String,
    val ipAddress: String,
    val port: Int
)
```

## WiFi Communication Protocol

### Device Discovery Flow
```
1. App broadcasts mDNS query for "_garmin._tcp." service
2. Garmin watch responds with service info:
   - Service name: "Garmin-Fenix7-ABC123"
   - IP address: 192.168.1.25
   - Port: 8080
3. App resolves service to get full details
4. App displays device in scan results
```

### Connection Flow
```
1. User taps device from scan results
2. App extracts IP address and port
3. App creates TCP socket connection to watch
4. Handshake: App sends authentication token
5. Watch validates token and responds with device info
6. Connection established, ready for data transfer
```

### Data Sync Protocol
```
1. App sends sync request with date range
2. Watch prepares workout data (FIT files)
3. Watch streams data in chunks (4KB each)
4. App receives and parses FIT files
5. App saves to local database
6. App syncs to Supabase cloud
```

## Testing WiFi Connection

### Test on Same Network
1. Connect phone to WiFi: "MyHomeWiFi"
2. On Garmin watch: Settings → Connectivity → Wi-Fi → Add "MyHomeWiFi"
3. Open SafeStride app
4. Select "WiFi" connection type
5. Tap "Scan for Devices"
6. Watch should appear in ~5 seconds
7. Tap watch to connect

### Test Connection Quality
```kotlin
// Add to GarminPlugin.kt
private fun testWiFiConnection(ipAddress: String): ConnectionQuality {
    val speeds = mutableListOf<Long>()
    
    repeat(5) {
        val startTime = System.nanoTime()
        val socket = Socket()
        socket.connect(InetSocketAddress(ipAddress, 8080), 1000)
        val latency = (System.nanoTime() - startTime) / 1_000_000
        speeds.add(latency)
        socket.close()
    }
    
    val avgLatency = speeds.average()
    
    return when {
        avgLatency < 50 -> ConnectionQuality.EXCELLENT
        avgLatency < 100 -> ConnectionQuality.GOOD
        avgLatency < 200 -> ConnectionQuality.FAIR
        else -> ConnectionQuality.POOR
    }
}

enum class ConnectionQuality {
    EXCELLENT, GOOD, FAIR, POOR
}
```

## Troubleshooting

### Device Not Found
1. Check permissions granted
2. Verify same WiFi network
3. Restart NSD Manager
4. Check service type string

### Connection Timeout
1. Increase connection timeout (5000ms → 10000ms)
2. Check firewall settings
3. Test with ping command
4. Verify port 8080 open

### Slow Data Transfer
1. Check WiFi signal strength
2. Reduce chunk size (4KB → 2KB)
3. Add retry logic
4. Use compression for FIT files

## Performance Optimization

### Caching
```kotlin
// Cache resolved services
private val serviceCache = mutableMapOf<String, GarminWiFiDevice>()

private fun getCachedOrResolve(serviceInfo: NsdServiceInfo): GarminWiFiDevice? {
    val cached = serviceCache[serviceInfo.serviceName]
    if (cached != null) return cached
    
    // Resolve and cache
    resolveService(serviceInfo)
    return null
}
```

### Connection Pooling
```kotlin
// Reuse connections
private val connectionPool = mutableMapOf<String, Socket>()

private fun getConnection(ipAddress: String, port: Int): Socket {
    val key = "$ipAddress:$port"
    var socket = connectionPool[key]
    
    if (socket == null || socket.isClosed) {
        socket = Socket()
        socket.connect(InetSocketAddress(ipAddress, port), 5000)
        connectionPool[key] = socket
    }
    
    return socket
}
```

## Next Steps

1. Implement full Bluetooth scanning (refer to main guide)
2. Add WiFi Direct support (for Android 4.0+)
3. Implement secure pairing (OAuth token exchange)
4. Add connection monitoring (detect disconnects)
5. Implement retry logic for failed transfers

## Resources

- [Android NsdManager Docs](https://developer.android.com/reference/android/net/nsd/NsdManager)
- [mDNS Protocol Spec](https://tools.ietf.org/html/rfc6762)
- [Garmin FIT SDK](https://developer.garmin.com/fit/overview/)

---

**File**: `android/app/src/main/kotlin/com/safestride/akura_mobile/MainActivity.kt`

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var garminPlugin: GarminPlugin? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Garmin plugin with WiFi support
        garminPlugin = GarminPlugin(this, flutterEngine)
        garminPlugin?.initialize()
    }
    
    override fun onDestroy() {
        garminPlugin?.dispose()
        super.onDestroy()
    }
}
```

Deploy the updated migration SQL and test WiFi connectivity!
