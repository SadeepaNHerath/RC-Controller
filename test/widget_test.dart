import 'package:flutter_test/flutter_test.dart';
import 'package:rc_controller/app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const RCControllerApp());

    expect(find.text('RC Controller'), findsOneWidget);
  });
}
