import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../commands/rc_commands.dart';
import '../models/ble_connection_state.dart';
import '../radio/ble_tx_option.dart';
import '../radio/rc_link.dart';
import '../radio/send_result.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final RcLink _link = RcLink.instance;
  final TextEditingController _commandController = TextEditingController();
  late final TabController _tabController;
  StreamSubscription<BleConnectionState>? _connectionSub;

  String? _lastCommand;
  bool _lastCommandOk = true;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    WakelockPlus.enable();

    _connectionSub = _link.connectionStateStream.listen((state) {
      if (!mounted || _leaving) return;
      if (state == BleConnectionState.disconnected ||
          state == BleConnectionState.error) {
        _leaveOnLinkLoss();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSub?.cancel();
    _commandController.dispose();
    _tabController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _link.emergencyStop();
    }
  }

  Future<void> _sendLogical(String command) async {
    final result = await _link.sendLogical(command);
    if (!mounted) return;
    _handleSend(command, result);
  }

  Future<void> _sendRaw(String command) async {
    final result = await _link.sendRaw(command);
    if (!mounted) return;
    _handleSend(command, result);
  }

  void _handleSend(String command, SendResult result) {
    setState(() {
      _lastCommand = command;
      _lastCommandOk = result != SendResult.failed;
    });
    if (result == SendResult.sent) {
      HapticFeedback.lightImpact();
    } else if (result == SendResult.failed) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Command failed. Check the Bluetooth link.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _emergencyStop() async {
    HapticFeedback.heavyImpact();
    await _link.emergencyStop();
    if (mounted) {
      setState(() {
        _lastCommand = RcCommands.allStop;
        _lastCommandOk = true;
      });
    }
  }

  Future<void> _leave({required bool sendFailSafe}) async {
    if (_leaving) return;
    _leaving = true;
    await _link.disconnect(sendFailSafe: sendFailSafe);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _leaveOnLinkLoss() async {
    if (_leaving) return;
    _leaving = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection lost. Vehicle stop was requested.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDisconnect() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Disconnect?'),
        content: const Text(
          'The controller will send a stop command, then close the Bluetooth link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Disconnect',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (shouldLeave == true) {
      await _leave(sendFailSafe: true);
    }
  }

  void _showCharacteristicSelector() {
    final characteristics = _link.getWritableCharacteristics();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCharacteristicSheet(characteristics),
    );
  }

  Widget _buildCharacteristicSheet(List<BleTxOption> characteristics) {
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
                final option = characteristics[index];
                final isSelected = _link.selectedTxId == option.id;

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
                      option.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Service: ${option.serviceId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: option.fast
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
                      _link.setWriteCharacteristic(option.id);
                      setState(() {});
                      Navigator.pop(context);
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
    final device = _link.connectedDevice;
    final subtitle = _link.hasTxSettings
        ? (_link.linkLabel != null ? 'TX: ${_link.linkLabel}' : 'No TX selected')
        : (_link.linkLabel ?? 'Serial (SPP)');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDisconnect();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ConnectionStatusBar(
                deviceName: device?.name.isNotEmpty == true
                    ? device!.name
                    : 'RC Device',
                subtitle: subtitle,
                onSettings:
                    _link.hasTxSettings ? _showCharacteristicSelector : null,
                onDisconnect: _confirmDisconnect,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(50),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.gamepad_rounded),
                      text: 'MOVEMENT',
                    ),
                    Tab(
                      icon: Icon(Icons.precision_manufacturing_rounded),
                      text: 'ARMS',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            ControlPad(
                              onCommand: _sendLogical,
                              onStop: () => _sendLogical(RcCommands.stop),
                            ),
                            const SizedBox(height: 24),
                            _buildCommandInput(),
                            if (_lastCommand != null) ...[
                              const SizedBox(height: 16),
                              _buildLastCommandIndicator(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    ArmsControlTab(
                      onCommand: _sendLogical,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _emergencyStop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.stop_circle),
                    label: const Text(
                      'EMERGENCY STOP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              style: const TextStyle(color: AppTheme.textPrimary),
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Custom command…',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (value) {
                final command = value.trim();
                if (command.isEmpty) return;
                _sendRaw(command);
                _commandController.clear();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: () {
                final command = _commandController.text.trim();
                if (command.isEmpty) return;
                _sendRaw(command);
                _commandController.clear();
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
            decoration: BoxDecoration(
              color:
                  _lastCommandOk ? AppTheme.successColor : AppTheme.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _lastCommandOk ? 'Last: $_lastCommand' : 'Failed: $_lastCommand',
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
