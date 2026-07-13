import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../internal/dropdown_form_field.dart';
import '../internal/dropdown_states.dart';
import '../models/dropdown_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import 'multi_select_dropdown_plus.dart';

/// [FormField] wrapper for [MultiSelectDropdownPlus].
///
/// Integrates with [Form], [validator], [onSaved], and [autovalidateMode].
class MultiSelectDropdownPlusFormField<C extends BlocBase<S>, S>
    extends FormField<List<DropdownItem<dynamic>>> {
  MultiSelectDropdownPlusFormField({
    required C cubit,
    required void Function(String query) onSearch,
    required void Function(
      S state,
      void Function(List<DropdownItem<dynamic>>) updateList,
      void Function(bool) updateLoading,
    ) onStateChange,
    required String hintText,
    super.key,
    List<DropdownItem<dynamic>> initialValue = const [],
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
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
              dropdown: MultiSelectDropdownPlus<C, S>(
                cubit: cubit,
                onSearch: onSearch,
                onStateChange: onStateChange,
                hintText: hintText,
                selectedItems: state.value ?? const [],
                onSelectionChanged: (items) => state.didChange(items),
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
