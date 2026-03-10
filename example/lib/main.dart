/// This example shows how to use dropdown_plus with a simple Cubit.
///
/// Run with: flutter run
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class User {
  const User({required this.id, required this.name, required this.role});
  final int id;
  final String name;
  final String role;
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  UsersLoaded(this.users);
  final List<User> users;
}

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(UsersInitial());

  static const _all = [
    User(id: 1, name: 'Alice Johnson', role: 'Engineer'),
    User(id: 2, name: 'Bob Smith', role: 'Designer'),
    User(id: 3, name: 'Carol White', role: 'Manager'),
    User(id: 4, name: 'David Brown', role: 'QA'),
    User(id: 5, name: 'Eve Davis', role: 'DevOps'),
  ];

  Future<void> search(String query) async {
    emit(UsersLoading());
    await Future.delayed(const Duration(milliseconds: 400)); // simulate API
    final results = query.isEmpty
        ? _all
        : _all
            .where(
              (u) =>
                  u.name.toLowerCase().contains(query.toLowerCase()) ||
                  u.role.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    emit(UsersLoaded(results));
  }
}

// ── App ───────────────────────────────────────────────────────────────────────

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dropdown_plus Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _singleCubit = UsersCubit();
  final _multiCubit = UsersCubit();

  DropdownItem<User>? _selected;
  List<DropdownItem<User>> _multiSelected = [];

  void Function(
    UsersState,
    void Function(List<DropdownItem<dynamic>>),
    void Function(bool),
  ) get _stateHandler => (state, updateList, updateLoading) {
        if (state is UsersLoaded) {
          updateList(
            state.users
                .map((u) =>
                    DropdownItem(value: u, label: '${u.name} · ${u.role}'))
                .toList(),
          );
          updateLoading(false);
        } else if (state is UsersLoading) {
          updateLoading(true);
        }
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dropdown_plus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Default theme ─────────────────────────────────────────────
            const Text('Single Select — Default Theme',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SearchableDropdownPlus<UsersCubit, UsersState>(
              cubit: _singleCubit,
              hintText: 'Search and select a user…',
              searchHint: 'Type a name or role…',
              noResultsText: 'No users found',
              loadingText: 'Loading…',
              onSearch: _singleCubit.search,
              onStateChange: _stateHandler,
              onSelectionChanged: (item) =>
                  setState(() => _selected = item as DropdownItem<User>),
            ),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Selected: ${_selected!.label}',
                    style: const TextStyle(color: Colors.green)),
              ),

            const SizedBox(height: 32),

            // ── Custom theme ──────────────────────────────────────────────
            const Text('Multi Select — Custom Theme',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            MultiSelectDropdownPlus<UsersCubit, UsersState>(
              cubit: _multiCubit,
              hintText: 'Select users…',
              noResultsText: 'No users found',
              maxDisplayChips: 3,
              onSearch: _multiCubit.search,
              onStateChange: _stateHandler,
              onSelectionChanged: (items) => setState(
                () => _multiSelected = items.cast<DropdownItem<User>>(),
              ),
              dropdownTheme: DropdownPlusTheme(
                activeBorderColor: Colors.teal,
                checkboxActiveColor: Colors.teal,
                chipBackgroundColor: Colors.teal.withOpacity(0.1),
                chipTextStyle: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.w600),
                chipBorderColor: Colors.teal.withOpacity(0.4),
                selectedItemTextStyle: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.bold),
                selectedItemBackgroundColor: Colors.teal.withOpacity(0.08),
                loadingIndicatorColor: Colors.teal,
                selectAllTextStyle: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.bold),
                selectedCountBackgroundColor: Colors.teal.withOpacity(0.15),
                selectedCountTextStyle: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.w600),
              ),
            ),
            if (_multiSelected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${_multiSelected.map((e) => e.label).join(', ')}',
                  style: const TextStyle(color: Colors.teal),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
