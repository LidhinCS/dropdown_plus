import 'package:flutter/material.dart';

import '../models/dropdown_item.dart';
import '../utils/debounced_callback.dart' show dropdownListMaxHeight;
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

class DropdownSingleSelectItemList extends StatelessWidget {
  const DropdownSingleSelectItemList({
    required this.resolved,
    required this.items,
    required this.isItemSelected,
    required this.onItemTap,
    this.itemBuilder,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final List<DropdownItem<dynamic>> items;
  final bool Function(DropdownItem<dynamic> item) isItemSelected;
  final void Function(DropdownItem<dynamic> item) onItemTap;
  final Widget Function(DropdownItem<dynamic> item, bool isSelected)?
      itemBuilder;

  @override
  Widget build(BuildContext context) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;
    final divCol = resolved.dividerColor;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: dropdownListMaxHeight(t.menuMaxHeight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          indent: 12,
          endIndent: 12,
          color: divCol,
        ),
        itemBuilder: (ctx, i) {
          final item = items[i];
          final isSelected = isItemSelected(item);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onItemTap(item),
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
                child: DropdownSingleSelectItemRow(
                  resolved: resolved,
                  item: item,
                  isSelected: isSelected,
                  itemBuilder: itemBuilder,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
