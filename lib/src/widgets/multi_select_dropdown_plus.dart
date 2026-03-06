import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';

/// A multi-select dropdown that integrates with any BLoC/Cubit.
///
/// ## Type Parameters
/// - [C] — your Cubit/Bloc type, e.g. `WorkerCubit`
/// - [S] — the state type emitted by [C], e.g. `WorkerState`
///
/// ## Key Features
/// - Select / deselect multiple items with animated circular checkboxes
/// - "Select All" / "Clear All" header action
/// - Chip display with overflow "+N more" badge
/// - Real-time search via [onSearch]
/// - Offline caching with client-side fallback filtering
/// - Controlled mode via [selectedItems]
/// - Full visual customisation via [dropdownTheme]
/// - Custom item & chip builders
///
/// ## Basic Usage
/// ```dart
/// MultiSelectDropdownPlus<WorkerCubit, WorkerState>(
///   cubit: workerCubit,
///   hintText: 'Select workers…',
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
///   onSelectionChanged: (items) =>
///       setState(() => _selected = items.map((e) => e.value).toList()),
/// )
/// ```
class MultiSelectDropdownPlus<C extends StateStreamableSource<S>, S>
    extends StatefulWidget {
  const MultiSelectDropdownPlus({
    required this.cubit,
    required this.onSearch,
    required this.onStateChange,
    required this.hintText,
    super.key,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.searchHint,
    this.noResultsText,
    this.loadingText,
    this.needInitialFetch = false,
    this.maxDisplayChips = 2,
    this.dropdownTheme,
    this.itemBuilder,
    this.selectedItemBuilder,
    this.buttonHeight,
    this.buttonWidth,
    this.checkInternetConnection,
  });

  /// The BLoC/Cubit instance that drives this dropdown.
  final C cubit;

  /// Called whenever the user types in the search box.
  final void Function(String query) onSearch;

  /// Maps incoming BLoC/Cubit states to list updates.
  final void Function(
    S state,
    void Function(List<DropdownItem<dynamic>>) updateList,
    void Function(bool) updateLoading,
  ) onStateChange;

  /// Placeholder text shown when nothing is selected.
  final String hintText;

  /// Pre-selected items (controlled mode).
  final List<DropdownItem<dynamic>> selectedItems;

  /// Called when the user changes the selection.
  final void Function(List<DropdownItem<dynamic>> items)? onSelectionChanged;

  /// Hint text for the search input. Defaults to `'Search…'`.
  final String? searchHint;

  /// Message shown when search returns no results.
  final String? noResultsText;

  /// Message shown while loading.
  final String? loadingText;

  /// If `true`, [onSearch] is called on widget mount.
  final bool needInitialFetch;

  /// Maximum chips shown before "+N more" overflow. Default: `2`.
  final int maxDisplayChips;

  /// Visual customisation.
  final DropdownPlusTheme? dropdownTheme;

  /// Override item row rendering.
  final Widget Function(DropdownItem<dynamic> item, bool isSelected)?
      itemBuilder;

  /// Override the chips display inside the trigger button.
  final Widget Function(List<DropdownItem<dynamic>> selected)?
      selectedItemBuilder;

  /// Fixed height of the trigger button.
  final double? buttonHeight;

  /// Fixed width of the trigger button.
  final double? buttonWidth;

  /// Optional internet check — enables offline caching when provided.
  final Future<bool> Function()? checkInternetConnection;

  @override
  State<MultiSelectDropdownPlus<C, S>> createState() =>
      _MultiSelectDropdownPlusState<C, S>();
}

