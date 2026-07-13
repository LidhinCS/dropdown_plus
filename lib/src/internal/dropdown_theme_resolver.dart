import 'package:flutter/material.dart';

import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';

/// Resolved theme tokens used when building dropdown UI.
class DropdownResolvedTheme {
  const DropdownResolvedTheme({
    required this.theme,
    required this.colorScheme,
    required this.borderColor,
    required this.activeBorderColor,
    required this.dividerColor,
    required this.loadingColor,
    required this.noResultsIconColor,
  });

  final DropdownPlusTheme theme;
  final ColorScheme colorScheme;
  final Color borderColor;
  final Color activeBorderColor;
  final Color dividerColor;
  final Color loadingColor;
  final Color noResultsIconColor;

  Color arrowColor(bool isOpen) => isOpen
      ? activeBorderColor
      : (theme.arrowIconColor ??
          colorScheme.onSurface.withValues(alpha: 0.6));

  static DropdownResolvedTheme resolve(
    BuildContext context, {
    DropdownPlusTheme? dropdownTheme,
    DropdownPlusThemeStyle? themeStyle,
  }) {
    final theme = dropdownTheme ??
        (themeStyle != null
            ? DropdownPlusThemePresets.forStyle(themeStyle)
            : null) ??
        const DropdownPlusTheme();
    final cs = Theme.of(context).colorScheme;

    return DropdownResolvedTheme(
      theme: theme,
      colorScheme: cs,
      borderColor: theme.borderColor ?? cs.outline.withValues(alpha: 0.5),
      activeBorderColor: theme.activeBorderColor ?? cs.primary,
      dividerColor: theme.dividerColor ?? cs.outline.withValues(alpha: 0.08),
      loadingColor: theme.loadingIndicatorColor ?? cs.primary,
      noResultsIconColor:
          theme.noResultsIconColor ?? cs.onSurface.withValues(alpha: 0.4),
    );
  }
}
