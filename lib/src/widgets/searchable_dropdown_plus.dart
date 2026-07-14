import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../internal/dropdown_internet.dart';
import '../internal/dropdown_menu_controller.dart';
import '../internal/dropdown_panel.dart';
import '../internal/dropdown_search_bar.dart';
import '../internal/dropdown_single_select.dart';
import '../internal/dropdown_states.dart';
import '../internal/dropdown_theme_resolver.dart';
import '../internal/dropdown_trigger.dart';
import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../utils/debounced_callback.dart';

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
/// - Full visual customisation via [dropdownTheme] or preset [themeStyle]
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
class SearchableDropdownPlus<C extends BlocBase<S>, S>
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
    this.themeStyle,
    this.itemBuilder,
    this.selectedValueBuilder,
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
    this.menuController,
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

  /// Visual customisation. When null, [themeStyle] is used if set.
  final DropdownPlusTheme? dropdownTheme;

  /// Preset theme style. Ignored when [dropdownTheme] is non-null.
  /// Use for out-of-the-box looks: [DropdownPlusThemeStyle.minimal],
  /// [DropdownPlusThemeStyle.dark], etc.
  final DropdownPlusThemeStyle? themeStyle;

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

  /// Debounce delay before [onSearch] is invoked. Default: no debounce.
  final Duration debounceDuration;

  /// When `false`, the dropdown cannot be opened or searched.
  final bool enabled;

  /// Focus the search field when the panel opens.
  final bool autofocusSearch;

  /// Custom empty-state UI when there are no results.
  final DropdownEmptyBuilder? emptyBuilder;

  /// Custom loading UI while items are loading.
  final DropdownLoadingBuilder? loadingBuilder;

  /// Optional error to display in the panel (controlled mode).
  final Object? error;

  /// Called when the user taps retry in the default error UI.
  final VoidCallback? onRetry;

  /// Custom error UI. Receives [onRetry] for retry actions.
  final DropdownErrorBuilder? errorBuilder;

  /// Semantics label for the trigger button.
  final String? semanticsLabel;

  /// Minimum query length before [onSearch] is invoked (empty query always fires).
  final int minSearchLength;

  /// Called when the user scrolls near the bottom of the item list.
  final VoidCallback? onLoadMore;

  /// Whether more items can be loaded via [onLoadMore].
  final bool hasMore;

  /// Shows a loading footer while the next page loads.
  final bool isLoadingMore;

  /// Optional focus node for the trigger button.
  final FocusNode? focusNode;

  /// Optional menu controller for programmatic open/close.
  ///
  /// Used by the typed API (`DropdownPlusController`). Prefer typed widgets
  /// rather than assigning this directly.
  final DropdownMenuController? menuController;

  @override
  State<SearchableDropdownPlus<C, S>> createState() =>
      _SearchableDropdownPlusState<C, S>();
}

class _SearchableDropdownPlusState<C extends BlocBase<S>, S>
    extends State<SearchableDropdownPlus<C, S>>
    implements DropdownMenuClient {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
  bool _isLoading = false;
  bool _isOpen = false;
  DropdownItem<dynamic>? _selected;
  final TextEditingController _searchController = TextEditingController();
  late DebouncedCallback _debouncedSearch;

  @override
  bool get isMenuOpen => _isOpen;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedCallback(duration: widget.debounceDuration);
    _selected = widget.selectedValue;
    widget.menuController?.bindClient(this);
    if (widget.needInitialFetch) widget.onSearch('');
  }

  @override
  void didUpdateWidget(SearchableDropdownPlus<C, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuController != widget.menuController) {
      oldWidget.menuController?.unbindClient(this);
      widget.menuController?.bindClient(this);
    }
    if (oldWidget.debounceDuration != widget.debounceDuration) {
      _debouncedSearch.dispose();
      _debouncedSearch = DebouncedCallback(duration: widget.debounceDuration);
    }
    if (oldWidget.selectedValue != widget.selectedValue) {
      setState(() => _selected = widget.selectedValue);
    }
  }

  @override
  void dispose() {
    widget.menuController?.unbindClient(this);
    _debouncedSearch.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> openMenu() async {
    if (!widget.enabled || _isOpen) return;
    setState(() => _isOpen = true);
    await _onOpened();
  }

  @override
  void closeMenu() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _searchController.clear();
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
      (loading) => setState(() {
        _isLoading = loading;
        if (loading && widget.selectedValue == null) _selected = null;
      }),
    );
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

  Future<void> _onOpened() async {
    final online = await dropdownHasInternet(widget.checkInternetConnection);
    if (!mounted) return;
    if (online) {
      _searchController.clear();
      widget.onSearch('');
    } else if (_cache.isNotEmpty) {
      setState(() => _items = _cache);
    }
  }

  Future<void> _handleTriggerTap() async {
    if (!widget.enabled) return;
    if (_isOpen) {
      closeMenu();
    } else {
      await openMenu();
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownTriggerButton(
              resolved: resolved,
              isOpen: _isOpen,
              enabled: widget.enabled,
              semanticsLabel: widget.semanticsLabel ?? widget.hintText,
              focusNode: widget.focusNode,
              showLoadingSpinner: _isLoading,
              onTap: _handleTriggerTap,
              child: _buildTriggerContent(resolved),
            ),
            DropdownPanelShell(
              resolved: resolved,
              isOpen: _isOpen && widget.enabled,
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
                Divider(height: 1, thickness: 1, color: resolved.dividerColor),
                _buildResults(resolved),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerContent(DropdownResolvedTheme resolved) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;

    if (_selected == null) {
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
      return DropdownSingleSelectItemList(
        resolved: resolved,
        items: _items,
        itemBuilder: widget.itemBuilder,
        onLoadMore: widget.onLoadMore,
        hasMore: widget.hasMore,
        isLoadingMore: widget.isLoadingMore,
        isItemSelected: (item) => _selected?.value == item.value,
        onItemTap: (item) {
          setState(() => _selected = item);
          closeMenu();
          widget.onSelectionChanged?.call(item);
        },
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
      noResultsText: widget.noResultsText,
      emptyBuilder: widget.emptyBuilder,
    );
  }
}
