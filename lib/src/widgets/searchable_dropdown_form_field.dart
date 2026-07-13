import 'package:flutter/material.dart';

import '../internal/dropdown_form_field.dart';
import '../internal/dropdown_states.dart';
import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import 'searchable_dropdown.dart';

/// [FormField] wrapper for [SearchableDropdown].
///
/// Integrates with [Form], [validator], [onSaved], and [autovalidateMode].
class SearchableDropdownFormField extends FormField<DropdownItem<dynamic>?> {
  SearchableDropdownFormField({
    required String hintText,
    required List<DropdownItem<dynamic>> items,
    required bool isLoading,
    super.key,
    DropdownItem<dynamic>? initialValue,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
    void Function(String query)? onSearch,
    String? searchHint,
    String? noResultsText,
    String? loadingText,
    bool needInitialFetch = false,
    DropdownPlusTheme? dropdownTheme,
    DropdownPlusThemeStyle? themeStyle,
    Widget Function(DropdownItem<dynamic> item, bool isSelected)? itemBuilder,
    Widget Function(DropdownItem<dynamic> selectedItem)? selectedValueBuilder,
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
              dropdown: SearchableDropdown(
                hintText: hintText,
                items: items,
                isLoading: isLoading,
                selectedValue: state.value,
                onSelectionChanged: (item) => state.didChange(item),
                onSearch: onSearch,
                searchHint: searchHint,
                noResultsText: noResultsText,
                loadingText: loadingText,
                needInitialFetch: needInitialFetch,
                dropdownTheme: dropdownTheme,
                themeStyle: themeStyle,
                itemBuilder: itemBuilder,
                selectedValueBuilder: selectedValueBuilder,
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
