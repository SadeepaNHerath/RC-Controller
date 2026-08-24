import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/radio/rc_link.dart';
import 'package:helmrc/screens/controller_screen.dart';
import 'package:helmrc/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RcLink.instance.restore();
    for (final channel in [
      'wakelock_plus',
      'dev.fluttercommunity.plus/wakelock',
      'wakelock_plus_macos',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel(channel),
        (call) async => true,
      );
    }
  });

  tearDown(() {
    for (final channel in [
      'wakelock_plus',
      'dev.fluttercommunity.plus/wakelock',
      'wakelock_plus_macos',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  testWidgets('controller renders pads, tabs, e-stop, and custom input',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ControllerScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('RC Device'), findsOneWidget);
    expect(find.text('No TX selected'), findsOneWidget);
    expect(find.text('MOVEMENT'), findsOneWidget);
    expect(find.text('ARMS'), findsOneWidget);
    expect(find.text('FWD'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('Custom command…'), findsOneWidget);
    expect(find.text('EMERGENCY STOP'), findsOneWidget);
    expect(find.text('SEND'), findsOneWidget);

    await tester.tap(find.text('ARMS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ARM CONTROLS'), findsOneWidget);
    expect(find.text('FRONT ARMS'), findsOneWidget);
  });
}
