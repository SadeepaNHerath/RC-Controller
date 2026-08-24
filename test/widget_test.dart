import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/app/app.dart';
import 'package:helmrc/app/app_info.dart';
import 'package:helmrc/profiles/builtin_profiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen shows HelmRC branding', (tester) async {
    await tester.pumpWidget(const HelmRcApp());
    await tester.pump();

    expect(find.text(AppInfo.name), findsWidgets);
    expect(find.text(AppInfo.developer), findsOneWidget);
  });

  testWidgets('home shows BLE and Classic radio segments', (tester) async {
    await tester.pumpWidget(const HelmRcApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('BLE'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Car profile'), findsOneWidget);
  });

  testWidgets('Classic stays BLE-only off Android', (tester) async {
    await tester.pumpWidget(const HelmRcApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Classic'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Classic serial is Android-only. iOS stays BLE.'),
        findsOneWidget);
  });

  testWidgets('profile dropdown lists builtin cars', (tester) async {
    await tester.pumpWidget(const HelmRcApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('HelmRC').evaluate().length, greaterThanOrEqualTo(1));
    expect(find.text('Arduino UART'), findsWidgets);
    expect(find.text('Numeric'), findsWidgets);
    expect(find.text('Custom'), findsWidgets);
  });

  testWidgets('edit icon appears only for Custom profile', (tester) async {
    await tester.pumpWidget(const HelmRcApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byTooltip('Edit custom commands'), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Custom').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byTooltip('Edit custom commands'), findsOneWidget);
    expect(
      tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>)).value,
      BuiltinProfiles.customId,
    );
  });
}
