import 'package:flutter/material.dart';

import '../commands/rc_commands.dart';
import '../profiles/device_profile.dart';
import '../theme/app_theme.dart';

Future<DeviceProfile?> showProfileEditorSheet({
  required BuildContext context,
  required DeviceProfile profile,
}) {
  return showModalBottomSheet<DeviceProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ProfileEditorSheet(profile: profile),
  );
}

class _ProfileEditorSheet extends StatefulWidget {
  const _ProfileEditorSheet({required this.profile});

  final DeviceProfile profile;

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  late final Map<String, TextEditingController> _controllers;
  late bool _appendNewline;

  @override
  void initState() {
    super.initState();
    _appendNewline = widget.profile.appendNewline;
    _controllers = {
      for (final key in RcCommands.allLogical)
        key: TextEditingController(text: widget.profile.wireMap[key] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final wireMap = <String, String>{};
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        wireMap[entry.key] = value;
      }
    }
    Navigator.pop(
      context,
      widget.profile.copyWith(
        wireMap: wireMap,
        appendNewline: _appendNewline,
        editable: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        margin: EdgeInsets.only(bottom: bottom),
        child: Column(
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
          const SizedBox(height: 16),
          const Text(
            'Custom command map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Set the bytes sent for each pad. Leave a field empty to skip that button.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          SwitchListTile(
            value: _appendNewline,
            onChanged: (value) => setState(() => _appendNewline = value),
            title: const Text('Append newline'),
            subtitle: const Text(r'Adds \n after each command'),
            activeThumbColor: AppTheme.primaryColor,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: RcCommands.allLogical.length,
              itemBuilder: (context, index) {
                final key = RcCommands.allLogical[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllers[key],
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: key,
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save profile'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
