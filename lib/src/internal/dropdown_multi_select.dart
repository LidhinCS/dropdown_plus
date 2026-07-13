import 'package:flutter/material.dart';

import '../models/dropdown_item.dart';
import 'dropdown_pagination.dart';
import 'dropdown_theme_resolver.dart';

class DropdownMultiSelectHeader extends StatelessWidget {
  const DropdownMultiSelectHeader({
    required this.resolved,
    required this.itemCount,
    required this.selectedCount,
    required this.allSelected,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onClose,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final int itemCount;
  final int selectedCount;
  final bool allSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;
    final divCol = resolved.dividerColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.headerBackgroundColor ??
            cs.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: divCol)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (itemCount > 0)
            TextButton(
              onPressed: allSelected ? onClearAll : onSelectAll,
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
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              if (selectedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.selectedCountBackgroundColor ??
                        cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$selectedCount selected',
                    style: t.selectedCountTextStyle ??
                        TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                  ),
                ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Close dropdown',
                child: GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DropdownMultiSelectItemRow extends StatelessWidget {
  const DropdownMultiSelectItemRow({
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
    final activeCol = t.checkboxActiveColor ?? cs.primary;
    final inactiveCol =
        t.checkboxBorderColor ?? cs.outline.withValues(alpha: 0.4);

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
                      fontWeight: FontWeight.w600,
                    ))
                : (t.itemTextStyle ??
                    TextStyle(
                      fontSize: 14,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w400,
                    )),
          ),
        ),
      ],
    );
  }
}

class DropdownMultiSelectItemList extends StatefulWidget {
  const DropdownMultiSelectItemList({
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
  State<DropdownMultiSelectItemList> createState() =>
      _DropdownMultiSelectItemListState();
}

class _DropdownMultiSelectItemListState
    extends State<DropdownMultiSelectItemList> {
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
  void didUpdateWidget(DropdownMultiSelectItemList oldWidget) {
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

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
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
            if (i > 0) dropdownItemDivider(divCol, indent: 16),
            Semantics(
              button: true,
              checked: isSelected,
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
                          vertical: 14,
                        ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (t.selectedItemBackgroundColor ??
                              cs.primaryContainer.withValues(alpha: 0.3))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownMultiSelectItemRow(
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
    );
  }
}

class DropdownChipRow extends StatelessWidget {
  const DropdownChipRow({
    required this.resolved,
    required this.selected,
    required this.maxDisplayChips,
    required this.onRemove,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final List<DropdownItem<dynamic>> selected;
  final int maxDisplayChips;
  final void Function(DropdownItem<dynamic> item) onRemove;

  @override
  Widget build(BuildContext context) {
    final visible = selected.length <= maxDisplayChips
        ? selected
        : selected.take(maxDisplayChips).toList();
    final overflow = selected.length - maxDisplayChips;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map(
          (item) => _DropdownChip(
            resolved: resolved,
            label: item.label,
            onDelete: () => onRemove(item),
          ),
        ),
        if (overflow > 0)
          _DropdownChip(
            resolved: resolved,
            label: '+$overflow more',
            isCount: true,
          ),
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.resolved,
    required this.label,
    this.onDelete,
    this.isCount = false,
  });

  final DropdownResolvedTheme resolved;
  final String label;
  final VoidCallback? onDelete;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;

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
                        fontWeight: FontWeight.w500,
                      ))
                  : (t.chipTextStyle ??
                      TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      )),
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
                  color: (t.chipDeleteIconColor ?? cs.primary)
                      .withValues(alpha: 0.2),
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
}
