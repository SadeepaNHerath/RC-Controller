import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/commands/rc_commands.dart';
import 'package:helmrc/profiles/builtin_profiles.dart';
import 'package:helmrc/profiles/device_profile.dart';
import 'package:helmrc/theme/app_theme.dart';
import 'package:helmrc/widgets/profile_editor_sheet.dart';

void main() {
  testWidgets('profile editor saves an edited map', (tester) async {
    DeviceProfile? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  saved = await showProfileEditorSheet(
                    context: context,
                    profile: BuiltinProfiles.custom(),
                  );
                },
                child: const Text('Open editor'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Custom command map'), findsOneWidget);
    expect(find.text('Append newline'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'GO');
    await tester.tap(find.text('Append newline'));
    await tester.pump();
    await tester.tap(find.text('Save profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(saved, isNotNull);
    expect(saved!.editable, isTrue);
    expect(saved!.appendNewline, isTrue);
    expect(saved!.encode(RcCommands.forward), 'GO\n');
  });
}
