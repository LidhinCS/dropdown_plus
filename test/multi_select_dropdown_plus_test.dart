import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class TestState {}

final class TestLoaded extends TestState {
  TestLoaded(this.labels);
  final List<String> labels;
}

class TestCubit extends Cubit<TestState> {
  TestCubit() : super(TestLoaded(['One', 'Two']));

  void search(String query) => emit(TestLoaded(['One', 'Two']));
}

void main() {
  testWidgets('multi BLoC dropdown does not close cubit on dispose',
      (tester) async {
    final cubit = TestCubit();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiSelectDropdownPlus<TestCubit, TestState>(
            cubit: cubit,
            hintText: 'Multi',
            onSearch: cubit.search,
            onStateChange: (state, updateList, updateLoading) {
              if (state is TestLoaded) {
                updateList(
                  state.labels
                      .map((l) => DropdownItem<String>(value: l, label: l))
                      .toList(),
                );
                updateLoading(false);
              }
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(cubit.isClosed, isFalse);
    await cubit.close();
  });
}
