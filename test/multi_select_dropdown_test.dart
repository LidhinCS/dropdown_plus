import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toggles multi selection', (tester) async {
    final items = [
      const DropdownItem<String>(value: 'a', label: 'Alice'),
      const DropdownItem<String>(value: 'b', label: 'Bob'),
    ];
    List<DropdownItem<dynamic>> selected = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiSelectDropdown(
            hintText: 'Select',
            items: items,
            isLoading: false,
            onSelectionChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(selected.map((e) => e.label).toList(), ['Alice', 'Bob']);
  });
}
