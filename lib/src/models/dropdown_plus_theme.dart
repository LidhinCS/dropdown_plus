import 'package:flutter/material.dart';

/// Defines the visual theme for [SearchableDropdownPlus] and
/// [MultiSelectDropdownPlus] widgets.
///
/// All properties are optional. When `null`, sensible defaults derived from the
/// ambient [Theme] / [ColorScheme] are used automatically.
///
/// ## Example — dark theme override
/// ```dart
/// DropdownPlusTheme(
///   backgroundColor: Colors.grey[900],
///   menuBackgroundColor: Colors.grey[850],
///   borderColor: Colors.white24,
///   activeBorderColor: Colors.blueAccent,
///   hintStyle: TextStyle(color: Colors.white54),
///   itemTextStyle: TextStyle(color: Colors.white),
///   selectedItemTextStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
///   chipBackgroundColor: Colors.blueAccent.withOpacity(0.2),
///   chipTextStyle: TextStyle(color: Colors.blueAccent),
///   borderRadius: 8,
///   checkboxActiveColor: Colors.blueAccent,
/// )
/// ```
class DropdownPlusTheme {
  const DropdownPlusTheme({
    // --- Trigger button ---
    this.backgroundColor,
    this.borderColor,
    this.activeBorderColor,
    this.borderWidth = 1.0,
    this.activeBorderWidth = 1.5,
    this.borderRadius = 10.0,
    this.contentPadding,
    this.hintStyle,
    this.triggerTextStyle,

    // --- Dropdown menu panel ---
    this.menuBackgroundColor,
    this.menuBorderRadius = 12.0,
    this.menuElevation = 12.0,
    this.menuMaxHeight = 320.0,
    this.menuBorderColor,

    // --- Search bar ---
    this.searchBarBackgroundColor,
    this.searchBarBorderRadius = 10.0,
    this.searchHintStyle,
    this.searchTextStyle,
    this.searchIconColor,

    // --- Items ---
    this.itemTextStyle,
    this.selectedItemTextStyle,
    this.selectedItemBackgroundColor,
    this.itemPadding,
    this.dividerColor,

    // --- Multi-select checkbox ---
    this.checkboxBorderColor,
    this.checkboxActiveColor,
    this.checkboxSize = 22.0,

    // --- Chips (multi-select display) ---
    this.chipBackgroundColor,
    this.chipTextStyle,
    this.chipBorderColor,
    this.chipBorderRadius = 16.0,
    this.chipDeleteIconColor,
    this.chipDeleteIconSize = 14.0,
    this.countChipBackgroundColor,
    this.countChipTextStyle,

    // --- Loading / empty states ---
    this.loadingIndicatorColor,
    this.loadingTextStyle,
    this.noResultsTextStyle,
    this.noResultsIconColor,

    // --- Dropdown arrow icon ---
    this.arrowIconColor,
    this.arrowIconSize = 22.0,

    // --- Multi-select header bar ---
    this.headerBackgroundColor,
    this.selectAllTextStyle,
    this.selectedCountTextStyle,
    this.selectedCountBackgroundColor,
  });

  // ── Trigger button ────────────────────────────────────────────────────────
  /// Background color of the dropdown trigger button. Defaults to white.
  final Color? backgroundColor;

  /// Border color when the dropdown is closed.
  final Color? borderColor;

  /// Border color when the dropdown is open / focused.
  final Color? activeBorderColor;

  /// Border width when the dropdown is closed. Default: `1.0`.
  final double borderWidth;

  /// Border width when the dropdown is open. Default: `1.5`.
  final double activeBorderWidth;

  /// Corner radius for the trigger button. Default: `10.0`.
  final double borderRadius;

  /// Padding inside the trigger button. Defaults to `EdgeInsets.symmetric(horizontal: 14, vertical: 12)`.
  final EdgeInsets? contentPadding;

  /// Style of the hint / placeholder text.
  final TextStyle? hintStyle;

  /// Style of the selected value text shown in the trigger (single-select).
  final TextStyle? triggerTextStyle;

  // ── Dropdown menu panel ───────────────────────────────────────────────────
  /// Background color of the floating menu panel. Defaults to white.
  final Color? menuBackgroundColor;

  /// Corner radius of the floating menu panel. Default: `12.0`.
  final double menuBorderRadius;

