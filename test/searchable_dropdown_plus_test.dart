import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class TestUsersState {}

final class TestUsersLoading extends TestUsersState {}

final class TestUsersLoaded extends TestUsersState {
  TestUsersLoaded(this.labels);
  final List<String> labels;
}

class TestUsersCubit extends Cubit<TestUsersState> {
  TestUsersCubit() : super(TestUsersLoading());

  int searchCalls = 0;

  void search(String query) {
    searchCalls++;
    emit(TestUsersLoaded(['Alice', 'Bob']));
  }
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('does not close parent cubit on dispose', (tester) async {
    final cubit = TestUsersCubit();

    await tester.pumpWidget(
      _wrap(
        SearchableDropdownPlus<TestUsersCubit, TestUsersState>(
          cubit: cubit,
          hintText: 'Pick user',
          onSearch: cubit.search,
          onStateChange: (state, updateList, updateLoading) {
            if (state is TestUsersLoaded) {
              updateList(
                state.labels
                    .map((l) => DropdownItem<String>(value: l, label: l))
                    .toList(),
              );
              updateLoading(false);
            } else if (state is TestUsersLoading) {
              updateLoading(true);
            }
          },
        ),
      ),
    );

    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pump();

    expect(cubit.isClosed, isFalse);
    await cubit.close();
  });

  testWidgets('opens panel and selects an item', (tester) async {
    final cubit = TestUsersCubit();
    DropdownItem<dynamic>? selected;

    await tester.pumpWidget(
      _wrap(
        SearchableDropdownPlus<TestUsersCubit, TestUsersState>(
          cubit: cubit,
          hintText: 'Pick user',
          onSearch: cubit.search,
          onStateChange: (state, updateList, updateLoading) {
            if (state is TestUsersLoaded) {
              updateList(
                state.labels
                    .map((l) => DropdownItem<String>(value: l, label: l))
                    .toList(),
              );
              updateLoading(false);
            } else if (state is TestUsersLoading) {
              updateLoading(true);
            }
          },
          onSelectionChanged: (item) => selected = item,
        ),
      ),
    );

    cubit.search('');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pick user'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    expect(selected?.label, 'Alice');
    await cubit.close();
  });
}
