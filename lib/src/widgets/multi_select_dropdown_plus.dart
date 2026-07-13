import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../internal/dropdown_internet.dart';
import '../internal/dropdown_multi_select.dart';
import '../internal/dropdown_panel.dart';
import '../internal/dropdown_search_bar.dart';
import '../internal/dropdown_states.dart';
import '../internal/dropdown_theme_resolver.dart';
import '../internal/dropdown_trigger.dart';
import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../utils/debounced_callback.dart';

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
/// - Full visual customisation via [dropdownTheme] or preset [themeStyle]
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
class MultiSelectDropdownPlus<C extends BlocBase<S>, S>
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
    this.themeStyle,
    this.itemBuilder,
    this.selectedItemBuilder,
    this.buttonHeight,
    this.buttonWidth,
    this.checkInternetConnection,
    this.debounceDuration = Duration.zero,
    this.enabled = true,
    this.autofocusSearch = false,
    this.emptyBuilder,
    this.loadingBuilder,
    this.error,
    this.onRetry,
    this.errorBuilder,
    this.semanticsLabel,
    this.minSearchLength = 0,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.focusNode,
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

  /// Visual customisation. When null, [themeStyle] is used if set.
  final DropdownPlusTheme? dropdownTheme;

  /// Preset theme style. Ignored when [dropdownTheme] is non-null.
  final DropdownPlusThemeStyle? themeStyle;

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

  /// Debounce delay before [onSearch] is invoked. Default: no debounce.
  final Duration debounceDuration;

  final bool enabled;
  final bool autofocusSearch;
  final DropdownEmptyBuilder? emptyBuilder;
  final DropdownLoadingBuilder? loadingBuilder;
  final Object? error;
  final VoidCallback? onRetry;
  final DropdownErrorBuilder? errorBuilder;
  final String? semanticsLabel;
  final int minSearchLength;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final FocusNode? focusNode;

  @override
  State<MultiSelectDropdownPlus<C, S>> createState() =>
      _MultiSelectDropdownPlusState<C, S>();
}

class _MultiSelectDropdownPlusState<C extends BlocBase<S>, S>
    extends State<MultiSelectDropdownPlus<C, S>> {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
  bool _isLoading = false;
  bool _isOpen = false;
  late List<DropdownItem<dynamic>> _selected;
  final TextEditingController _searchController = TextEditingController();
  late DebouncedCallback _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedCallback(duration: widget.debounceDuration);
    _selected = List.from(widget.selectedItems);
    if (widget.needInitialFetch) widget.onSearch('');
  }

  @override
  void didUpdateWidget(MultiSelectDropdownPlus<C, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debounceDuration != widget.debounceDuration) {
      _debouncedSearch.dispose();
      _debouncedSearch = DebouncedCallback(duration: widget.debounceDuration);
    }
    if (oldWidget.selectedItems != widget.selectedItems) {
      setState(() => _selected = List.from(widget.selectedItems));
    }
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _handleQueryChanged(String value) async {
    final online = await dropdownHasInternet(widget.checkInternetConnection);
    if (!mounted) return;
    if (online) {
      widget.onSearch(value);
    } else {
      _localSearch(value);
    }
  }

  Future<void> _handleTriggerTap() async {
    if (!widget.enabled) return;
    final opening = !_isOpen;
    setState(() => _isOpen = opening);
    if (opening && _items.isEmpty) {
      final online = await dropdownHasInternet(widget.checkInternetConnection);
      if (online) {
        widget.onSearch('');
      } else if (_cache.isNotEmpty) {
        setState(() => _items = _cache);
      }
    } else if (!opening) {
      _searchController.clear();
    }
  }

  void _closePanel() {
    setState(() => _isOpen = false);
    _searchController.clear();
  }

  void _handleRetry() {
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      widget.onSearch(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = DropdownResolvedTheme.resolve(
      context,
      dropdownTheme: widget.dropdownTheme,
      themeStyle: widget.themeStyle,
    );

    return BlocProvider<C>.value(
      value: widget.cubit,
      child: BlocListener<C, S>(
        bloc: widget.cubit,
        listener: (_, state) => _onBlocState(state),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelMax = resolveMultiSelectPanelMaxHeight(
              constraints,
              resolved.theme.menuMaxHeight,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownTriggerButton(
                  resolved: resolved,
                  isOpen: _isOpen,
                  enabled: widget.enabled,
                  semanticsLabel: widget.semanticsLabel ?? widget.hintText,
                  focusNode: widget.focusNode,
                  width: widget.buttonWidth,
                  height: widget.buttonHeight,
                  showLoadingSpinner: _isLoading,
                  onTap: _handleTriggerTap,
                  child: _buildTriggerContent(resolved),
                ),
                DropdownPanelShell(
                  resolved: resolved,
                  isOpen: _isOpen && widget.enabled,
                  maxHeight: panelMax,
                  expandBody: true,
                  children: [
                    DropdownSearchBar(
                      resolved: resolved,
                      controller: _searchController,
                      debouncedSearch: _debouncedSearch,
                      searchHint: widget.searchHint,
                      enabled: widget.enabled,
                      autofocus: widget.autofocusSearch,
                      minSearchLength: widget.minSearchLength,
                      onQueryChanged: _handleQueryChanged,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: resolved.dividerColor,
                    ),
                    DropdownMultiSelectHeader(
                      resolved: resolved,
                      itemCount: _items.length,
                      selectedCount: _selected.length,
                      allSelected:
                          _items.isNotEmpty && _selected.length == _items.length,
                      onSelectAll: _selectAll,
                      onClearAll: _clearAll,
                      onClose: _closePanel,
                    ),
                    _buildResults(resolved),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTriggerContent(DropdownResolvedTheme resolved) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;

    if (_selected.isEmpty) {
      return Text(
        widget.hintText,
        style: t.hintStyle ??
            TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
      );
    }
    return widget.selectedItemBuilder?.call(_selected) ??
        DropdownChipRow(
          resolved: resolved,
          selected: _selected,
          maxDisplayChips: widget.maxDisplayChips,
          onRemove: (item) {
            final updated = List<DropdownItem<dynamic>>.from(_selected)
              ..removeWhere((s) => s.value == item.value);
            setState(() => _selected = updated);
            widget.onSelectionChanged?.call(updated);
          },
        );
  }

  Widget _buildResults(DropdownResolvedTheme resolved) {
    if (widget.error != null) {
      return DropdownErrorState(
        resolved: resolved,
        error: widget.error!,
        onRetry: _handleRetry,
        errorBuilder: widget.errorBuilder,
      );
    }

    if (_items.isNotEmpty) {
      return DropdownMultiSelectItemList(
        resolved: resolved,
        items: _items,
        itemBuilder: widget.itemBuilder,
        onLoadMore: widget.onLoadMore,
        hasMore: widget.hasMore,
        isLoadingMore: widget.isLoadingMore,
        isItemSelected: (item) =>
            _selected.any((s) => s.value == item.value),
        onItemTap: _toggleItem,
      );
    }

    if (_isLoading) {
      return DropdownLoadingState(
        resolved: resolved,
        loadingText: widget.loadingText,
        loadingBuilder: widget.loadingBuilder,
      );
    }

    return DropdownEmptyState(
      resolved: resolved,
      noResultsText: widget.noResultsText ?? 'No items found',
      emptyBuilder: widget.emptyBuilder,
      compact: true,
    );
  }
}