  /// Elevation of the floating menu panel. Default: `12.0`.
  final double menuElevation;

  /// Maximum height of the floating menu panel. Default: `320.0`.
  final double menuMaxHeight;

  /// Border color of the floating menu panel.
  final Color? menuBorderColor;

  // ── Search bar ────────────────────────────────────────────────────────────
  /// Background color of the search input container.
  final Color? searchBarBackgroundColor;

  /// Corner radius of the search input container. Default: `10.0`.
  final double searchBarBorderRadius;

  /// Hint/placeholder style for the search input.
  final TextStyle? searchHintStyle;

  /// Style for text typed in the search input.
  final TextStyle? searchTextStyle;

  /// Color of the leading search icon.
  final Color? searchIconColor;

  // ── Items ─────────────────────────────────────────────────────────────────
  /// Text style for non-selected items in the list.
  final TextStyle? itemTextStyle;

  /// Text style for the currently selected item(s).
  final TextStyle? selectedItemTextStyle;

  /// Background color applied to selected item rows.
  final Color? selectedItemBackgroundColor;

  /// Padding for each item row. Defaults to `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
  final EdgeInsets? itemPadding;

  /// Color of the thin divider lines between items.
  final Color? dividerColor;

  // ── Multi-select checkbox ─────────────────────────────────────────────────
  /// Border color of the circular checkbox when unselected.
  final Color? checkboxBorderColor;

  /// Fill / border color of the circular checkbox when selected.
  final Color? checkboxActiveColor;

  /// Diameter of the circular checkbox. Default: `22.0`.
  final double checkboxSize;

  // ── Chips ─────────────────────────────────────────────────────────────────
  /// Background color of the selected-item chips.
  final Color? chipBackgroundColor;

  /// Text style inside the selected-item chips.
  final TextStyle? chipTextStyle;

  /// Border color of the selected-item chips.
  final Color? chipBorderColor;

  /// Corner radius of the chips. Default: `16.0`.
  final double chipBorderRadius;

  /// Color of the delete (×) icon on each chip.
  final Color? chipDeleteIconColor;

  /// Size of the delete (×) icon. Default: `14.0`.
  final double chipDeleteIconSize;

  /// Background color of the "+N more" overflow chip.
  final Color? countChipBackgroundColor;

  /// Text style of the "+N more" overflow chip.
  final TextStyle? countChipTextStyle;

  // ── Loading / empty states ────────────────────────────────────────────────
  /// Color of the circular progress indicator shown while loading.
  final Color? loadingIndicatorColor;

  /// Text style of the optional loading message.
  final TextStyle? loadingTextStyle;

  /// Text style of the "no results" message.
  final TextStyle? noResultsTextStyle;

  /// Color of the "no results" icon.
  final Color? noResultsIconColor;

  // ── Arrow icon ────────────────────────────────────────────────────────────
  /// Color of the animated caret / arrow icon in the trigger button.
  final Color? arrowIconColor;

  /// Size of the arrow icon. Default: `22.0`.
  final double arrowIconSize;

  // ── Multi-select header bar ───────────────────────────────────────────────
  /// Background color of the "Select All / Clear" header row.
  final Color? headerBackgroundColor;

  /// Text style of the "Select All" / "Clear All" button.
  final TextStyle? selectAllTextStyle;

  /// Text style of the "N selected" badge.
  final TextStyle? selectedCountTextStyle;

  /// Background color of the "N selected" badge pill.
  final Color? selectedCountBackgroundColor;

