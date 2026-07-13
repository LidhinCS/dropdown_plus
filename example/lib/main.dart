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
      other is User &&
          id == other.id &&
          name == other.name &&
          role == other.role;

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

List<DropdownItem<dynamic>> _usersToItems(List<User> users) => users
    .map((u) => DropdownItem<User>(value: u, label: _userLabel(u)))
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

// ── Adaptive dropdown theme ─────────────────────────────────────────────────────

const _tealAccentTheme = DropdownPlusTheme(
  activeBorderColor: Color(0xFF00897B),
  checkboxActiveColor: Color(0xFF00897B),
  chipBackgroundColor: Color(0x1A00897B),
  chipTextStyle: TextStyle(
    color: Color(0xFF00897B),
    fontWeight: FontWeight.w600,
  ),
  chipBorderColor: Color(0x6600897B),
  selectedItemTextStyle: TextStyle(
    color: Color(0xFF00897B),
    fontWeight: FontWeight.bold,
  ),
  selectedItemBackgroundColor: Color(0x1400897B),
  loadingIndicatorColor: Color(0xFF00897B),
  selectAllTextStyle: TextStyle(
    color: Color(0xFF00897B),
    fontWeight: FontWeight.bold,
  ),
  selectedCountBackgroundColor: Color(0x2600897B),
  selectedCountTextStyle: TextStyle(
    color: Color(0xFF00897B),
    fontWeight: FontWeight.w600,
  ),
);

