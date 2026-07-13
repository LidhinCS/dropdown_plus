import 'package:dropdown_plus_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('dropdown_plus'), findsOneWidget);
    expect(find.text('BLoC — single select'), findsOneWidget);
  });
}
