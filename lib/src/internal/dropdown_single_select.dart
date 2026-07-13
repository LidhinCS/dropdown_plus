import 'package:flutter/material.dart';

import '../models/dropdown_item.dart';
import '../utils/debounced_callback.dart' show dropdownListMaxHeight;
import 'dropdown_pagination.dart';
import 'dropdown_theme_resolver.dart';

class DropdownSingleSelectItemRow extends StatelessWidget {
  const DropdownSingleSelectItemRow({
    required this.resolved,
    required this.item,
    required this.isSelected,
    this.itemBuilder,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final DropdownItem<dynamic> item;
  final bool isSelected;
  final Widget Function(DropdownItem<dynamic> item, bool isSelected)?
      itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) {
      return itemBuilder!(item, isSelected);
    }

    final t = resolved.theme;
    final cs = resolved.colorScheme;

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
                      fontWeight: FontWeight.w500,
                    ))
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

class DropdownSingleSelectItemList extends StatefulWidget {
  const DropdownSingleSelectItemList({
    required this.resolved,
    required this.items,
    required this.isItemSelected,
    required this.onItemTap,
    this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final List<DropdownItem<dynamic>> items;
  final bool Function(DropdownItem<dynamic> item) isItemSelected;
  final void Function(DropdownItem<dynamic> item) onItemTap;
  final Widget Function(DropdownItem<dynamic> item, bool isSelected)?
      itemBuilder;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  State<DropdownSingleSelectItemList> createState() =>
      _DropdownSingleSelectItemListState();
}

class _DropdownSingleSelectItemListState
    extends State<DropdownSingleSelectItemList> {
  late final DropdownPaginationScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = DropdownPaginationScrollController(
      onLoadMore: widget.onLoadMore,
      hasMore: widget.hasMore,
      isLoadingMore: widget.isLoadingMore,
    );
  }

  @override
  void didUpdateWidget(DropdownSingleSelectItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollController.hasMore = widget.hasMore;
    _scrollController.isLoadingMore = widget.isLoadingMore;
    _scrollController.onLoadMore = widget.onLoadMore;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.resolved.theme;
    final cs = widget.resolved.colorScheme;
    final divCol = widget.resolved.dividerColor;
    final showFooter = widget.isLoadingMore;
    final maxH = dropdownListMaxHeight(t.menuMaxHeight);
    const estimatedRowHeight = 49.0;
    final contentHeight = widget.items.length * estimatedRowHeight +
        (showFooter ? 52.0 : 0.0);
    final listHeight = contentHeight.clamp(0.0, maxH);

    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: widget.items.length + (showFooter ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= widget.items.length) {
            return DropdownLoadMoreFooter(isLoading: widget.isLoadingMore);
          }

          final item = widget.items[i];
          final isSelected = widget.isItemSelected(item);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0) dropdownItemDivider(divCol),
              Semantics(
                button: true,
                selected: isSelected,
                label: item.label,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onItemTap(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: t.itemPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (t.selectedItemBackgroundColor ??
                                cs.primaryContainer.withValues(alpha: 0.3))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownSingleSelectItemRow(
                        resolved: widget.resolved,
                        item: item,
                        isSelected: isSelected,
                        itemBuilder: widget.itemBuilder,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}