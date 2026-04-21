import 'package:flutter/material.dart';

import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';

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

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

const double _triggerAndGapEstimate = 70.0;
const double _minPanelHeight = 120.0;

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  List<DropdownItem<dynamic>> _items = [];
  List<DropdownItem<dynamic>> _cache = [];
  bool _isOpen = false;
  late List<DropdownItem<dynamic>> _selected;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    if (oldWidget.selectedItems != widget.selectedItems) {
      setState(() => _selected = List.from(widget.selectedItems));
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
    final divCol = t.dividerColor ?? cs.outline.withValues(alpha: 0.1);
    final loadCol = t.loadingIndicatorColor ?? cs.primary;
    final arrowCol = _isOpen
        ? activeBorderCol
        : (t.arrowIconColor ?? cs.onSurface.withValues(alpha: 0.6));

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelMax = constraints.hasBoundedHeight
            ? (constraints.maxHeight - _triggerAndGapEstimate)
                .clamp(_minPanelHeight, t.menuMaxHeight)
            : t.menuMaxHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTrigger(t, cs, borderCol, activeBorderCol, loadCol, arrowCol),
            _buildPanel(t, cs, divCol, loadCol, panelMax),
          ],
        );
      },
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
        if (opening && _items.isEmpty) {
          final online = await _hasInternet();
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
            const SizedBox(width: 8),
            if (widget.isLoading && widget.items.isEmpty) ...[
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
                color: cs.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400),
      );
    }
    return widget.selectedItemBuilder?.call(_selected) ?? _buildChipRow(t, cs);
  }

  Widget _buildPanel(
    DropdownPlusTheme t,
    ColorScheme cs,
    Color divCol,
    Color loadCol,
    double panelMaxHeight,
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
                  constraints: BoxConstraints(maxHeight: panelMaxHeight),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.menuBorderRadius),
                    border: Border.all(
                      color: t.menuBorderColor ??
                          cs.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
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
          onChanged: (value) async {
            final online = await _hasInternet();
            if (online && widget.onSearch != null) {
              widget.onSearch!(value);
            } else {
              _localSearch(value);
            }
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
            cs.surfaceContainerHighest.withValues(alpha: 0.3),
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
                        cs.primary.withValues(alpha: 0.1),
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
                    size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
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
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading) ...[
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
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.6))),
            ],
          ] else ...[
            Icon(Icons.search_off_rounded,
                size: 48,
                color: t.noResultsIconColor ?? cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              widget.noResultsText ?? 'No items found',
              style: t.noResultsTextStyle ??
                  TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

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
            : (t.chipBackgroundColor ?? cs.primary.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(t.chipBorderRadius),
        border: Border.all(
          color: isCount
              ? (t.chipBorderColor ?? cs.outline.withValues(alpha: 0.3))
              : (t.chipBorderColor ?? cs.primary.withValues(alpha: 0.3)),
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
                          color: cs.onSurface.withValues(alpha: 0.7),
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
                  color: (t.chipDeleteIconColor ?? cs.primary).withValues(alpha: 0.2),
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

  Widget _defaultRow(
    DropdownPlusTheme t,
    ColorScheme cs,
    DropdownItem<dynamic> item,
    bool isSelected,
  ) {
    final activeCol = t.checkboxActiveColor ?? cs.primary;
    final inactiveCol = t.checkboxBorderColor ?? cs.outline.withValues(alpha: 0.4);

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
