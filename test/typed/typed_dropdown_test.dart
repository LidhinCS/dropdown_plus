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
  test('toDropdownItems maps typed list to DropdownItem', () {
    const users = [
      TestUser(id: 1, name: 'Alice'),
      TestUser(id: 2, name: 'Bob'),
    ];

    final items = users.toDropdownItems((u) => u.name);
    expect(items, hasLength(2));
    expect(items.first.label, 'Alice');
    expect(items.first.typedValue.name, 'Alice');
  });

  testWidgets('TypedSearchableDropdown onChanged receives T', (tester) async {
    const users = [
      TestUser(id: 1, name: 'Alice'),
      TestUser(id: 2, name: 'Bob'),
    ];
    TestUser? selected;

    await tester.pumpWidget(
      _wrap(
        TypedSearchableDropdown<TestUser>(
          hintText: 'Pick user',
          items: users,
          isLoading: false,
          itemLabel: (u) => u.name,
          onChanged: (user) => selected = user,
        ),
      ),
    );

    await tester.tap(find.text('Pick user'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    expect(selected?.name, 'Alice');
  });

  testWidgets('TypedSearchableDropdownPlus updateItems uses List<T>',
      (tester) async {
    const users = [
      TestUser(id: 1, name: 'Alice'),
      TestUser(id: 2, name: 'Bob'),
    ];
    final cubit = TypedUsersCubit(users);
    List<TestUser>? receivedItems;
    TestUser? selected;

    await tester.pumpWidget(
      _wrap(
        TypedSearchableDropdownPlus<TestUser, TypedUsersCubit, TypedUsersState>(
          cubit: cubit,
          hintText: 'Pick user',
          itemLabel: (u) => u.name,
          onSearch: cubit.search,
          onStateChange: (state, updateItems, updateLoading) {
            if (state is TypedUsersLoaded) {
              receivedItems = state.users;
              updateItems(state.users);
              updateLoading(false);
            }
          },
          onChanged: (user) => selected = user,
        ),
      ),
    );

    cubit.search('');
    await tester.pumpAndSettle();

    expect(receivedItems, users);
    await tester.tap(find.text('Pick user'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(selected?.name, 'Bob');
    await cubit.close();
  });

  testWidgets('TypedMultiSelectDropdown toggles typed values', (tester) async {
    const users = [
      TestUser(id: 1, name: 'Alice'),
      TestUser(id: 2, name: 'Bob'),
    ];
    List<TestUser>? selected;

    await tester.pumpWidget(
      _wrap(
        TypedMultiSelectDropdown<TestUser>(
          hintText: 'Pick users',
          items: users,
          isLoading: false,
          itemLabel: (u) => u.name,
          onChanged: (values) => selected = values,
        ),
      ),
    );

    await tester.tap(find.text('Pick users'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    expect(selected?.length, 1);
    expect(selected?.first.name, 'Alice');
  });
}
