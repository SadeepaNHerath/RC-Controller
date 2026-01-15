import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'controller_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final BleService _bleService = BleService();
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  String? _connectingDeviceId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initBluetooth();
    _listenToDevices();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _listenToDevices() {
    _bleService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() => _devices = devices);
      }
    });
  }

  Future<void> _initBluetooth() async {
    final hasPermission = await _bleService.requestPermissions();
    if (hasPermission) {
      _startScan();
    } else {
      if (mounted) {
        _showMessage('Bluetooth permissions required', isError: true);
      }
    }
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    await _bleService.startScan();
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _connectingDeviceId = device.remoteId.toString();
    });

    final success = await _bleService.connect(device);

    if (mounted) {
      setState(() {
        _connectingDeviceId = null;
      });

      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ControllerScreen(bleService: _bleService),
          ),
        );
      } else {
        _showMessage('Failed to connect', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildDeviceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.gamepad_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RC Controller',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Connect to your device',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildScanButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _isScanning ? null : _startScan,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isScanning
                    ? AppTheme.primaryColor.withAlpha(
                        (100 + 100 * _pulseController.value).toInt(),
                      )
                    : AppTheme.primaryColor.withAlpha(50),
                width: 2,
              ),
            ),
            child: _isScanning
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.primaryColor,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty && !_isScanning) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Available Devices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_devices.length}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              final isConnecting =
                  _connectingDeviceId == device.remoteId.toString();

              return DeviceCard(
                device: device,
                onConnect: () => _connectToDevice(device),
                isConnecting: isConnecting,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.bluetooth_searching_rounded,
              size: 50,
              color: AppTheme.textSecondary.withAlpha(150),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No devices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure your device is powered on\nand in pairing mode',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }
}
