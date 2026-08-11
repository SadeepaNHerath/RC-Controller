import 'package:flutter_test/flutter_test.dart';
import 'package:helmrc/app/app.dart';
import 'package:helmrc/app/app_info.dart';
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
}
