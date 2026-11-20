import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:dropdown_plus_bloc/src/internal/dropdown_item_button.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('menu opens upward when trigger is near the bottom',
      (tester) async {
    final items = List<DropdownItem<int>>.generate(
      12,
      (i) => DropdownItem<int>(value: i, label: 'Item $i'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SearchableDropdown(
                hintText: 'Pick',
                items: items,
                isLoading: false,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    final triggerBottom = tester.getBottomLeft(find.text('Pick')).dy;
    final firstItemTop = tester.getTopLeft(find.text('Item 0')).dy;
    expect(firstItemTop, lessThan(triggerBottom));
  });

  testWidgets('menu overlays content instead of pushing it down',
      (tester) async {
    final belowKey = GlobalKey();
    final items = [
      const DropdownItem<String>(value: 'a', label: 'Alice'),
      const DropdownItem<String>(value: 'b', label: 'Bob'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SearchableDropdown(
                hintText: 'Pick',
                items: items,
                isLoading: false,
              ),
              Container(
                  key: belowKey, height: 24, color: const Color(0xFFE53935)),
            ],
          ),
        ),
      ),
    );

    final before = tester.getTopLeft(find.byKey(belowKey));

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    // The open trigger border is slightly thicker. The menu itself must not
    // add its height to the layout below.
    expect(
      (tester.getTopLeft(find.byKey(belowKey)).dy - before.dy).abs(),
      lessThan(8),
    );

    await tester.tapAt(const Offset(12, 560));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('mouse scroll clears the row hover highlight', (tester) async {
    final items = List<DropdownItem<int>>.generate(
      30,
      (i) => DropdownItem<int>(value: i, label: 'Item $i'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableDropdown(
            hintText: 'Pick',
            items: items,
            isLoading: false,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    final hover = dropdownItemHoverColor(
      Theme.of(tester.element(find.text('Item 1'))).colorScheme,
    );

    bool rowHasHover() {
      return tester
          .widgetList<Container>(find.byType(Container))
          .any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == hover;
      });
    }

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Item 1')));
    await tester.pump();

    expect(rowHasHover(), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pump();

    expect(rowHasHover(), isFalse);
  });
}
