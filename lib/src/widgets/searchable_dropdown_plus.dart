import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';

/// A single-select searchable dropdown that integrates with any BLoC/Cubit.
///
/// ## Type Parameters
/// - [C] — your Cubit/Bloc type, e.g. `WorkerCubit`
/// - [S] — the state type emitted by [C], e.g. `WorkerState`
///
/// ## Key Features
/// - Real-time search via [onSearch]
/// - Offline caching: falls back to client-side filtering when no internet
/// - Controlled-mode support via [selectedValue] (useful for QR scan, form reset, etc.)
/// - Full visual customisation via [dropdownTheme]
/// - Custom item & selected-value builders
///
/// ## Basic Usage
/// ```dart
/// SearchableDropdownPlus<WorkerCubit, WorkerState>(
///   cubit: workerCubit,
///   hintText: 'Search worker…',
///   onSearch: workerCubit.search,
///   onStateChange: (state, updateList, updateLoading) {
///     if (state is WorkersLoaded) {
///       updateList(state.workers
///           .map((w) => DropdownItem(value: w, label: w.name))
///           .toList());
///       updateLoading(false);
///     } else if (state is WorkersLoading) {
///       updateLoading(true);
///     }
///   },
///   onSelectionChanged: (item) => setState(() => _selected = item.value),
/// )
/// ```
///
/// ## Controlled Mode (e.g. QR scan)
/// ```dart
/// SearchableDropdownPlus(
///   key: ValueKey(qrScanKey), // increment key to force re-sync
///   selectedValue: scannedItem,
///   ...
/// )
/// ```
class SearchableDropdownPlus<C extends StateStreamableSource<S>, S>
    extends StatefulWidget {
  const SearchableDropdownPlus({
    required this.cubit,
    required this.onSearch,
    required this.onStateChange,
    required this.hintText,
    super.key,
    this.selectedValue,
    this.onSelectionChanged,
    this.searchHint,
    this.noResultsText,
    this.loadingText,
    this.needInitialFetch = false,
    this.dropdownTheme,
    this.itemBuilder,
    this.selectedValueBuilder,
    this.checkInternetConnection,
  });

  /// The BLoC/Cubit instance that drives this dropdown.
  final C cubit;

  /// Called whenever the user types in the search box.
  final void Function(String query) onSearch;

  /// Maps incoming BLoC/Cubit states to list updates.
  ///
  /// ```dart
  /// onStateChange: (state, updateList, updateLoading) {
  ///   if (state is LoadedState) {
  ///     updateList(state.items.map((e) => DropdownItem(value: e, label: e.name)).toList());
  ///     updateLoading(false);
  ///   } else if (state is LoadingState) {
  ///     updateLoading(true);
  ///   }
  /// },
  /// ```
  final void Function(
    S state,
    void Function(List<DropdownItem<dynamic>>) updateList,
    void Function(bool) updateLoading,
  ) onStateChange;

  /// Placeholder text shown when no item is selected.
  final String hintText;

  /// Pre-selected item (controlled mode). When provided, the parent owns the
  /// selection state.
  final DropdownItem<dynamic>? selectedValue;

  /// Called when the user picks an item. Not called for programmatic updates
  /// via [selectedValue].
  final void Function(DropdownItem<dynamic> item)? onSelectionChanged;

  /// Hint text shown inside the search input. Defaults to `'Search…'`.
  final String? searchHint;

  /// Message shown when the search returns no results.
  final String? noResultsText;

  /// Message shown while the cubit is loading.
  final String? loadingText;

  /// If `true`, [onSearch] is called with an empty string on widget mount.
  final bool needInitialFetch;

  /// Visual customisation. Falls back to [Theme] values when `null`.
  final DropdownPlusTheme? dropdownTheme;

  /// Override the item row rendering.
  final Widget Function(DropdownItem<dynamic> item, bool isSelected)?
      itemBuilder;

  /// Override how the selected value is displayed in the trigger button.
  final Widget Function(DropdownItem<dynamic> selectedItem)?
      selectedValueBuilder;

  /// Optional async function returning `true` when the device is online.
  /// When `null`, the widget always performs remote search (no offline fallback).
  ///
  /// ```dart
  /// checkInternetConnection: () async {
  ///   final result = await Connectivity().checkConnectivity();
  ///   return result != ConnectivityResult.none;
  /// },
  /// ```
  final Future<bool> Function()? checkInternetConnection;

  @override
  State<SearchableDropdownPlus<C, S>> createState() =>
      _SearchableDropdownPlusState<C, S>();
}

