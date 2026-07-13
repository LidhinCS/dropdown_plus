import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dropdown_plus_bloc/src/internal/dropdown_pagination.dart';

void main() {
  testWidgets('pagination scroll controller fires near max extent',
      (tester) async {
    var calls = 0;
    final controller = DropdownPaginationScrollController(
      onLoadMore: () => calls++,
      hasMore: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 200,
          width: 300,
          child: ListView.builder(
            controller: controller,
            itemCount: 30,
            itemBuilder: (_, i) => SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Row $i'),
              ),
            ),
          ),
        ),
      ),
    );

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    expect(calls, 1);
    controller.dispose();
  });
}