/// Resolves a [DropdownPlusTheme] that follows the app [ColorScheme] in dark mode.
DropdownPlusTheme? _demoDropdownTheme(
  BuildContext context, {
  DropdownPlusThemeStyle? lightStyle,
  DropdownPlusTheme? accent,
}) {
  final brightness = Theme.of(context).brightness;
  if (brightness == Brightness.light) {
    return accent;
  }

  final cs = Theme.of(context).colorScheme;
  final preset = lightStyle != null
      ? DropdownPlusThemePresets.forStyle(lightStyle)
      : const DropdownPlusTheme();
  final accentColor = accent?.activeBorderColor ?? cs.primary;

  return DropdownPlusTheme(
    backgroundColor: cs.surfaceContainerHigh,
    menuBackgroundColor: cs.surfaceContainerHighest,
    borderColor: cs.outline,
    activeBorderColor: accentColor,
    borderRadius: preset.borderRadius,
    borderWidth: preset.borderWidth,
    activeBorderWidth: preset.activeBorderWidth,
    contentPadding: preset.contentPadding,
    menuBorderRadius: preset.menuBorderRadius,
    menuElevation: preset.menuElevation,
    menuBorderColor: cs.outline,
    searchBarBackgroundColor: cs.surfaceContainerHighest,
    searchBarBorderRadius: preset.searchBarBorderRadius,
    headerBackgroundColor: cs.surfaceContainerHighest,
    dividerColor: cs.outlineVariant,
    hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
    triggerTextStyle: TextStyle(
      color: cs.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    searchHintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
    searchTextStyle: TextStyle(color: cs.onSurface, fontSize: 14),
    searchIconColor: cs.onSurfaceVariant,
    itemTextStyle: TextStyle(color: cs.onSurface, fontSize: 14),
    selectedItemTextStyle: TextStyle(
      color: accentColor,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    selectedItemBackgroundColor: accent?.selectedItemBackgroundColor ??
        cs.primaryContainer.withValues(alpha: 0.35),
    itemPadding: preset.itemPadding,
    chipBackgroundColor: accent?.chipBackgroundColor ??
        cs.primaryContainer.withValues(alpha: 0.45),
    chipTextStyle: accent?.chipTextStyle ??
        TextStyle(
          color: cs.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
    chipBorderColor:
        accent?.chipBorderColor ?? accentColor.withValues(alpha: 0.5),
    chipBorderRadius: preset.chipBorderRadius,
    chipDeleteIconColor: accent?.chipDeleteIconColor ?? accentColor,
    checkboxActiveColor: accent?.checkboxActiveColor ?? accentColor,
    checkboxBorderColor: cs.onSurfaceVariant,
    loadingIndicatorColor: accent?.loadingIndicatorColor ?? accentColor,
    loadingTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
    noResultsTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
    noResultsIconColor: cs.onSurfaceVariant,
    arrowIconColor: cs.onSurfaceVariant,
    selectAllTextStyle: TextStyle(
      color: accentColor,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    selectedCountTextStyle: accent?.selectedCountTextStyle ??
        TextStyle(
          color: accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
    selectedCountBackgroundColor: accent?.selectedCountBackgroundColor ??
        cs.primaryContainer.withValues(alpha: 0.45),
  );
}

/// Light-mode preset only; in dark mode pass [dropdownTheme] via [_demoDropdownTheme].
DropdownPlusThemeStyle? _demoThemeStyle(
  BuildContext context,
  DropdownPlusThemeStyle lightStyle,
) =>
    Theme.of(context).brightness == Brightness.dark ? null : lightStyle;

// ── App ───────────────────────────────────────────────────────────────────────

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dropdown_plus',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: ExamplePage(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = isDark ? const Color(0xFF7C4DFF) : const Color(0xFF5E35B1);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: seed.withValues(alpha: isDark ? 0.22 : 0.14),
      ),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  int _tabIndex = 0;

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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Saved: ${_formSavedUser?.name ?? 'none'}'),
        ),
      );
    }
  }

  void _cycleTheme() {
    final next = switch (widget.themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    widget.onThemeModeChanged(next);
  }

  IconData get _themeIcon => switch (widget.themeMode) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            actions: [
              IconButton(
                tooltip: 'Toggle theme',
                onPressed: _cycleTheme,
                icon: Icon(_themeIcon),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('dropdown_plus'),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      cs.surface,
                    ],
                  ),
                ),
                child: SizedBox.shrink(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: switch (_tabIndex) {
                      0 => _BlocTab(
                          key: const ValueKey('bloc'),
                          singleCubit: _singleCubit,
                          multiCubit: _multiCubit,
                          selected: _selected,
                          multiSelected: _multiSelected,
                          onSingleChanged: (item) => setState(
                            () => _selected = item as DropdownItem<User>,
                          ),
                          onMultiChanged: (items) => setState(
                            () => _multiSelected =
                                items.cast<DropdownItem<User>>(),
                          ),
                        ),
                      1 => _StandaloneTab(
                          key: const ValueKey('standalone'),
                          plainLocalItems: _plainLocalItems,
                          plainLocalSelected: _plainLocalSelected,
                          plainRemoteItems: _plainRemoteItems,
                          plainRemoteLoading: _plainRemoteLoading,
                          plainRemoteSelected: _plainRemoteSelected,
                          onPlainLocalChanged: (item) =>
                              setState(() => _plainLocalSelected = item),
                          onPlainRemoteChanged: (items) =>
                              setState(() => _plainRemoteSelected = items),
                          onPlainRemoteSearch: _plainRemoteSearch,
                        ),
                      2 => _TypedTab(
                          key: const ValueKey('typed'),
                          typedCubit: _typedCubit,
                          typedSelected: _typedSelected,
                          typedPlainSelected: _typedPlainSelected,
                          onTypedBlocChanged: (user) =>
                              setState(() => _typedSelected = user),
                          onTypedPlainChanged: (user) =>
                              setState(() => _typedPlainSelected = user),
                        ),
                      _ => _FormTab(
                          key: const ValueKey('form'),
                          formKey: _formKey,
                          formSavedUser: _formSavedUser,
                          onSubmit: _submitForm,
                          onSaved: (user) =>
                              setState(() => _formSavedUser = user),
                        ),
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded),
            label: 'BLoC',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets_rounded),
            label: 'Standalone',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Typed',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Forms',
          ),
        ],
      ),
    );
  }
}