class _SearchableDropdownPlusState<C extends StateStreamableSource<S>, S>
    extends State<SearchableDropdownPlus<C, S>> {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
  bool _isLoading = false;
  bool _isOpen = false;
  DropdownItem<dynamic>? _selected;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedValue;
    if (widget.needInitialFetch) widget.onSearch('');
  }

  @override
  void didUpdateWidget(SearchableDropdownPlus<C, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue) {
      setState(() => _selected = widget.selectedValue);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<bool> _hasInternet() async => widget.checkInternetConnection == null
      ? true
      : await widget.checkInternetConnection!();

  void _localSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _items = q.isEmpty
          ? _cache
          : _cache.where((i) => i.label.toLowerCase().contains(q)).toList();
    });
  }

  void _onBlocState(S state) {
    widget.onStateChange(
      state,
      (items) => setState(() {
        _items = items;
        if (items.isNotEmpty &&
            (_searchController.text.isEmpty || _cache.isEmpty)) {
          _cache = items;
        }
      }),
      (loading) => setState(() {
        _isLoading = loading;
        // Uncontrolled mode: clear selection while a new load begins
        if (loading && widget.selectedValue == null) _selected = null;
      }),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = widget.dropdownTheme ?? const DropdownPlusTheme();
    final cs = Theme.of(context).colorScheme;

    final borderCol = t.borderColor ?? cs.outline.withOpacity(0.5);
    final activeBorderCol = t.activeBorderColor ?? cs.primary;
    final divCol = t.dividerColor ?? cs.outline.withOpacity(0.08);
    final loadCol = t.loadingIndicatorColor ?? cs.primary;
    final noResIconCol = t.noResultsIconColor ?? cs.onSurface.withOpacity(0.4);
    final arrowCol = _isOpen
        ? activeBorderCol
        : (t.arrowIconColor ?? cs.onSurface.withOpacity(0.6));

    return BlocProvider<C>(
      create: (_) => widget.cubit,
      child: BlocListener<C, S>(
        bloc: widget.cubit,
        listener: (_, state) => _onBlocState(state),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTrigger(t, cs, borderCol, activeBorderCol, loadCol, arrowCol),
            _buildPanel(t, cs, divCol, loadCol, noResIconCol),
          ],
        ),
      ),
    );
  }

  // ── Trigger button ─────────────────────────────────────────────────────────

  Widget _buildTrigger(
    DropdownPlusTheme t,
    ColorScheme cs,
    Color borderCol,
    Color activeBorderCol,
    Color loadCol,
    Color arrowCol,
  ) {
    return GestureDetector(
      onTap: () async {
        final opening = !_isOpen;
        setState(() => _isOpen = opening);
        if (opening) {
          final online = await _hasInternet();
          if (online) {
            _searchController.clear();
            widget.onSearch('');
          } else if (_cache.isNotEmpty) {
            setState(() => _items = _cache);
          }
        } else {
          _searchController.clear();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: t.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(t.borderRadius),
          border: Border.all(
            color: _isOpen ? activeBorderCol : borderCol,
            width: _isOpen ? t.activeBorderWidth : t.borderWidth,
          ),
          boxShadow: _isOpen
              ? [
                  BoxShadow(
                    color: activeBorderCol.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(child: _buildTriggerContent(t, cs)),
            if (_isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(loadCol),
                ),
              ),
              const SizedBox(width: 8),
            ],
            AnimatedRotation(
              turns: _isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: arrowCol, size: t.arrowIconSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerContent(DropdownPlusTheme t, ColorScheme cs) {
    if (_selected == null) {
      return Text(
        widget.hintText,
        style: t.hintStyle ??
            TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w400),
      );
    }
    return widget.selectedValueBuilder?.call(_selected!) ??
        Text(
          _selected!.label,
          style: t.triggerTextStyle ??
              Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
        );
  }

  // ── Dropdown panel ─────────────────────────────────────────────────────────

  Widget _buildPanel(
    DropdownPlusTheme t,
    ColorScheme cs,
    Color divCol,
    Color loadCol,
    Color noResIconCol,
  ) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _isOpen
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Material(
                elevation: t.menuElevation,
                shadowColor: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(t.menuBorderRadius),
                color: t.menuBackgroundColor ?? Colors.white,
                child: Container(
                  constraints: BoxConstraints(maxHeight: t.menuMaxHeight),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.menuBorderRadius),
                    border: Border.all(
                      color: t.menuBorderColor ?? cs.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchBar(t, cs),
                      Divider(height: 1, thickness: 1, color: divCol),
                      _buildResults(t, cs, divCol, loadCol, noResIconCol),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchBar(DropdownPlusTheme t, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: t.searchBarBackgroundColor ??
              cs.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(t.searchBarBorderRadius),
        ),
        child: TextField(
          controller: _searchController,
          style: t.searchTextStyle,
          decoration: InputDecoration(
            hintText: widget.searchHint ?? 'Search…',
            hintStyle: t.searchHintStyle ??
                TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20,
                color: t.searchIconColor ?? cs.onSurface.withOpacity(0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) async {
            final online = await _hasInternet();
            online ? widget.onSearch(value) : _localSearch(value);
          },
        ),
      ),
    );
  }

  Widget _buildResults(
    DropdownPlusTheme t,
    ColorScheme cs,
    Color divCol,
    Color loadCol,
    Color noResIconCol,
  ) {
    if (_items.isNotEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _items.length,
          separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              indent: 12,
              endIndent: 12,
              color: divCol),
          itemBuilder: (ctx, i) {
            final item = _items[i];
            final isSelected = _selected?.value == item.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selected = item;
                    _isOpen = false;
                  });
                  widget.onSelectionChanged?.call(item);
                  _searchController.clear();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: t.itemPadding ??
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (t.selectedItemBackgroundColor ??
                            cs.primaryContainer.withOpacity(0.3))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.itemBuilder?.call(item, isSelected) ??
                      _defaultRow(t, cs, item, isSelected),
                ),
              ),
            );
          },
        ),
      );
    }

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(loadCol),
              ),
            ),
            if (widget.loadingText?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  widget.loadingText!,
                  style: t.loadingTextStyle ??
                      TextStyle(
                          fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 24, color: noResIconCol),
          if (widget.noResultsText?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.noResultsText!,
                textAlign: TextAlign.center,
                style: t.noResultsTextStyle ??
                    TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultRow(
    DropdownPlusTheme t,
    ColorScheme cs,
    DropdownItem<dynamic> item,
    bool isSelected,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.label,
            style: isSelected
                ? (t.selectedItemTextStyle ??
                    TextStyle(
                        fontSize: 14,
                        color: cs.primary,
                        fontWeight: FontWeight.w500))
                : (t.itemTextStyle ??
                    TextStyle(fontSize: 14, color: cs.onSurface)),
          ),
        ),
        if (isSelected)
          Icon(Icons.check_circle_rounded, size: 20, color: cs.primary),
      ],
    );
  }
}
