import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dropdown_theme_resolver.dart';

/// Viewport cap for the open menu, supplied by the overlay host.
class DropdownMenuMetrics extends InheritedWidget {
  const DropdownMenuMetrics({
    required this.maxHeight,
    required super.child,
    super.key,
  });

  final double maxHeight;

  static DropdownMenuMetrics? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DropdownMenuMetrics>();
  }

  @override
  bool updateShouldNotify(DropdownMenuMetrics oldWidget) =>
      maxHeight != oldWidget.maxHeight;
}

class DropdownPanelShell extends StatelessWidget {
  const DropdownPanelShell({
    required this.resolved,
    required this.children,
    this.maxHeight,
    this.expandBody = false,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final List<Widget> children;
  final double? maxHeight;
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;
    final themeMax = maxHeight ?? t.menuMaxHeight;
    final overlayMax = DropdownMenuMetrics.maybeOf(context)?.maxHeight;
    final panelMax =
        overlayMax == null ? themeMax : math.min(themeMax, overlayMax);

    final columnChildren = expandBody && children.isNotEmpty
        ? [
            ...children.sublist(0, children.length - 1),
            Flexible(child: children.last),
          ]
        : children;

    // Border is painted inside the box; inset the child so header+list
    // never exceed [panelMax] by the 1px top/bottom stroke.
    const borderWidth = 1.0;
    final innerMax = math.max(0.0, panelMax - borderWidth * 2);

    return Material(
      elevation: t.menuElevation,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(t.menuBorderRadius),
      color: t.menuBackgroundColor ?? Colors.white,
      child: Container(
        constraints: BoxConstraints(maxHeight: panelMax),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.menuBorderRadius),
          border: Border.all(
            width: borderWidth,
            color: t.menuBorderColor ?? cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(t.menuBorderRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: innerMax),
            // Re-publish the inner budget so lists size to content without
            // overflowing the 1px top/bottom border.
            child: DropdownMenuMetrics(
              maxHeight: innerMax,
              child: Column(
                mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
                children: columnChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
