import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('enabled false prevents opening panel', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SearchableDropdown(
          hintText: 'Pick',
          items: [
            DropdownItem<String>(value: 'a', label: 'Alpha'),
          ],
          isLoading: false,
          enabled: false,
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('errorBuilder shows custom error UI', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SearchableDropdown(
          hintText: 'Pick',
          items: const [],
          isLoading: false,
          error: 'Network failed',
          errorBuilder: (context, error, retry) => Text('Custom: $error'),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    expect(find.text('Custom: Network failed'), findsOneWidget);
  });

  testWidgets('minSearchLength delays onSearch', (tester) async {
    final queries = <String>[];

    await tester.pumpWidget(
      _wrap(
        SearchableDropdown(
          hintText: 'Pick',
          items: const [],
          isLoading: false,
          minSearchLength: 3,
          onSearch: queries.add,
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    queries.clear();

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pumpAndSettle();
    expect(queries, isEmpty);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pumpAndSettle();
    expect(queries, contains('abc'));
  });
}
