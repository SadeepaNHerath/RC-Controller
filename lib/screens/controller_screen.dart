import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ControllerScreen extends StatefulWidget {
  final BleService bleService;

  const ControllerScreen({super.key, required this.bleService});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  final TextEditingController _commandController = TextEditingController();
  String? _lastCommand;

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  void _sendCommand(String command) {
    widget.bleService.sendCommand(command);
    setState(() => _lastCommand = command);
    HapticFeedback.lightImpact();
  }

  void _stopMovement() {
    _sendCommand('S');
  }

  void _disconnect() async {
    await widget.bleService.disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showCharacteristicSelector() {
    final characteristics = widget.bleService.getWritableCharacteristics();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCharacteristicSheet(characteristics),
    );
  }

  Widget _buildCharacteristicSheet(
      List<BluetoothCharacteristic> characteristics) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select TX Characteristic',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose which characteristic to send commands to',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (characteristics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No writable characteristics found',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: characteristics.length,
              itemBuilder: (context, index) {
                final char = characteristics[index];
                final isSelected =
                    widget.bleService.writeCharacteristic?.uuid == char.uuid;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withAlpha(30)
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                    ),
                    title: Text(
                      char.uuid.toString().substring(4, 8).toUpperCase(),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Service: ${char.serviceUuid.toString().substring(4, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: char.properties.writeWithoutResponse
                        ? const Chip(
                            label: Text('Fast'),
                            backgroundColor: AppTheme.successColor,
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                    onTap: () {
                      widget.bleService.setWriteCharacteristic(char);
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Selected: ${char.uuid.toString().substring(4, 8).toUpperCase()}',
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.bleService.connectedDevice;
    final characteristic = widget.bleService.writeCharacteristic;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ConnectionStatusBar(
              deviceName: device?.platformName ?? 'Unknown Device',
              characteristicId: characteristic?.uuid.toString(),
              onSettings: _showCharacteristicSelector,
              onDisconnect: _disconnect,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ControlPad(
                        onCommand: _sendCommand,
                        onStop: _stopMovement,
                      ),
                      const SizedBox(height: 32),
                      _buildCommandInput(),
                      if (_lastCommand != null) ...[
                        const SizedBox(height: 16),
                        _buildLastCommandIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Custom command...',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _sendCommand(value);
                  _commandController.clear();
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: () {
                if (_commandController.text.isNotEmpty) {
                  _sendCommand(_commandController.text);
                  _commandController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SEND',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastCommandIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Last: $_lastCommand',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
