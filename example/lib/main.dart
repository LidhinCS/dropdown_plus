/// This example shows dropdown_plus with BLoC (`*Plus` widgets) and without
/// (`SearchableDropdown` / `MultiSelectDropdown`).
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

const List<User> kDemoUsers = [
  User(id: 1, name: 'Alice Johnson', role: 'Engineer'),
  User(id: 2, name: 'Bob Smith', role: 'Designer'),
  User(id: 3, name: 'Carol White', role: 'Manager'),
  User(id: 4, name: 'David Brown', role: 'QA'),
  User(id: 5, name: 'Eve Davis', role: 'DevOps'),
];

List<DropdownItem<dynamic>> _usersToItems(List<User> users) => users
    .map(
      (u) => DropdownItem<User>(
        value: u,
        label: '${u.name} · ${u.role}',
      ),
    )
    .toList();

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

  Future<void> search(String query) async {
    emit(UsersLoading());
    await Future.delayed(const Duration(milliseconds: 400)); // simulate API
    final results = query.isEmpty
        ? kDemoUsers
        : kDemoUsers
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

  // Plain (no BLoC) — local list for single-select demo
  late List<DropdownItem<dynamic>> _plainLocalItems;
  DropdownItem<dynamic>? _plainLocalSelected;

  // Plain — remote-style search for multi-select demo
  List<DropdownItem<dynamic>> _plainRemoteItems = _usersToItems(kDemoUsers);
  bool _plainRemoteLoading = false;
  List<DropdownItem<dynamic>> _plainRemoteSelected = [];

  void Function(
    UsersState,
    void Function(List<DropdownItem<dynamic>>),
    void Function(bool),
  ) get _stateHandler => (state, updateList, updateLoading) {
        if (state is UsersLoaded) {
          updateList(_usersToItems(state.users));
          updateLoading(false);
        } else if (state is UsersLoading) {
          updateLoading(true);
        }
      };

  @override
  void initState() {
    super.initState();
    _plainLocalItems = _usersToItems(kDemoUsers);
    _singleCubit.search('');
    _multiCubit.search('');
  }

  Future<void> _plainRemoteSearch(String query) async {
    setState(() => _plainRemoteLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      final users = query.isEmpty
          ? kDemoUsers
          : kDemoUsers
              .where(
                (u) =>
                    u.name.toLowerCase().contains(query.toLowerCase()) ||
                    u.role.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
      setState(() => _plainRemoteItems = _usersToItems(users));
    } finally {
      if (mounted) setState(() => _plainRemoteLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dropdown_plus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BLoC — single select',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SearchableDropdownPlus<UsersCubit, UsersState>(
              cubit: _singleCubit,
              hintText: 'Search and select a user…',
              searchHint: 'Type a name or role…',
              noResultsText: 'No users found',
              loadingText: 'Loading…',
              onSearch: _singleCubit.search,
              themeStyle: DropdownPlusThemeStyle.dark,
              onStateChange: _stateHandler,
              onSelectionChanged: (item) =>
                  setState(() => _selected = item as DropdownItem<User>),
            ),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${_selected!.label}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),

            const SizedBox(height: 32),

            const Text(
              'BLoC — multi select',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            MultiSelectDropdownPlus<UsersCubit, UsersState>(
              cubit: _multiCubit,
              hintText: 'Select users…',
              noResultsText: 'No users found',
              loadingText: 'Loading…',
              maxDisplayChips: 3,
              selectedItems: _multiSelected,
              onSearch: _multiCubit.search,
              onStateChange: _stateHandler,
              onSelectionChanged: (items) => setState(
                () => _multiSelected = items.cast<DropdownItem<User>>(),
              ),
              dropdownTheme: DropdownPlusTheme(
                activeBorderColor: Colors.teal,
                checkboxActiveColor: Colors.teal,
                chipBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                chipTextStyle: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.w600),
                chipBorderColor: Colors.teal.withValues(alpha: 0.4),
                selectedItemTextStyle: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.bold),
                selectedItemBackgroundColor:
                    Colors.teal.withValues(alpha: 0.08),
                loadingIndicatorColor: Colors.teal,
                selectAllTextStyle: const TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.bold),
                selectedCountBackgroundColor:
                    Colors.teal.withValues(alpha: 0.15),
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

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Without BLoC — single select (local search only)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SearchableDropdown(
              hintText: 'Pick a user (filters this list locally)…',
              items: _plainLocalItems,
              isLoading: false,
              selectedValue: _plainLocalSelected,
              themeStyle: DropdownPlusThemeStyle.minimal,
              onSelectionChanged: (item) =>
                  setState(() => _plainLocalSelected = item),
            ),
            if (_plainLocalSelected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Plain selected: ${_plainLocalSelected!.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            const SizedBox(height: 32),

            const Text(
              'Without BLoC — multi select (simulated remote search)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            MultiSelectDropdown(
              hintText: 'Select users…',
              items: _plainRemoteItems,
              isLoading: _plainRemoteLoading,
              selectedItems: _plainRemoteSelected,
              onSearch: _plainRemoteSearch,
              searchHint: 'Type a name or role…',
              noResultsText: 'No users found',
              loadingText: 'Loading…',
              maxDisplayChips: 2,
              themeStyle: DropdownPlusThemeStyle.rounded,
              onSelectionChanged: (items) =>
                  setState(() => _plainRemoteSelected = items),
            ),
            if (_plainRemoteSelected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Plain multi: ${_plainRemoteSelected.map((e) => e.label).join(', ')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
