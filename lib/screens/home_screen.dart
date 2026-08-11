import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app/app_info.dart';
import '../models/ble_prep_result.dart';
import '../profiles/builtin_profiles.dart';
import '../profiles/device_profile.dart';
import '../radio/radio_device.dart';
import '../radio/radio_kind.dart';
import '../radio/rc_link.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'controller_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final RcLink _link = RcLink.instance;
  final List<StreamSubscription> _subscriptions = [];

  List<RadioDevice> _devices = [];
  bool _isScanning = false;
  int _radioEpoch = 0;
  String? _connectingDeviceId;
  BlePrepResult? _prepResult;
  RadioKind _kind = RadioKind.ble;
  DeviceProfile _profile = BuiltinProfiles.helmrc;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _link.restore();
    if (!mounted) return;
    setState(() {
      _kind = _link.kind;
      _profile = _link.profile;
    });
    _subscriptions.add(
      _link.devicesStream.listen((devices) {
        if (mounted) setState(() => _devices = devices);
      }),
    );
    _subscriptions.add(
      _link.adapterOnStream.listen((on) {
        if (!mounted) return;
        if (on && _prepResult == BlePrepResult.bluetoothOff) {
          _initRadio();
        }
      }),
    );
    _subscriptions.add(
      _link.kindStream.listen((kind) {
        if (mounted) setState(() => _kind = kind);
      }),
    );
    _subscriptions.add(
      _link.profileStream.listen((profile) {
        if (mounted) setState(() => _profile = profile);
      }),
    );
    await _initRadio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_prepResult == BlePrepResult.permissionDenied ||
            _prepResult == BlePrepResult.bluetoothOff)) {
      _initRadio();
    }
  }

  Future<void> _initRadio() async {
    final epoch = ++_radioEpoch;
    var result = BlePrepResult.unsupported;
    try {
      result = await _link.ensureReady();
    } catch (error) {
      debugPrint('Radio init failed: $error');
      result = BlePrepResult.unsupported;
    }
    if (!mounted || epoch != _radioEpoch) return;
    setState(() => _prepResult = result);
    if (result == BlePrepResult.ready) {
      await _startScan();
    }
  }

  Future<void> _startScan() async {
    final epoch = ++_radioEpoch;
    setState(() => _isScanning = true);
    try {
      final result = await _link.ensureReady();
      if (!mounted) return;
      if (result != BlePrepResult.ready) {
        if (mounted && epoch == _radioEpoch) {
          setState(() {
            _prepResult = result;
            _isScanning = false;
          });
        }
        return;
      }
      if (mounted && epoch == _radioEpoch) {
        setState(() => _prepResult = BlePrepResult.ready);
      }
      await _link.startScan();
    } catch (error) {
      if (mounted && epoch == _radioEpoch) {
        _showMessage('Scan failed. Try again.', isError: true);
      }
      debugPrint('Scan failed: $error');
    } finally {
      if (mounted && epoch == _radioEpoch) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _setKind(RadioKind kind) async {
    if (kind == RadioKind.classic && !_link.classicSupported) {
      _showMessage(
        'Classic serial is Android-only. iOS can use BLE UART devices.',
        isError: true,
      );
      return;
    }
    final ok = await _link.setKind(kind);
    if (!mounted) return;
    if (!ok) return;
    setState(() {
      _devices = [];
      _connectingDeviceId = null;
      _isScanning = false;
    });
    await _initRadio();
  }

  Future<void> _setProfile(DeviceProfile? profile) async {
    if (profile == null) return;
    await _link.setProfile(profile);
  }

  Future<void> _editCustomProfile() async {
    final custom = _link.profiles.firstWhere(
      (item) => item.id == BuiltinProfiles.customId,
    );
    final updated = await showProfileEditorSheet(
      context: context,
      profile: custom,
    );
    if (updated == null || !mounted) return;
    await _link.setProfile(updated);
  }

  Future<void> _connectToDevice(RadioDevice device) async {
    if (_connectingDeviceId != null) return;

    setState(() => _connectingDeviceId = device.id);
    final success = await _link.connect(device);
    if (!mounted) return;

    setState(() => _connectingDeviceId = null);

    if (success) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ControllerScreen(),
        ),
      );
      if (mounted) _startScan();
    } else {
      _showMessage(
        'Could not connect. Check the device and try again.',
        isError: true,
      );
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
            _buildRadioAndProfile(),
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
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
                  AppInfo.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  AppInfo.developer,
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
    );
  }

  Widget _buildRadioAndProfile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<RadioKind>(
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryColor.withAlpha(40);
                }
                return AppTheme.cardColor;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppTheme.textSecondary.withAlpha(80);
                }
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryColor;
                }
                return AppTheme.textSecondary;
              }),
            ),
            segments: [
              const ButtonSegment(
                value: RadioKind.ble,
                label: Text('BLE'),
                icon: Icon(Icons.bluetooth),
              ),
              ButtonSegment(
                value: RadioKind.classic,
                label: const Text('Classic'),
                icon: const Icon(Icons.settings_input_antenna),
                enabled: _link.classicSupported,
                tooltip: _link.classicSupported
                    ? 'Android Classic serial (HC-05 / SPP)'
                    : 'Classic serial is Android-only',
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (selected) => _setKind(selected.first),
          ),
          if (!_link.classicSupported) ...[
            const SizedBox(height: 8),
            const Text(
              'Classic serial is Android-only. iOS stays BLE.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Car profile',
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _profile.id,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceColor,
                      items: [
                        for (final profile in _link.profiles)
                          DropdownMenuItem(
                            value: profile.id,
                            child: Text(profile.name),
                          ),
                      ],
                      onChanged: (id) {
                        final match = _link.profiles.where((item) => item.id == id);
                        _setProfile(match.isEmpty ? null : match.first);
                      },
                    ),
                  ),
                ),
              ),
              if (_profile.editable) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _editCustomProfile,
                  tooltip: 'Edit custom commands',
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.primaryColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Text(
        AppInfo.tagline,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
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

  Widget _buildBody() {
    switch (_prepResult) {
      case BlePrepResult.bluetoothOff:
        return _buildStatusState(
          icon: Icons.bluetooth_disabled,
          title: 'Bluetooth is off',
          message: 'Turn on Bluetooth to scan for your RC device.',
          actionLabel: 'Try again',
          onAction: _initRadio,
        );
      case BlePrepResult.permissionDenied:
        return _buildStatusState(
          icon: Icons.lock_outline,
          title: 'Permissions required',
          message:
              'Bluetooth permission is needed to find and control your RC device.',
          actionLabel: 'Open settings',
          onAction: openAppSettings,
        );
      case BlePrepResult.unsupported:
        return _buildStatusState(
          icon: Icons.error_outline,
          title: 'Bluetooth unavailable',
          message: _kind == RadioKind.classic
              ? 'Classic Bluetooth serial is not available on this device.'
              : 'This device does not support Bluetooth Low Energy.',
        );
      case BlePrepResult.ready:
      case null:
        if (_devices.isEmpty) {
          return _buildEmptyState();
        }
        return _buildDeviceList();
    }
  }

  Widget _buildDeviceList() {
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
              final showPairedHeader = device.paired && index == 0;
              final showNearbyHeader = !device.paired &&
                  (index == 0 || _devices[index - 1].paired);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPairedHeader) _sectionLabel('Paired'),
                  if (showNearbyHeader) _sectionLabel('Nearby'),
                  DeviceCard(
                    name: device.name,
                    id: device.id,
                    rssi: device.rssi,
                    paired: device.paired,
                    showRssi: device.kind == RadioKind.ble,
                    onConnect: () => _connectToDevice(device),
                    isConnecting: _connectingDeviceId == device.id,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final classic = _kind == RadioKind.classic;
    return _buildStatusState(
      icon: Icons.bluetooth_searching_rounded,
      title: _isScanning ? 'Scanning…' : 'No devices found',
      message: _isScanning
          ? (classic
              ? 'Looking for paired and nearby serial devices.'
              : 'Looking for nearby BLE devices.')
          : (classic
              ? 'Pair HC-05/HC-06 in Android Bluetooth settings, then scan.'
              : 'Power on the RC device and keep it in range.'),
      actionLabel: _isScanning ? null : 'Scan again',
      onAction: _isScanning ? null : _startScan,
    );
  }

  Widget _buildStatusState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
                icon,
                size: 50,
                color: AppTheme.textSecondary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
