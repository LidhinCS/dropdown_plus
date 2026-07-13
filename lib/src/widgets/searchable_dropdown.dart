import 'package:flutter/material.dart';

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

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
  bool _isOpen = false;
  DropdownItem<dynamic>? _selected;
  final TextEditingController _searchController = TextEditingController();
  late DebouncedCallback _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedCallback(duration: widget.debounceDuration);
    _selected = widget.selectedValue;
    _items = List.from(widget.items);
    _cache = List.from(widget.items);
    if (widget.needInitialFetch && widget.onSearch != null) {
      widget.onSearch!('');
    }
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    if (oldWidget.items != widget.items || oldWidget.isLoading != widget.isLoading) {
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

  @override
  Widget build(BuildContext context) {
    final t = widget.dropdownTheme ??
        (widget.themeStyle != null
            ? DropdownPlusThemePresets.forStyle(widget.themeStyle!)
            : null) ??
        const DropdownPlusTheme();
    final cs = Theme.of(context).colorScheme;

    final borderCol = t.borderColor ?? cs.outline.withValues(alpha: 0.5);
    final activeBorderCol = t.activeBorderColor ?? cs.primary;
    final divCol = t.dividerColor ?? cs.outline.withValues(alpha: 0.08);
    final loadCol = t.loadingIndicatorColor ?? cs.primary;
    final noResIconCol =
        t.noResultsIconColor ?? cs.onSurface.withValues(alpha: 0.4);
    final arrowCol = _isOpen
        ? activeBorderCol
        : (t.arrowIconColor ?? cs.onSurface.withValues(alpha: 0.6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTrigger(t, cs, borderCol, activeBorderCol, loadCol, arrowCol),
        _buildPanel(t, cs, divCol, loadCol, noResIconCol),
      ],
    );
  }

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
                    color: activeBorderCol.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(child: _buildTriggerContent(t, cs)),
            if (widget.isLoading && widget.items.isEmpty) ...[
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
                color: cs.onSurface.withValues(alpha: 0.6),
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
                shadowColor: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(t.menuBorderRadius),
                color: t.menuBackgroundColor ?? Colors.white,
                child: Container(
                  constraints: BoxConstraints(maxHeight: t.menuMaxHeight),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.menuBorderRadius),
                    border: Border.all(
                      color: t.menuBorderColor ??
                          cs.outline.withValues(alpha: 0.2),
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
              cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(t.searchBarBorderRadius),
        ),
        child: TextField(
          controller: _searchController,
          style: t.searchTextStyle,
          decoration: InputDecoration(
            hintText: widget.searchHint ?? 'Search…',
            hintStyle: t.searchHintStyle ??
                TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20,
                color: t.searchIconColor ?? cs.onSurface.withValues(alpha: 0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) {
            _debouncedSearch(() async {
              final online = await _hasInternet();
              if (!mounted) return;
              if (online && widget.onSearch != null) {
                widget.onSearch!(value);
              } else {
                _localSearch(value);
              }
            });
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
        constraints:
            BoxConstraints(maxHeight: dropdownListMaxHeight(t.menuMaxHeight)),
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
                            cs.primaryContainer.withValues(alpha: 0.3))
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

    if (widget.isLoading) {
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
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.6)),
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
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6)),
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
