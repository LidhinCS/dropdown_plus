import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class FormUsersState {}

final class FormUsersLoaded extends FormUsersState {
  FormUsersLoaded(this.labels);
  final List<String> labels;
}

class FormUsersCubit extends Cubit<FormUsersState> {
  FormUsersCubit() : super(FormUsersLoaded(['Alice', 'Bob']));

  void search(String query) {
    emit(FormUsersLoaded(['Alice', 'Bob']));
  }
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SearchableDropdownFormField', () {
    testWidgets('validator shows error when empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Form(
            child: SearchableDropdownFormField(
              hintText: 'Pick user',
              items: const [
                DropdownItem<String>(value: 'a', label: 'Alpha'),
              ],
              isLoading: false,
              autovalidateMode: AutovalidateMode.always,
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('onSaved receives selected item', (tester) async {
      DropdownItem<dynamic>? saved;
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        _wrap(
          Form(
            key: formKey,
            child: SearchableDropdownFormField(
              hintText: 'Pick user',
              items: const [
                DropdownItem<String>(value: 'a', label: 'Alpha'),
                DropdownItem<String>(value: 'b', label: 'Beta'),
              ],
              isLoading: false,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick user'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      formKey.currentState!.save();
      expect(saved?.label, 'Alpha');
    });
  });

  group('MultiSelectDropdownFormField', () {
    testWidgets('validator requires at least one selection', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Form(
            child: MultiSelectDropdownFormField(
              hintText: 'Pick users',
              items: const [
                DropdownItem<String>(value: 'a', label: 'Alpha'),
              ],
              isLoading: false,
              autovalidateMode: AutovalidateMode.always,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Pick at least one' : null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pick at least one'), findsOneWidget);
    });
  });

  group('SearchableDropdownPlusFormField', () {
    testWidgets('selects item and clears validation error', (tester) async {
      final cubit = FormUsersCubit();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        _wrap(
          Form(
            key: formKey,
            child: SearchableDropdownPlusFormField<FormUsersCubit, FormUsersState>(
              cubit: cubit,
              hintText: 'Pick user',
              onSearch: cubit.search,
              onStateChange: (state, updateList, updateLoading) {
                if (state is FormUsersLoaded) {
                  updateList(
                    state.labels
                        .map((l) => DropdownItem<String>(value: l, label: l))
                        .toList(),
                  );
                  updateLoading(false);
                }
              },
              autovalidateMode: AutovalidateMode.always,
              validator: (value) => value == null ? 'Required' : null,
            ),
          ),
        ),
      );

      cubit.search('');
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);

      await tester.tap(find.text('Pick user'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNothing);
      await cubit.close();
    });
  });
}
