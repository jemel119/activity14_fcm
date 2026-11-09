import 'package:activity14_fcm/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows the Activity 14 startup screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Activity 14 FCM'), findsOneWidget);
    expect(find.text('Firebase initialized.'), findsOneWidget);
  });
}
