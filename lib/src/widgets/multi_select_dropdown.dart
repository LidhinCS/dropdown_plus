import 'package:flutter/material.dart';

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

/// Multi-select searchable dropdown **without** BLoC/Cubit.
///
/// Pass [items] and [isLoading] from your own state. When [onSearch] is
/// non-null, it is called on each query while online; otherwise the list is
/// filtered locally against the cached full list from [items].
class MultiSelectDropdown extends StatefulWidget {
  const MultiSelectDropdown({
    required this.hintText,
    required this.items,
    required this.isLoading,
    super.key,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.onSearch,
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

  final List<DropdownItem<dynamic>> items;

  final bool isLoading;

  final void Function(String query)? onSearch;

  final String hintText;

  final List<DropdownItem<dynamic>> selectedItems;

  final void Function(List<DropdownItem<dynamic>> items)? onSelectionChanged;

  final String? searchHint;
  final String? noResultsText;
  final String? loadingText;

  final bool needInitialFetch;

  final int maxDisplayChips;

  final DropdownPlusTheme? dropdownTheme;
  final DropdownPlusThemeStyle? themeStyle;

  final Widget Function(DropdownItem<dynamic> item, bool isSelected)?
      itemBuilder;

  final Widget Function(List<DropdownItem<dynamic>> selected)?
      selectedItemBuilder;

  final double? buttonHeight;
  final double? buttonWidth;

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
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
  bool _isOpen = false;
  late List<DropdownItem<dynamic>> _selected;
  final TextEditingController _searchController = TextEditingController();
  late DebouncedCallback _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedCallback(duration: widget.debounceDuration);
    _selected = List.from(widget.selectedItems);
    _items = List.from(widget.items);
    _cache = List.from(widget.items);
    if (widget.needInitialFetch && widget.onSearch != null) {
      widget.onSearch!('');
    }
  }

  @override
  void didUpdateWidget(MultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debounceDuration != widget.debounceDuration) {
      _debouncedSearch.dispose();
      _debouncedSearch = DebouncedCallback(duration: widget.debounceDuration);
    }
    if (oldWidget.selectedItems != widget.selectedItems) {
      setState(() => _selected = List.from(widget.selectedItems));
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
    if (online && widget.onSearch != null) {
      widget.onSearch!(value);
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
      if (widget.onSearch != null) {
        if (online) {
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

    return LayoutBuilder(
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
              showLoadingSpinner: widget.isLoading && widget.items.isEmpty,
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

    if (widget.isLoading) {
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