// ── Shared UI ─────────────────────────────────────────────────────────────────

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.selection,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Widget child;
  final Widget? selection;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  _Badge(label: badge!),
                ],
              ],
            ),
            const SizedBox(height: 20),
            child,
            if (selection != null) ...[
              const SizedBox(height: 14),
              selection!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _BlocTab extends StatelessWidget {
  const _BlocTab({
    required this.singleCubit,
    required this.multiCubit,
    required this.selected,
    required this.multiSelected,
    required this.onSingleChanged,
    required this.onMultiChanged,
    super.key,
  });

  final UsersCubit singleCubit;
  final UsersCubit multiCubit;
  final DropdownItem<User>? selected;
  final List<DropdownItem<User>> multiSelected;
  final ValueChanged<DropdownItem<dynamic>> onSingleChanged;
  final ValueChanged<List<DropdownItem<dynamic>>> onMultiChanged;

  @override
  Widget build(BuildContext context) {
    const singleStyle = DropdownPlusThemeStyle.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TabHeader(
          title: 'BLoC integration',
          description:
              'Wire dropdowns to a Cubit or Bloc. Search, loading, and item '
              'updates flow through onStateChange.',
        ),
        _DemoCard(
          icon: Icons.person_search_rounded,
          title: 'Single select',
          subtitle: 'SearchableDropdownPlus with remote search and dark theme.',
          badge: 'Legacy API',
          child: SearchableDropdownPlus<UsersCubit, UsersState>(
            cubit: singleCubit,
            hintText: 'Search and select a user…',
            searchHint: 'Type a name or role…',
            noResultsText: 'No users found',
            loadingText: 'Loading…',
            onSearch: singleCubit.search,
            debounceDuration: const Duration(milliseconds: 400),
            themeStyle: _demoThemeStyle(context, singleStyle),
            dropdownTheme: _demoDropdownTheme(context, lightStyle: singleStyle),
            onStateChange: _legacyStateHandler,
            onSelectionChanged: onSingleChanged,
          ),
          selection: selected != null
              ? _SelectionChip(
                  label: 'Selected: ${selected!.label}',
                  color: Colors.green.shade700,
                )
              : null,
        ),
        _DemoCard(
          icon: Icons.group_add_rounded,
          title: 'Multi select',
          subtitle:
              'MultiSelectDropdownPlus with chips, select-all, and custom theme.',
          badge: 'Legacy API',
          child: MultiSelectDropdownPlus<UsersCubit, UsersState>(
            cubit: multiCubit,
            hintText: 'Select users…',
            noResultsText: 'No users found',
            loadingText: 'Loading…',
            maxDisplayChips: 3,
            selectedItems: multiSelected,
            onSearch: multiCubit.search,
            onStateChange: _legacyStateHandler,
            onSelectionChanged: onMultiChanged,
            dropdownTheme: _demoDropdownTheme(
              context,
              accent: _tealAccentTheme,
            ),
          ),
          selection: multiSelected.isNotEmpty
              ? _SelectionChip(
                  label: '${multiSelected.length} selected: '
                      '${multiSelected.map((e) => e.label).join(', ')}',
                  color: const Color(0xFF00897B),
                )
              : null,
        ),
      ],
    );
  }
}

class _StandaloneTab extends StatelessWidget {
  const _StandaloneTab({
    required this.plainLocalItems,
    required this.plainLocalSelected,
    required this.plainRemoteItems,
    required this.plainRemoteLoading,
    required this.plainRemoteSelected,
    required this.onPlainLocalChanged,
    required this.onPlainRemoteChanged,
    required this.onPlainRemoteSearch,
    super.key,
  });

  final List<DropdownItem<dynamic>> plainLocalItems;
  final DropdownItem<dynamic>? plainLocalSelected;
  final List<DropdownItem<dynamic>> plainRemoteItems;
  final bool plainRemoteLoading;
  final List<DropdownItem<dynamic>> plainRemoteSelected;
  final ValueChanged<DropdownItem<dynamic>> onPlainLocalChanged;
  final ValueChanged<List<DropdownItem<dynamic>>> onPlainRemoteChanged;
  final Future<void> Function(String) onPlainRemoteSearch;

  @override
  Widget build(BuildContext context) {
    const localStyle = DropdownPlusThemeStyle.minimal;
    const remoteStyle = DropdownPlusThemeStyle.rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TabHeader(
          title: 'Without BLoC',
          description:
              'Use setState, Provider, Riverpod, or any state solution. Pass '
              'items and isLoading directly.',
        ),
        _DemoCard(
          icon: Icons.filter_list_rounded,
          title: 'Local filter',
          subtitle:
              'SearchableDropdown filters the list on-device — no cubit needed.',
          badge: 'Minimal',
          child: SearchableDropdown(
            hintText: 'Pick a user…',
            items: plainLocalItems,
            isLoading: false,
            selectedValue: plainLocalSelected,
            themeStyle: _demoThemeStyle(context, localStyle),
            dropdownTheme: _demoDropdownTheme(context, lightStyle: localStyle),
            onSelectionChanged: onPlainLocalChanged,
          ),
          selection: plainLocalSelected != null
              ? _SelectionChip(label: 'Selected: ${plainLocalSelected!.label}')
              : null,
        ),
        _DemoCard(
          icon: Icons.cloud_sync_rounded,
          title: 'Remote search',
          subtitle:
              'MultiSelectDropdown with async onSearch and rounded styling.',
          badge: 'Rounded',
          child: MultiSelectDropdown(
            hintText: 'Select users…',
            items: plainRemoteItems,
            isLoading: plainRemoteLoading,
            selectedItems: plainRemoteSelected,
            onSearch: onPlainRemoteSearch,
            searchHint: 'Type a name or role…',
            noResultsText: 'No users found',
            loadingText: 'Loading…',
            maxDisplayChips: 2,
            themeStyle: _demoThemeStyle(context, remoteStyle),
            dropdownTheme: _demoDropdownTheme(context, lightStyle: remoteStyle),
            onSelectionChanged: onPlainRemoteChanged,
          ),
          selection: plainRemoteSelected.isNotEmpty
              ? _SelectionChip(
                  label: '${plainRemoteSelected.length} selected: '
                      '${plainRemoteSelected.map((e) => e.label).join(', ')}',
                )
              : null,
        ),
      ],
    );
  }
}

