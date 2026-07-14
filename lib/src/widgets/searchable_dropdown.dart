import 'package:flutter/material.dart';

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

/// Single-select searchable dropdown **without** BLoC/Cubit.
///
/// Pass [items] and [isLoading] from your own state (e.g. `setState`, Riverpod,
/// Provider). When [onSearch] is non-null, call it on each query change while
/// online; update [items] from the parent when results arrive. When [onSearch]
/// is null, the list is filtered locally against the last full list cached from
/// [items].
class SearchableDropdown extends StatefulWidget {
  const SearchableDropdown({
    required this.hintText,
    required this.items,
    required this.isLoading,
    super.key,
    this.selectedValue,
    this.onSelectionChanged,
    this.onSearch,
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

  /// Items currently shown (after remote search or full list for local filter).
  final List<DropdownItem<dynamic>> items;

  /// When `true`, the trigger shows a small spinner.
  final bool isLoading;

  /// Called on each search box change while online, if non-null.
  final void Function(String query)? onSearch;

  /// Placeholder when nothing is selected.
  final String hintText;

  final DropdownItem<dynamic>? selectedValue;

  final void Function(DropdownItem<dynamic> item)? onSelectionChanged;

  final String? searchHint;
  final String? noResultsText;
  final String? loadingText;

  /// If `true` and [onSearch] is non-null, calls `onSearch('')` once on mount.
  final bool needInitialFetch;

  final DropdownPlusTheme? dropdownTheme;
  final DropdownPlusThemeStyle? themeStyle;

  final Widget Function(DropdownItem<dynamic> item, bool isSelected)?
      itemBuilder;

  final Widget Function(DropdownItem<dynamic> selectedItem)?
      selectedValueBuilder;

  final Future<bool> Function()? checkInternetConnection;

  /// Debounce delay before [onSearch] is invoked. Default: no debounce.
  final Duration debounceDuration;

  /// When `false`, the dropdown cannot be opened or searched.
  final bool enabled;

  /// Focus the search field when the panel opens.
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

  /// Optional menu controller for programmatic open/close (typed API).
  final DropdownMenuController? menuController;

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown>
    implements DropdownMenuClient {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
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
    _items = List.from(widget.items);
    _cache = List.from(widget.items);
    widget.menuController?.bindClient(this);
    if (widget.needInitialFetch && widget.onSearch != null) {
      widget.onSearch!('');
    }
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
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
    if (widget.isLoading &&
        !oldWidget.isLoading &&
        widget.selectedValue == null) {
      setState(() => _selected = null);
    }
    if (oldWidget.items != widget.items ||
        oldWidget.isLoading != widget.isLoading) {
      setState(() {
        _items = List.from(widget.items);
        if (widget.items.isNotEmpty &&
            (_searchController.text.isEmpty || _cache.isEmpty)) {
          _cache = List.from(widget.items);
        }
        if (_searchController.text.isNotEmpty && widget.onSearch == null) {
          _localSearch(_searchController.text);
        }
      });
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

  Future<void> _handleQueryChanged(String value) async {
    final online = await dropdownHasInternet(widget.checkInternetConnection);
    if (!mounted) return;
    if (online && widget.onSearch != null) {
      widget.onSearch!(value);
    } else {
      _localSearch(value);
    }
  }

  Future<void> _onOpened() async {
    final online = await dropdownHasInternet(widget.checkInternetConnection);
    if (!mounted) return;
    if (widget.onSearch != null) {
      if (online) {
        _searchController.clear();
        widget.onSearch!('');
      } else if (_cache.isNotEmpty) {
        setState(() => _items = _cache);
      }
    } else {
      setState(() {
        _items = List.from(widget.items);
        _cache = List.from(widget.items);
      });
      if (_searchController.text.isNotEmpty) {
        _localSearch(_searchController.text);
      }
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
    } else if (widget.onSearch != null) {
      widget.onSearch!(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = DropdownResolvedTheme.resolve(
      context,
      dropdownTheme: widget.dropdownTheme,
      themeStyle: widget.themeStyle,
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
          showLoadingSpinner: widget.isLoading && widget.items.isEmpty,
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

    if (widget.isLoading) {
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
