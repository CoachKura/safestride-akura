import 'package:flutter/material.dart';
import '../services/garmin_connect_service.dart';

class GarminDeviceScreen extends StatefulWidget {
  const GarminDeviceScreen({super.key});

  @override
  State<GarminDeviceScreen> createState() => _GarminDeviceScreenState();
}

class _GarminDeviceScreenState extends State<GarminDeviceScreen> {
  bool _isScanning = false;
  bool _isConnecting = false;
  List<Map<String, dynamic>> _availableDevices = [];
  Map<String, dynamic>? _connectedDevice;
  int? _batteryLevel;
  String _selectedConnectionType = 'both'; // 'bluetooth', 'wifi', or 'both'

  @override
  void initState() {
    super.initState();
    _initializeGarmin();
  }

  Future<void> _initializeGarmin() async {
    final initialized = await GarminConnectService.initialize();
    if (initialized && GarminConnectService.isConnected) {
      _loadConnectedDevice();
    }
  }

  Future<void> _loadConnectedDevice() async {
    final status = await GarminConnectService.getDeviceStatus();
    if (status['connected'] == true) {
      setState(() {
        _connectedDevice = status;
        _batteryLevel = status['battery_level'];
      });
    }
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _availableDevices = [];
    });

    try {
      List<Map<String, dynamic>> devices = [];

      // Scan based on selected connection type
      if (_selectedConnectionType == 'bluetooth') {
        devices = await GarminConnectService.scanBluetoothDevices(
            durationSeconds: 10);
      } else if (_selectedConnectionType == 'wifi') {
        devices =
            await GarminConnectService.scanWiFiDevices(durationSeconds: 10);
      } else {
        // Scan both
        devices = await GarminConnectService.scanForDevices(
          durationSeconds: 10,
          connectionType: 'both',
        );
      }

      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });

      if (devices.isEmpty) {
        _showMessage('No Garmin devices found nearby', isError: true);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showMessage('Error scanning for devices: $e', isError: true);
    }
  }

  Future<void> _connectDevice(String deviceId, String deviceName,
      {String? connectionType, String? ipAddress}) async {
    setState(() => _isConnecting = true);

    try {
      final connected = await GarminConnectService.connectToDevice(
        deviceId,
        connectionType: connectionType ?? _selectedConnectionType,
        ipAddress: ipAddress,
      );

      if (connected) {
        await _loadConnectedDevice();
        _showMessage(
            'Connected to $deviceName via ${connectionType ?? _selectedConnectionType}');
        setState(() {
          _availableDevices = [];
        });
      } else {
        _showMessage('Failed to connect to $deviceName', isError: true);
      }
    } catch (e) {
      _showMessage('Error connecting: $e', isError: true);
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Device'),
        content: const Text('Are you sure you want to disconnect this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final disconnected = await GarminConnectService.disconnect();
      if (disconnected) {
        setState(() {
          _connectedDevice = null;
          _batteryLevel = null;
        });
        _showMessage('Device disconnected');
      }
    }
  }

  Future<void> _syncData() async {
    _showMessage('Syncing workout data...');

    try {
      final workouts = await GarminConnectService.syncHistoricalData(days: 7);
      _showMessage('Successfully synced ${workouts.length} workouts');
    } catch (e) {
      _showMessage('Error syncing data: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Garmin Device'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _syncData,
              tooltip: 'Sync Data',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connected Device Card
            if (_connectedDevice != null) ...[
              _buildConnectedDeviceCard(),
              const SizedBox(height: 24),
              _buildDeviceControls(),
              const SizedBox(height: 24),
            ],

            // Scan Section
            if (_connectedDevice == null) ...[
              _buildScanSection(),
              const SizedBox(height: 24),
            ],

            // Available Devices
            if (_availableDevices.isNotEmpty) ...[
              const Text(
                'Available Devices',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._availableDevices.map((device) => _buildDeviceCard(device)),
            ],

            // Setup Instructions
            if (_connectedDevice == null &&
                _availableDevices.isEmpty &&
                !_isScanning) ...[
              _buildSetupInstructions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceCard() {
    final deviceName = _connectedDevice!['device_name'] ?? 'Garmin Device';
    final deviceInfo =
        _connectedDevice!['device_info'] as Map<String, dynamic>?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.watch, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_batteryLevel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _batteryLevel! > 20
                            ? Icons.battery_full
                            : Icons.battery_alert,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_batteryLevel%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (deviceInfo != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (deviceInfo['model'] != null)
                  _buildInfoChip(Icons.info_outline, deviceInfo['model']),
                if (deviceInfo['firmware'] != null)
                  _buildInfoChip(Icons.system_update, deviceInfo['firmware']),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Controls',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _syncData,
                icon: const Icon(Icons.sync),
                label: const Text('Sync Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _disconnectDevice,
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScanSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.watch,
            size: 64,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect Your Garmin Device',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose connection type and scan for nearby devices',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Connection Type Selector
          const Text(
            'Connection Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildConnectionTypeChip('wifi', Icons.wifi, 'WiFi'),
              _buildConnectionTypeChip(
                  'bluetooth', Icons.bluetooth, 'Bluetooth'),
              _buildConnectionTypeChip('both', Icons.devices, 'Both'),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isScanning || _isConnecting ? null : _scanForDevices,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTypeChip(String type, IconData icon, String label) {
    final isSelected = _selectedConnectionType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedConnectionType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final deviceName = device['name'] ?? 'Unknown Device';
    final deviceId = device['id'] ?? '';
    final signalStrength = device['signal_strength'] as int? ?? 0;
    final connectionType = device['connection_type'] ?? _selectedConnectionType;
    final ipAddress = device['ip_address'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
          child: Icon(
            connectionType == 'wifi' ? Icons.wifi : Icons.bluetooth,
            color: Colors.deepPurple,
          ),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signal: ${signalStrength > 0 ? "Strong" : "Weak"}'),
            if (connectionType == 'wifi' && ipAddress != null)
              Text('IP: $ipAddress',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: _isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: _isConnecting
            ? null
            : () => _connectDevice(
                  deviceId,
                  deviceName,
                  connectionType: connectionType,
                  ipAddress: ipAddress,
                ),
      ),
    );
  }

  Widget _buildSetupInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Setup Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            1,
            'Turn on your Garmin device',
            'Make sure your watch is powered on and nearby',
          ),
          _buildInstructionStep(
            2,
            'Choose connection type',
            'Select WiFi (if on same network), Bluetooth, or Both above',
          ),
          _buildInstructionStep(
            3,
            'Enable connectivity',
            'WiFi: Connect watch to same WiFi network. Bluetooth: Enable Bluetooth on both devices',
          ),
          _buildInstructionStep(
            4,
            'Tap "Scan for Devices"',
            'Wait for your device to appear in the list',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
