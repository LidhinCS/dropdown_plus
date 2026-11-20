import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = [
    CascadeMenuItem<String>(
      label: 'Europe',
      leading: Icon(Icons.public),
      children: [
        CascadeMenuItem(label: 'France', value: 'fr'),
        CascadeMenuItem(label: 'Germany', value: 'de'),
      ],
    ),
    CascadeMenuItem<String>(
      label: 'Asia',
      children: [
        CascadeMenuItem(label: 'Japan', value: 'jp'),
        CascadeMenuItem(label: 'India', value: 'in'),
      ],
    ),
  ];

  test('findByValue and path helpers walk the tree', () {
    expect(CascadeMenuItem.findByValue(items, 'de')?.label, 'Germany');
    expect(
      CascadeMenuItem.pathLabelsForValue(items, 'jp'),
      ['Asia', 'Japan'],
    );
    expect(CascadeMenuItem.pathIndicesForValue(items, 'jp'), [1, 0]);
  });

  testWidgets('flyout opens cascade and selects a leaf', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 280,
              child: CascadeDropdown<String>(
                hintText: 'Pick country',
                items: items,
                view: CascadeView.web,
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick country'));
    await tester.pumpAndSettle();

    expect(find.text('Europe'), findsOneWidget);
    expect(find.text('France'), findsNothing);

    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();
    expect(find.text('France'), findsOneWidget);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    expect(selected, 'fr');
    expect(find.text('France'), findsOneWidget);
    expect(find.text('Europe'), findsNothing);
  });

  testWidgets('drill-down replaces panel and supports back', (tester) async {
    String? selected;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CascadeDropdown<String>(
            hintText: 'Pick country',
            items: items,
            view: CascadeView.mobile,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick country'));
    await tester.pumpAndSettle();

    expect(find.text('Europe'), findsOneWidget);
    expect(find.text('France'), findsNothing);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();

    expect(find.text('France'), findsOneWidget);
    expect(find.text('Asia'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('Europe'), findsWidgets);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Asia'), findsOneWidget);
    expect(find.text('France'), findsNothing);

    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    expect(selected, 'fr');
  });

  testWidgets('auto uses drill-down under flyoutBreakpoint', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CascadeDropdown<String>(
            hintText: 'Pick country',
            items: items,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick country'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('France'), findsOneWidget);
  });

  testWidgets('showPathInTrigger displays ancestors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CascadeDropdown<String>(
            hintText: 'Pick country',
            items: items,
            value: 'de',
            showPathInTrigger: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Europe › Germany'), findsOneWidget);
  });

  testWidgets('drill-down nested panel fits near the bottom', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CascadeDropdown<String>(
                hintText: 'Pick country',
                items: items,
                view: CascadeView.mobile,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick country'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();

    expect(find.text('France'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    final triggerTop = tester.getTopLeft(find.text('Pick country')).dy;
    final childTop = tester.getTopLeft(find.text('France')).dy;
    // Children that won't fit below flip the panel above the trigger.
    expect(childTop, lessThan(triggerTop));
    expect(
      tester.takeException(),
      isNull,
      reason: 'drill-down header + list must not bottom-overflow',
    );
  });

  testWidgets('tall flyout submenu flips up near the bottom', (tester) async {
    tester.view.physicalSize = const Size(800, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final manyChildren = List<CascadeMenuItem<String>>.generate(
      20,
      (i) => CascadeMenuItem(label: 'City $i', value: 'c$i'),
    );
    final tree = [
      CascadeMenuItem<String>(
        label: 'Region',
        children: manyChildren,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: SizedBox(
                width: 240,
                child: CascadeDropdown<String>(
                  hintText: 'Pick city',
                  items: tree,
                  view: CascadeView.web,
                  submenuWidth: 200,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick city'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Region'));
    await tester.pumpAndSettle();

    expect(find.text('City 0'), findsOneWidget);

    final regionTop = tester.getTopLeft(find.text('Region')).dy;
    final city0Top = tester.getTopLeft(find.text('City 0')).dy;
    // Bottom-aligned flyout: first child row sits above the parent row.
    expect(city0Top, lessThan(regionTop));

    final screenBottom = tester.view.physicalSize.height;
    final city0Bottom = tester.getBottomLeft(find.text('City 0')).dy;
    expect(city0Bottom, lessThan(screenBottom));
    expect(city0Top, greaterThanOrEqualTo(0));
    expect(
      tester.takeException(),
      isNull,
      reason: 'tall submenu must not overflow the viewport',
    );
  });

  testWidgets('onLoadChildren fills a lazy branch', (tester) async {
    String? selected;
    var loadCalls = 0;

    const lazyRoot = [
      CascadeMenuItem<String>(
        label: 'Europe',
        value: 'eu',
        hasChildren: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 280,
              child: CascadeDropdown<String>(
                hintText: 'Pick country',
                items: lazyRoot,
                view: CascadeView.web,
                onLoadChildren: (parent) async {
                  loadCalls++;
                  expect(parent.value, 'eu');
                  await Future<void>.delayed(const Duration(milliseconds: 20));
                  return const [
                    CascadeMenuItem(label: 'France', value: 'fr'),
                    CascadeMenuItem(label: 'Germany', value: 'de'),
                  ];
                },
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick country'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Europe'));
    await tester.pump();
    expect(find.text('Loading…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpAndSettle();

    expect(loadCalls, 1);
    expect(find.text('France'), findsOneWidget);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();
    expect(selected, 'fr');
  });

  test('hasChildren marks empty nodes as branches', () {
    const item = CascadeMenuItem<String>(
      label: 'Lazy',
      value: 'x',
      hasChildren: true,
    );
    expect(item.isBranch, isTrue);
    expect(item.isLeaf, isFalse);
  });
}
