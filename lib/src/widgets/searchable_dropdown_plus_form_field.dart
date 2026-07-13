import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../internal/dropdown_form_field.dart';
import '../internal/dropdown_states.dart';
import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import 'searchable_dropdown_plus.dart';

/// [FormField] wrapper for [SearchableDropdownPlus].
///
/// Integrates with [Form], [validator], [onSaved], and [autovalidateMode].
class SearchableDropdownPlusFormField<C extends BlocBase<S>, S>
    extends FormField<DropdownItem<dynamic>?> {
  SearchableDropdownPlusFormField({
    required C cubit,
    required void Function(String query) onSearch,
    required void Function(
      S state,
      void Function(List<DropdownItem<dynamic>>) updateList,
      void Function(bool) updateLoading,
    ) onStateChange,
    required String hintText,
    super.key,
    DropdownItem<dynamic>? initialValue,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
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
              dropdown: SearchableDropdownPlus<C, S>(
                cubit: cubit,
                onSearch: onSearch,
                onStateChange: onStateChange,
                hintText: hintText,
                selectedValue: state.value,
                onSelectionChanged: (item) => state.didChange(item),
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
