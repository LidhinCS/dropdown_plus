import 'package:flutter/material.dart';

import 'dropdown_theme_resolver.dart';

class DropdownPanelShell extends StatelessWidget {
  const DropdownPanelShell({
    required this.resolved,
    required this.isOpen,
    required this.children,
    this.maxHeight,
    this.expandBody = false,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final bool isOpen;
  final List<Widget> children;
  final double? maxHeight;
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;
    final panelMax = maxHeight ?? t.menuMaxHeight;

    final columnChildren = expandBody && children.isNotEmpty
        ? [
            ...children.sublist(0, children.length - 1),
            Flexible(child: children.last),
          ]
        : children;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: isOpen
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Material(
                elevation: t.menuElevation,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(t.menuBorderRadius),
                color: t.menuBackgroundColor ?? Colors.white,
                child: Container(
                  constraints: BoxConstraints(maxHeight: panelMax),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.menuBorderRadius),
                    border: Border.all(
                      color: t.menuBorderColor ??
                          cs.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                        expandBody ? MainAxisSize.max : MainAxisSize.min,
                    children: columnChildren,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Conservative height for trigger + top gap so panel can stay within parent.
const double dropdownTriggerAndGapEstimate = 70.0;

/// Minimum panel height so the list area remains usable when space is tight.
const double dropdownMinPanelHeight = 120.0;

double resolveMultiSelectPanelMaxHeight(
  BoxConstraints constraints,
  double menuMaxHeight,
) =>
    constraints.hasBoundedHeight
        ? (constraints.maxHeight - dropdownTriggerAndGapEstimate)
            .clamp(dropdownMinPanelHeight, menuMaxHeight)
        : menuMaxHeight;