  /// Returns a copy of this theme with the given fields replaced.
  DropdownPlusTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? activeBorderColor,
    double? borderWidth,
    double? activeBorderWidth,
    double? borderRadius,
    EdgeInsets? contentPadding,
    TextStyle? hintStyle,
    TextStyle? triggerTextStyle,
    Color? menuBackgroundColor,
    double? menuBorderRadius,
    double? menuElevation,
    double? menuMaxHeight,
    Color? menuBorderColor,
    Color? searchBarBackgroundColor,
    double? searchBarBorderRadius,
    TextStyle? searchHintStyle,
    TextStyle? searchTextStyle,
    Color? searchIconColor,
    TextStyle? itemTextStyle,
    TextStyle? selectedItemTextStyle,
    Color? selectedItemBackgroundColor,
    EdgeInsets? itemPadding,
    Color? dividerColor,
    Color? checkboxBorderColor,
    Color? checkboxActiveColor,
    double? checkboxSize,
    Color? chipBackgroundColor,
    TextStyle? chipTextStyle,
    Color? chipBorderColor,
    double? chipBorderRadius,
    Color? chipDeleteIconColor,
    double? chipDeleteIconSize,
    Color? countChipBackgroundColor,
    TextStyle? countChipTextStyle,
    Color? loadingIndicatorColor,
    TextStyle? loadingTextStyle,
    TextStyle? noResultsTextStyle,
    Color? noResultsIconColor,
    Color? arrowIconColor,
    double? arrowIconSize,
    Color? headerBackgroundColor,
    TextStyle? selectAllTextStyle,
    TextStyle? selectedCountTextStyle,
    Color? selectedCountBackgroundColor,
  }) {
    return DropdownPlusTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      activeBorderColor: activeBorderColor ?? this.activeBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      activeBorderWidth: activeBorderWidth ?? this.activeBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      hintStyle: hintStyle ?? this.hintStyle,
      triggerTextStyle: triggerTextStyle ?? this.triggerTextStyle,
      menuBackgroundColor: menuBackgroundColor ?? this.menuBackgroundColor,
      menuBorderRadius: menuBorderRadius ?? this.menuBorderRadius,
      menuElevation: menuElevation ?? this.menuElevation,
      menuMaxHeight: menuMaxHeight ?? this.menuMaxHeight,
      menuBorderColor: menuBorderColor ?? this.menuBorderColor,
      searchBarBackgroundColor:
          searchBarBackgroundColor ?? this.searchBarBackgroundColor,
      searchBarBorderRadius:
          searchBarBorderRadius ?? this.searchBarBorderRadius,
      searchHintStyle: searchHintStyle ?? this.searchHintStyle,
      searchTextStyle: searchTextStyle ?? this.searchTextStyle,
      searchIconColor: searchIconColor ?? this.searchIconColor,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      selectedItemTextStyle:
          selectedItemTextStyle ?? this.selectedItemTextStyle,
      selectedItemBackgroundColor:
          selectedItemBackgroundColor ?? this.selectedItemBackgroundColor,
      itemPadding: itemPadding ?? this.itemPadding,
      dividerColor: dividerColor ?? this.dividerColor,
      checkboxBorderColor: checkboxBorderColor ?? this.checkboxBorderColor,
      checkboxActiveColor: checkboxActiveColor ?? this.checkboxActiveColor,
      checkboxSize: checkboxSize ?? this.checkboxSize,
      chipBackgroundColor: chipBackgroundColor ?? this.chipBackgroundColor,
      chipTextStyle: chipTextStyle ?? this.chipTextStyle,
      chipBorderColor: chipBorderColor ?? this.chipBorderColor,
      chipBorderRadius: chipBorderRadius ?? this.chipBorderRadius,
      chipDeleteIconColor: chipDeleteIconColor ?? this.chipDeleteIconColor,
      chipDeleteIconSize: chipDeleteIconSize ?? this.chipDeleteIconSize,
      countChipBackgroundColor:
          countChipBackgroundColor ?? this.countChipBackgroundColor,
      countChipTextStyle: countChipTextStyle ?? this.countChipTextStyle,
      loadingIndicatorColor:
          loadingIndicatorColor ?? this.loadingIndicatorColor,
      loadingTextStyle: loadingTextStyle ?? this.loadingTextStyle,
      noResultsTextStyle: noResultsTextStyle ?? this.noResultsTextStyle,
      noResultsIconColor: noResultsIconColor ?? this.noResultsIconColor,
      arrowIconColor: arrowIconColor ?? this.arrowIconColor,
      arrowIconSize: arrowIconSize ?? this.arrowIconSize,
      headerBackgroundColor:
          headerBackgroundColor ?? this.headerBackgroundColor,
      selectAllTextStyle: selectAllTextStyle ?? this.selectAllTextStyle,
      selectedCountTextStyle:
          selectedCountTextStyle ?? this.selectedCountTextStyle,
      selectedCountBackgroundColor:
          selectedCountBackgroundColor ?? this.selectedCountBackgroundColor,
    );
  }
}
