import 'package:dropdown_plus_bloc/typed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUser {
  const TestUser({required this.id, required this.name});
  final int id;
  final String name;
}

sealed class TypedUsersState {}

final class TypedUsersLoaded extends TypedUsersState {
  TypedUsersLoaded(this.users);
  final List<TestUser> users;
}

class TypedUsersCubit extends Cubit<TypedUsersState> {
  TypedUsersCubit(List<TestUser> users) : super(TypedUsersLoaded(users));

  void search(String query) {
    final state = this.state;
    if (state is TypedUsersLoaded) emit(TypedUsersLoaded(state.users));
  }
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  const users = [
    TestUser(id: 1, name: 'Alice'),
    TestUser(id: 2, name: 'Bob'),
  ];

  testWidgets('controller select and clear fire onChanged', (tester) async {
    final controller = DropdownPlusController<TestUser>();
    TestUser? selected = users.first;

    await tester.pumpWidget(
      _wrap(
        TypedSearchableDropdown<TestUser>(
          hintText: 'Pick user',
          items: users,
          isLoading: false,
          itemLabel: (u) => u.name,
          controller: controller,
          value: users.first,
          onChanged: (user) => selected = user,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsWidgets);

    controller.select(users[1]);
    await tester.pumpAndSettle();
    expect(selected?.name, 'Bob');
    expect(controller.value?.name, 'Bob');
    expect(find.text('Bob'), findsWidgets);

    controller.clear();
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(controller.value, isNull);
    expect(find.text('Pick user'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('controller open and close toggle the panel', (tester) async {
    final controller = DropdownPlusController<TestUser>();

    await tester.pumpWidget(
      _wrap(
        TypedSearchableDropdown<TestUser>(
          hintText: 'Pick user',
          items: users,
          isLoading: false,
          itemLabel: (u) => u.name,
          controller: controller,
          searchHint: 'Search users…',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.isOpen, isFalse);
    expect(find.text('Alice'), findsNothing);

    await controller.open();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Search users…'), findsOneWidget);

    controller.close();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('Alice'), findsNothing);

    controller.dispose();
  });

  testWidgets('user tap updates controller value', (tester) async {
    final controller = DropdownPlusController<TestUser>();
    TestUser? selected;

    await tester.pumpWidget(
      _wrap(
        TypedSearchableDropdown<TestUser>(
          hintText: 'Pick user',
          items: users,
          isLoading: false,
          itemLabel: (u) => u.name,
          controller: controller,
          onChanged: (user) => selected = user,
        ),
      ),
    );

    await tester.tap(find.text('Pick user'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    expect(selected?.name, 'Alice');
    expect(controller.value?.name, 'Alice');
    expect(controller.isOpen, isFalse);

    controller.dispose();
  });

  testWidgets('multi controller select deselect clear setValues', (tester) async {
    final controller = DropdownPlusMultiController<TestUser>();
    List<TestUser> selected = [];

    await tester.pumpWidget(
      _wrap(
        TypedMultiSelectDropdown<TestUser>(
          hintText: 'Pick users',
          items: users,
          isLoading: false,
          itemLabel: (u) => u.name,
          itemEquals: (a, b) => a.id == b.id,
          controller: controller,
          onChanged: (values) => selected = values,
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.select(users[0]);
    await tester.pumpAndSettle();
    expect(selected.map((u) => u.name), ['Alice']);
    expect(controller.values.map((u) => u.name), ['Alice']);

    controller.select(users[1]);
    await tester.pumpAndSettle();
    expect(selected.map((u) => u.name), ['Alice', 'Bob']);

    controller.deselect(users[0]);
    await tester.pumpAndSettle();
    expect(selected.map((u) => u.name), ['Bob']);

    controller.setValues([users[0]]);
    await tester.pumpAndSettle();
    expect(selected.map((u) => u.name), ['Alice']);

    controller.clear();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(find.text('Pick users'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('Plus controller does not close parent cubit', (tester) async {
    final cubit = TypedUsersCubit(users);
    final controller = DropdownPlusController<TestUser>();

    await tester.pumpWidget(
      _wrap(
        TypedSearchableDropdownPlus<TestUser, TypedUsersCubit, TypedUsersState>(
          cubit: cubit,
          hintText: 'Pick user',
          itemLabel: (u) => u.name,
          controller: controller,
          onSearch: cubit.search,
          onStateChange: (state, updateItems, updateLoading) {
            if (state is TypedUsersLoaded) {
              updateItems(state.users);
              updateLoading(false);
            }
          },
        ),
      ),
    );

    cubit.search('');
    await tester.pumpAndSettle();
    await controller.open();
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);

    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pumpAndSettle();

    expect(cubit.isClosed, isFalse);
    await cubit.close();
    controller.dispose();
  });

  test('dispose detaches cleanly', () {
    final controller = DropdownPlusController<TestUser>();
    controller.select(users.first);
    expect(controller.value?.name, 'Alice');
    controller.dispose();
    expect(controller.isAttached, isFalse);
  });
}
