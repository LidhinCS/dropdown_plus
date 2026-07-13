/// Example for dropdown_plus_bloc: legacy [DropdownItem] API, typed API, and forms.
///
/// Run with: flutter run
library;

import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
import 'package:dropdown_plus_bloc/typed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class User {
  const User({required this.id, required this.name, required this.role});
  final int id;
  final String name;
  final String role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && id == other.id && name == other.name && role == other.role;

  @override
  int get hashCode => Object.hash(id, name, role);
}

const List<User> kDemoUsers = [
  User(id: 1, name: 'Alice Johnson', role: 'Engineer'),
  User(id: 2, name: 'Bob Smith', role: 'Designer'),
  User(id: 3, name: 'Carol White', role: 'Manager'),
  User(id: 4, name: 'David Brown', role: 'QA'),
  User(id: 5, name: 'Eve Davis', role: 'DevOps'),
];

String _userLabel(User u) => '${u.name} · ${u.role}';

List<DropdownItem<dynamic>> _usersToItems(List<User> users) =>
    users.map((u) => DropdownItem<User>(value: u, label: _userLabel(u))).toList();

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
    await Future.delayed(const Duration(milliseconds: 400));
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

void _legacyStateHandler(
  UsersState state,
  void Function(List<DropdownItem<dynamic>>) updateList,
  void Function(bool) updateLoading,
) {
  if (state is UsersLoaded) {
    updateList(_usersToItems(state.users));
    updateLoading(false);
  } else if (state is UsersLoading) {
    updateLoading(true);
  }
}

void _typedStateHandler(
  UsersState state,
  void Function(List<User>) updateItems,
  void Function(bool) updateLoading,
) {
  if (state is UsersLoaded) {
    updateItems(state.users);
    updateLoading(false);
  } else if (state is UsersLoading) {
    updateLoading(true);
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
  final _typedCubit = UsersCubit();
  final _formKey = GlobalKey<FormState>();

  DropdownItem<User>? _selected;
  List<DropdownItem<User>> _multiSelected = [];
  User? _typedSelected;
  User? _formSavedUser;

  late List<DropdownItem<dynamic>> _plainLocalItems;
  DropdownItem<dynamic>? _plainLocalSelected;
  User? _typedPlainSelected;

  List<DropdownItem<dynamic>> _plainRemoteItems = _usersToItems(kDemoUsers);
  bool _plainRemoteLoading = false;
  List<DropdownItem<dynamic>> _plainRemoteSelected = [];

  @override
  void initState() {
    super.initState();
    _plainLocalItems = _usersToItems(kDemoUsers);
    _singleCubit.search('');
    _multiCubit.search('');
    _typedCubit.search('');
  }

  @override
  void dispose() {
    _singleCubit.close();
    _multiCubit.close();
    _typedCubit.close();
    super.dispose();
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

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${_formSavedUser?.name ?? 'none'}')),
      );
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
            _sectionTitle('BLoC — single select (legacy)'),
            SearchableDropdownPlus<UsersCubit, UsersState>(
              cubit: _singleCubit,
              hintText: 'Search and select a user…',
              searchHint: 'Type a name or role…',
              noResultsText: 'No users found',
              loadingText: 'Loading…',
              onSearch: _singleCubit.search,
              debounceDuration: const Duration(milliseconds: 400),
              themeStyle: DropdownPlusThemeStyle.dark,
              onStateChange: _legacyStateHandler,
              onSelectionChanged: (item) =>
                  setState(() => _selected = item as DropdownItem<User>),
            ),
            if (_selected != null)
              _selectionNote('Selected: ${_selected!.label}', Colors.green),
            const SizedBox(height: 32),
            _sectionTitle('Typed API — BLoC single select'),
            const Text(
              'import package:dropdown_plus_bloc/typed.dart',
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            TypedSearchableDropdownPlus<User, UsersCubit, UsersState>(
              cubit: _typedCubit,
              hintText: 'Select a user (typed)…',
              itemLabel: _userLabel,
              itemEquals: (a, b) => a.id == b.id,
              value: _typedSelected,
              onChanged: (user) => setState(() => _typedSelected = user),
              onSearch: _typedCubit.search,
              debounceDuration: const Duration(milliseconds: 400),
              themeStyle: DropdownPlusThemeStyle.dark,
              onStateChange: _typedStateHandler,
            ),
            if (_typedSelected != null)
              _selectionNote(
                'Typed selected: ${_userLabel(_typedSelected!)}',
                Colors.deepPurple,
              ),
            const SizedBox(height: 32),
            _sectionTitle('Form — SearchableDropdownFormField'),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchableDropdownFormField(
                    hintText: 'Required: pick a user…',
                    items: _usersToItems(kDemoUsers),
                    isLoading: false,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        value == null ? 'Please select a user' : null,
                    onSaved: (value) =>
                        _formSavedUser = value?.value as User?,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _submitForm,
                    child: const Text('Save form'),
                  ),
                ],
              ),
            ),
            if (_formSavedUser != null)
              _selectionNote('Last saved: ${_userLabel(_formSavedUser!)}', null),
            const SizedBox(height: 32),
            _sectionTitle('BLoC — multi select (legacy)'),
            MultiSelectDropdownPlus<UsersCubit, UsersState>(
              cubit: _multiCubit,
              hintText: 'Select users…',
              noResultsText: 'No users found',
              loadingText: 'Loading…',
              maxDisplayChips: 3,
              selectedItems: _multiSelected,
              onSearch: _multiCubit.search,
              onStateChange: _legacyStateHandler,
              onSelectionChanged: (items) => setState(
                () => _multiSelected = items.cast<DropdownItem<User>>(),
              ),
              dropdownTheme: DropdownPlusTheme(
                activeBorderColor: Colors.teal,
                checkboxActiveColor: Colors.teal,
                chipBackgroundColor: Colors.teal.withValues(alpha: 0.1),
                chipTextStyle: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                ),
                chipBorderColor: Colors.teal.withValues(alpha: 0.4),
                selectedItemTextStyle: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
                selectedItemBackgroundColor:
                    Colors.teal.withValues(alpha: 0.08),
                loadingIndicatorColor: Colors.teal,
                selectAllTextStyle: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
                selectedCountBackgroundColor:
                    Colors.teal.withValues(alpha: 0.15),
                selectedCountTextStyle: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_multiSelected.isNotEmpty)
              _selectionNote(
                'Selected: ${_multiSelected.map((e) => e.label).join(', ')}',
                Colors.teal,
              ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            _sectionTitle('Without BLoC — single select (legacy)'),
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
              _selectionNote(
                'Plain selected: ${_plainLocalSelected!.label}',
                null,
              ),
            const SizedBox(height: 32),
            _sectionTitle('Typed API — without BLoC'),
            TypedSearchableDropdown<User>(
              hintText: 'Pick a user (typed, local list)…',
              items: kDemoUsers,
              isLoading: false,
              itemLabel: _userLabel,
              value: _typedPlainSelected,
              onChanged: (user) => setState(() => _typedPlainSelected = user),
              themeStyle: DropdownPlusThemeStyle.minimal,
            ),
            if (_typedPlainSelected != null)
              _selectionNote(
                'Typed plain: ${_userLabel(_typedPlainSelected!)}',
                null,
              ),
            const SizedBox(height: 32),
            _sectionTitle('Without BLoC — multi select (remote search)'),
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
              _selectionNote(
                'Plain multi: ${_plainRemoteSelected.map((e) => e.label).join(', ')}',
                null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );

  Widget _selectionNote(String text, Color? color) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: TextStyle(color: color),
        ),
      );
}
