import 'package:flutter/material.dart';

import 'dropdown_plus_theme.dart';

/// Predefined visual styles for [SearchableDropdownPlus] and [MultiSelectDropdownPlus].
///
/// Pass [themeStyle] to either widget to get an out-of-the-box look without
/// building a custom [DropdownPlusTheme]. You can still override specific
/// properties via [dropdownTheme] after applying a preset.
///
/// ## Example
/// ```dart
/// MultiSelectDropdownPlus<MyCubit, MyState>(
///   themeStyle: DropdownPlusThemeStyle.minimal,
///   cubit: myCubit,
///   hintText: 'Select…',
///   onSearch: myCubit.search,
///   onStateChange: ...,
/// )
/// ```
enum DropdownPlusThemeStyle {
  /// Default Material-style look: white background, primary accents, standard radii.
  material,

  /// Light borders, subtle backgrounds, minimal visual weight.
  minimal,

  /// Large border radii and soft shadows for a rounded, card-like feel.
  rounded,

  /// Strong border, transparent or light fill; emphasis on the outline.
  outlined,

  /// Dark surfaces and light text for use in dark UIs or dark mode.
  dark,

  /// Tighter padding and smaller typography for dense layouts.
  compact,
}

/// Provides ready-made [DropdownPlusTheme] instances for each [DropdownPlusThemeStyle].
///
/// Use [forStyle] to resolve a theme from an enum value. Useful when you want
/// to apply a preset and then override a few properties:
///
/// ```dart
/// dropdownTheme: DropdownPlusThemePresets.forStyle(DropdownPlusThemeStyle.dark)
///   .copyWith(borderRadius: 16),
/// ```
class DropdownPlusThemePresets {
  DropdownPlusThemePresets._();

  static const Color _minimalBorder = Color(0xFFE0E0E0);
  static const Color _minimalActive = Color(0xFF616161);
  static const Color _outlinedBorder = Color(0xFF424242);
  static const Color _outlinedActive = Color(0xFF1976D2);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color _darkBorder = Color(0xFF424242);
  static const Color _darkAccent = Color(0xFF90CAF9);
  static const Color _darkOnSurface = Color(0xFFE0E0E0);
  static const Color _darkOnSurfaceMuted = Color(0xFF9E9E9E);

  /// Returns the [DropdownPlusTheme] for the given [style].
  static DropdownPlusTheme forStyle(DropdownPlusThemeStyle style) {
    switch (style) {
      case DropdownPlusThemeStyle.material:
        return const DropdownPlusTheme();
      case DropdownPlusThemeStyle.minimal:
        return const DropdownPlusTheme(
          backgroundColor: Colors.white,
          borderColor: _minimalBorder,
          activeBorderColor: _minimalActive,
          borderWidth: 1.0,
          activeBorderWidth: 1.0,
          borderRadius: 8.0,
          menuBackgroundColor: Colors.white,
          menuBorderRadius: 8.0,
          menuElevation: 4.0,
          menuBorderColor: _minimalBorder,
          searchBarBackgroundColor: Color(0xFFF5F5F5),
          searchBarBorderRadius: 8.0,
          dividerColor: Color(0xFFEEEEEE),
          chipBackgroundColor: Color(0xFFF5F5F5),
          chipBorderColor: _minimalBorder,
          chipBorderRadius: 12.0,
          headerBackgroundColor: Color(0xFFFAFAFA),
          selectedItemBackgroundColor: Color(0xFFF5F5F5),
          checkboxActiveColor: _minimalActive,
          checkboxBorderColor: _minimalBorder,
        );
      case DropdownPlusThemeStyle.rounded:
        return const DropdownPlusTheme(
          borderRadius: 16.0,
          menuBorderRadius: 16.0,
          searchBarBorderRadius: 14.0,
          chipBorderRadius: 20.0,
          menuElevation: 16.0,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          itemPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        );
      case DropdownPlusThemeStyle.outlined:
        return const DropdownPlusTheme(
          backgroundColor: Colors.transparent,
          borderColor: _outlinedBorder,
          activeBorderColor: _outlinedActive,
          borderWidth: 2.0,
          activeBorderWidth: 2.0,
          borderRadius: 8.0,
          menuBackgroundColor: Colors.white,
          menuBorderColor: _outlinedBorder,
          menuBorderRadius: 8.0,
          searchBarBackgroundColor: Color(0xFFFAFAFA),
          chipBackgroundColor: Color(0xFFE3F2FD),
          chipBorderColor: _outlinedActive,
          selectedItemBackgroundColor: Color(0xFFE3F2FD),
          checkboxActiveColor: _outlinedActive,
          checkboxBorderColor: _outlinedBorder,
        );
      case DropdownPlusThemeStyle.dark:
        return const DropdownPlusTheme(
          backgroundColor: _darkSurface,
          borderColor: _darkBorder,
          activeBorderColor: _darkAccent,
          menuBackgroundColor: _darkSurfaceVariant,
          menuBorderColor: _darkBorder,
          searchBarBackgroundColor: Color(0xFF383838),
          searchBarBorderRadius: 8.0,
          hintStyle: TextStyle(
            fontSize: 14,
            color: _darkOnSurfaceMuted,
            fontWeight: FontWeight.w400,
          ),
          searchHintStyle: TextStyle(fontSize: 14, color: _darkOnSurfaceMuted),
          searchTextStyle: TextStyle(fontSize: 14, color: _darkOnSurface),
          searchIconColor: _darkOnSurfaceMuted,
          triggerTextStyle: TextStyle(
            fontSize: 14,
            color: _darkOnSurface,
            fontWeight: FontWeight.w500,
          ),
          itemTextStyle: TextStyle(fontSize: 14, color: _darkOnSurface),
          selectedItemTextStyle: TextStyle(
            fontSize: 14,
            color: _darkAccent,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBackgroundColor: Color(0xFF37474F),
          dividerColor: Color(0xFF424242),
          chipBackgroundColor: Color(0xFF37474F),
          chipTextStyle: TextStyle(
            fontSize: 12,
            color: _darkAccent,
            fontWeight: FontWeight.w500,
          ),
          chipBorderColor: _darkAccent,
          chipDeleteIconColor: _darkAccent,
          headerBackgroundColor: Color(0xFF383838),
          selectAllTextStyle: TextStyle(
            fontSize: 13,
            color: _darkAccent,
            fontWeight: FontWeight.w600,
          ),
          selectedCountTextStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _darkAccent,
          ),
          selectedCountBackgroundColor: Color(0xFF37474F),
          checkboxActiveColor: _darkAccent,
          checkboxBorderColor: _darkOnSurfaceMuted,
          loadingIndicatorColor: _darkAccent,
          noResultsTextStyle: TextStyle(
            fontSize: 14,
            color: _darkOnSurfaceMuted,
            fontWeight: FontWeight.w500,
          ),
          noResultsIconColor: _darkOnSurfaceMuted,
          loadingTextStyle: TextStyle(fontSize: 13, color: _darkOnSurfaceMuted),
          arrowIconColor: _darkOnSurfaceMuted,
        );
      case DropdownPlusThemeStyle.compact:
        return const DropdownPlusTheme(
          borderRadius: 6.0,
          menuBorderRadius: 8.0,
          searchBarBorderRadius: 6.0,
          chipBorderRadius: 10.0,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          checkboxSize: 18.0,
          arrowIconSize: 18.0,
          chipDeleteIconSize: 12.0,
          hintStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        );
    }
  }
}