class _MultiSelectDropdownPlusState<C extends StateStreamableSource<S>, S>
    extends State<MultiSelectDropdownPlus<C, S>> {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
  bool _isLoading = false;
  bool _isOpen = false;
  late List<DropdownItem<dynamic>> _selected;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedItems);
    if (widget.needInitialFetch) widget.onSearch('');
  }

  @override
  void didUpdateWidget(MultiSelectDropdownPlus<C, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItems != widget.selectedItems) {
      setState(() => _selected = List.from(widget.selectedItems));
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
      (loading) => setState(() => _isLoading = loading),
    );
  }

  void _toggleItem(DropdownItem<dynamic> item) {
    final updated = List<DropdownItem<dynamic>>.from(_selected);
    final alreadySelected = updated.any((s) => s.value == item.value);
    if (alreadySelected) {
      updated.removeWhere((s) => s.value == item.value);
    } else {
      updated.add(item);
    }
    setState(() => _selected = updated);
    widget.onSelectionChanged?.call(updated);
  }

  void _selectAll() {
    final updated = List<DropdownItem<dynamic>>.from(_items);
    setState(() => _selected = updated);
    widget.onSelectionChanged?.call(updated);
  }

  void _clearAll() {
    setState(() => _selected = []);
    widget.onSelectionChanged?.call([]);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = widget.dropdownTheme ?? const DropdownPlusTheme();
    final cs = Theme.of(context).colorScheme;

    final borderCol = t.borderColor ?? cs.outline.withOpacity(0.5);
    final activeBorderCol = t.activeBorderColor ?? cs.primary;
    final divCol = t.dividerColor ?? cs.outline.withOpacity(0.1);
    final loadCol = t.loadingIndicatorColor ?? cs.primary;
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
            _buildPanel(t, cs, divCol, loadCol),
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
        if (opening && _items.isEmpty) {
          final online = await _hasInternet();
          if (online) {
            widget.onSearch('');
          } else if (_cache.isNotEmpty) {
            setState(() => _items = _cache);
          }
        } else if (!opening) {
          _searchController.clear();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.buttonWidth,
        height: widget.buttonHeight,
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
            const SizedBox(width: 8),
            if (_isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(loadCol),
                ),
              ),
              const SizedBox(width: 4),
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
    if (_selected.isEmpty) {
      return Text(
        widget.hintText,
        style: t.hintStyle ??
            TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w400),
      );
    }
    return widget.selectedItemBuilder?.call(_selected) ?? _buildChipRow(t, cs);
  }

  // ── Dropdown panel ─────────────────────────────────────────────────────────

  Widget _buildPanel(
    DropdownPlusTheme t,
    ColorScheme cs,
    Color divCol,
    Color loadCol,
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
                      _buildHeader(t, cs, divCol),
                      Flexible(child: _buildResults(t, cs, divCol, loadCol)),
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

  Widget _buildHeader(DropdownPlusTheme t, ColorScheme cs, Color divCol) {
    final allSelected = _items.isNotEmpty && _selected.length == _items.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.headerBackgroundColor ??
            cs.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: divCol),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: allSelected ? _clearAll : _selectAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                allSelected ? 'Clear All' : 'Select All',
                style: t.selectAllTextStyle ??
                    TextStyle(
                        fontSize: 13,
                        color: cs.primary,
                        fontWeight: FontWeight.w600),
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              if (_selected.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.selectedCountBackgroundColor ??
                        cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selected.length} selected',
                    style: t.selectedCountTextStyle ??
                        TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.primary),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _isOpen = false);
                  _searchController.clear();
                },
                child: Icon(Icons.close_rounded,
                    size: 20, color: cs.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    DropdownPlusTheme t,
    ColorScheme cs,
    Color divCol,
    Color loadCol,
  ) {
    if (_items.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _items.length,
        separatorBuilder: (_, __) => Divider(
            height: 1, thickness: 1, color: divCol, indent: 16, endIndent: 16),
        itemBuilder: (ctx, i) {
          final item = _items[i];
          final isSelected = _selected.any((s) => s.value == item.value);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleItem(item),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: t.itemPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      );
    }

    // Loading or empty state
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(loadCol),
              ),
            ),
            if (widget.loadingText?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(widget.loadingText!,
                  style: t.loadingTextStyle ??
                      TextStyle(
                          fontSize: 13, color: cs.onSurface.withOpacity(0.6))),
            ],
          ] else ...[
            Icon(Icons.search_off_rounded,
                size: 48,
                color: t.noResultsIconColor ?? cs.onSurface.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              widget.noResultsText ?? 'No items found',
              style: t.noResultsTextStyle ??
                  TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // ── Chip display ───────────────────────────────────────────────────────────

  Widget _buildChipRow(DropdownPlusTheme t, ColorScheme cs) {
    final visible = _selected.length <= widget.maxDisplayChips
        ? _selected
        : _selected.take(widget.maxDisplayChips).toList();
    final overflow = _selected.length - widget.maxDisplayChips;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map((item) => _chip(
              t,
              cs,
              label: item.label,
              onDelete: () {
                final updated = List<DropdownItem<dynamic>>.from(_selected)
                  ..removeWhere((s) => s.value == item.value);
                setState(() => _selected = updated);
                widget.onSelectionChanged?.call(updated);
              },
            )),
        if (overflow > 0) _chip(t, cs, label: '+$overflow more', isCount: true),
      ],
    );
  }

  Widget _chip(
    DropdownPlusTheme t,
    ColorScheme cs, {
    required String label,
    VoidCallback? onDelete,
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCount
            ? (t.countChipBackgroundColor ?? cs.surfaceContainerHighest)
            : (t.chipBackgroundColor ?? cs.primary.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(t.chipBorderRadius),
        border: Border.all(
          color: isCount
              ? (t.chipBorderColor ?? cs.outline.withOpacity(0.3))
              : (t.chipBorderColor ?? cs.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: isCount
                  ? (t.countChipTextStyle ??
                      TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500))
                  : (t.chipTextStyle ??
                      TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w500)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: (t.chipDeleteIconColor ?? cs.primary).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: t.chipDeleteIconSize,
                  color: t.chipDeleteIconColor ?? cs.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Default item row ───────────────────────────────────────────────────────

  Widget _defaultRow(
    DropdownPlusTheme t,
    ColorScheme cs,
    DropdownItem<dynamic> item,
    bool isSelected,
  ) {
    final activeCol = t.checkboxActiveColor ?? cs.primary;
    final inactiveCol = t.checkboxBorderColor ?? cs.outline.withOpacity(0.4);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: t.checkboxSize,
          height: t.checkboxSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? activeCol : inactiveCol,
              width: 2,
            ),
            color: isSelected ? activeCol : Colors.transparent,
          ),
          child: isSelected
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            item.label,
            style: isSelected
                ? (t.selectedItemTextStyle ??
                    TextStyle(
                        fontSize: 14,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600))
                : (t.itemTextStyle ??
                    TextStyle(
                        fontSize: 14,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w400)),
          ),
        ),
      ],
    );
  }
}