class _TypedTab extends StatelessWidget {
  const _TypedTab({
    required this.typedCubit,
    required this.typedSelected,
    required this.typedPlainSelected,
    required this.onTypedBlocChanged,
    required this.onTypedPlainChanged,
    super.key,
  });

  final UsersCubit typedCubit;
  final User? typedSelected;
  final User? typedPlainSelected;
  final ValueChanged<User?> onTypedBlocChanged;
  final ValueChanged<User?> onTypedPlainChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const blocStyle = DropdownPlusThemeStyle.dark;
    const plainStyle = DropdownPlusThemeStyle.minimal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TabHeader(
          title: 'Typed API',
          description:
              'Work with your domain models directly — no DropdownItem boilerplate. '
              'Opt-in via package:dropdown_plus_bloc/typed.dart',
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Text(
            "import 'package:dropdown_plus_bloc/typed.dart';",
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: cs.primary,
            ),
          ),
        ),
        _DemoCard(
          icon: Icons.hub_rounded,
          title: 'Typed + BLoC',
          subtitle: 'TypedSearchableDropdownPlus<User, UsersCubit, UsersState>',
          badge: 'Generics',
          child: TypedSearchableDropdownPlus<User, UsersCubit, UsersState>(
            cubit: typedCubit,
            hintText: 'Select a user (typed)…',
            itemLabel: _userLabel,
            itemEquals: (a, b) => a.id == b.id,
            value: typedSelected,
            onChanged: onTypedBlocChanged,
            onSearch: typedCubit.search,
            debounceDuration: const Duration(milliseconds: 400),
            themeStyle: _demoThemeStyle(context, blocStyle),
            dropdownTheme: _demoDropdownTheme(context, lightStyle: blocStyle),
            onStateChange: _typedStateHandler,
          ),
          selection: typedSelected != null
              ? _SelectionChip(
                  label: 'Typed: ${_userLabel(typedSelected!)}',
                  color: cs.primary,
                )
              : null,
        ),
        _DemoCard(
          icon: Icons.data_object_rounded,
          title: 'Typed standalone',
          subtitle: 'TypedSearchableDropdown<User> with a local List<User>.',
          badge: 'Generics',
          child: TypedSearchableDropdown<User>(
            hintText: 'Pick a user (typed, local)…',
            items: kDemoUsers,
            isLoading: false,
            itemLabel: _userLabel,
            value: typedPlainSelected,
            onChanged: onTypedPlainChanged,
            themeStyle: _demoThemeStyle(context, plainStyle),
            dropdownTheme: _demoDropdownTheme(context, lightStyle: plainStyle),
          ),
          selection: typedPlainSelected != null
              ? _SelectionChip(
                  label: 'Typed: ${_userLabel(typedPlainSelected!)}')
              : null,
        ),
      ],
    );
  }
}

class _FormTab extends StatelessWidget {
  const _FormTab({
    required this.formKey,
    required this.formSavedUser,
    required this.onSubmit,
    required this.onSaved,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final User? formSavedUser;
  final VoidCallback onSubmit;
  final ValueChanged<User?> onSaved;

  @override
  Widget build(BuildContext context) {
    const formStyle = DropdownPlusThemeStyle.material;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TabHeader(
          title: 'Form integration',
          description:
              'Wrap any dropdown in a FormField with validator, onSaved, '
              'and autovalidateMode.',
        ),
        _DemoCard(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Required field',
          subtitle: 'SearchableDropdownFormField inside a Form widget.',
          badge: 'FormField',
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchableDropdownFormField(
                  hintText: 'Required: pick a user…',
                  items: _usersToItems(kDemoUsers),
                  isLoading: false,
                  themeStyle: _demoThemeStyle(context, formStyle),
                  dropdownTheme:
                      _demoDropdownTheme(context, lightStyle: formStyle),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      value == null ? 'Please select a user' : null,
                  onSaved: (value) => onSaved(value?.value as User?),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Save form'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          selection: formSavedUser != null
              ? _SelectionChip(
                  label: 'Last saved: ${_userLabel(formSavedUser!)}',
                  color: Colors.green.shade700,
                )
              : null,
        ),
      ],
    );
  }
}
