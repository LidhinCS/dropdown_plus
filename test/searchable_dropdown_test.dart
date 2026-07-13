import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('local list filters and selects item', (tester) async {
    final items = [
      const DropdownItem<String>(value: 'a', label: 'Alice'),
      const DropdownItem<String>(value: 'b', label: 'Bob'),
    ];
    DropdownItem<dynamic>? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableDropdown(
            hintText: 'Pick',
            items: items,
            isLoading: false,
            onSelectionChanged: (item) => selected = item,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(selected?.label, 'Bob');
  });

  testWidgets('debounce delays onSearch', (tester) async {
    final items = <DropdownItem<dynamic>>[];
    var searchCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableDropdown(
            hintText: 'Search',
            items: items,
            isLoading: false,
            debounceDuration: const Duration(milliseconds: 100),
            onSearch: (_) => searchCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    final callsAfterOpen = searchCalls;

    await tester.enterText(find.byType(TextField), 'a');
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.enterText(find.byType(TextField), 'abc');
    expect(searchCalls, callsAfterOpen);

    await tester.pump(const Duration(milliseconds: 120));
    expect(searchCalls, callsAfterOpen + 1);
  });
}
