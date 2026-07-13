import 'package:flutter/material.dart';

import '../internal/dropdown_form_field.dart';
import '../internal/dropdown_states.dart';
import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import 'multi_select_dropdown.dart';

/// [FormField] wrapper for [MultiSelectDropdown].
///
/// Integrates with [Form], [validator], [onSaved], and [autovalidateMode].
class MultiSelectDropdownFormField
    extends FormField<List<DropdownItem<dynamic>>> {
  MultiSelectDropdownFormField({
    required String hintText,
    required List<DropdownItem<dynamic>> items,
    required bool isLoading,
    super.key,
    List<DropdownItem<dynamic>> initialValue = const [],
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
    void Function(String query)? onSearch,
    String? searchHint,
    String? noResultsText,
    String? loadingText,
    bool needInitialFetch = false,
    int maxDisplayChips = 2,
    DropdownPlusTheme? dropdownTheme,
    DropdownPlusThemeStyle? themeStyle,
    Widget Function(DropdownItem<dynamic> item, bool isSelected)? itemBuilder,
    Widget Function(List<DropdownItem<dynamic>> selected)? selectedItemBuilder,
    double? buttonHeight,
    double? buttonWidth,
    Future<bool> Function()? checkInternetConnection,
    Duration debounceDuration = Duration.zero,
    bool autofocusSearch = false,
    DropdownEmptyBuilder? emptyBuilder,
    DropdownLoadingBuilder? loadingBuilder,
    Object? error,
    VoidCallback? onRetry,
    DropdownErrorBuilder? errorBuilder,
    String? semanticsLabel,
    int minSearchLength = 0,
  }) : super(
          initialValue: initialValue,
          builder: (state) {
            return dropdownFormFieldDecoration(
              state: state,
              dropdown: MultiSelectDropdown(
                hintText: hintText,
                items: items,
                isLoading: isLoading,
                selectedItems: state.value ?? const [],
                onSelectionChanged: (items) => state.didChange(items),
                onSearch: onSearch,
                searchHint: searchHint,
                noResultsText: noResultsText,
                loadingText: loadingText,
                needInitialFetch: needInitialFetch,
                maxDisplayChips: maxDisplayChips,
                dropdownTheme: dropdownTheme,
                themeStyle: themeStyle,
                itemBuilder: itemBuilder,
                selectedItemBuilder: selectedItemBuilder,
                buttonHeight: buttonHeight,
                buttonWidth: buttonWidth,
                checkInternetConnection: checkInternetConnection,
                debounceDuration: debounceDuration,
                enabled: enabled,
                autofocusSearch: autofocusSearch,
                emptyBuilder: emptyBuilder,
                loadingBuilder: loadingBuilder,
                error: error,
                onRetry: onRetry,
                errorBuilder: errorBuilder,
                semanticsLabel: semanticsLabel,
                minSearchLength: minSearchLength,
              ),
            );
          },
        );
}
