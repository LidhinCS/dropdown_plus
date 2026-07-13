import 'package:flutter/material.dart';

import '../internal/dropdown_states.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../widgets/multi_select_dropdown.dart';
import 'typed_dropdown_adapter.dart';

/// Typed multi-select searchable dropdown without BLoC/Cubit.
///
/// Opt-in API — import `package:dropdown_plus_bloc/typed.dart`.
class TypedMultiSelectDropdown<T> extends StatelessWidget {
  const TypedMultiSelectDropdown({
    required this.hintText,
    required this.items,
    required this.isLoading,
    required this.itemLabel,
    super.key,
    this.values = const [],
    this.onChanged,
    this.itemEquals,
    this.onSearch,
    this.searchHint,
    this.noResultsText,
    this.loadingText,
    this.needInitialFetch = false,
    this.maxDisplayChips = 2,
    this.dropdownTheme,
    this.themeStyle,
    this.itemBuilder,
    this.valuesBuilder,
    this.buttonHeight,
    this.buttonWidth,
    this.checkInternetConnection,
    this.debounceDuration = Duration.zero,
    this.enabled = true,
    this.autofocusSearch = false,
    this.emptyBuilder,
    this.loadingBuilder,
    this.error,
    this.onRetry,
    this.errorBuilder,
    this.semanticsLabel,
    this.minSearchLength = 0,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.focusNode,
  });

  final String hintText;
  final List<T> items;
  final bool isLoading;
  final ItemLabel<T> itemLabel;
  final List<T> values;
  final void Function(List<T> values)? onChanged;
  final ItemEquals<T>? itemEquals;
  final void Function(String query)? onSearch;
  final String? searchHint;
  final String? noResultsText;
  final String? loadingText;
  final bool needInitialFetch;
  final int maxDisplayChips;
  final DropdownPlusTheme? dropdownTheme;
  final DropdownPlusThemeStyle? themeStyle;
  final TypedItemBuilder<T>? itemBuilder;
  final TypedValuesBuilder<T>? valuesBuilder;
  final double? buttonHeight;
  final double? buttonWidth;
  final Future<bool> Function()? checkInternetConnection;
  final Duration debounceDuration;
  final bool enabled;
  final bool autofocusSearch;
  final DropdownEmptyBuilder? emptyBuilder;
  final DropdownLoadingBuilder? loadingBuilder;
  final Object? error;
  final VoidCallback? onRetry;
  final DropdownErrorBuilder? errorBuilder;
  final String? semanticsLabel;
  final int minSearchLength;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final adapter = TypedDropdownAdapter<T>(
      itemLabel: itemLabel,
      itemEquals: itemEquals,
    );

    return MultiSelectDropdown(
      hintText: hintText,
      items: adapter.toItems(items),
      isLoading: isLoading,
      selectedItems: adapter.toItems(values),
      onSelectionChanged: (items) => onChanged?.call(adapter.asValues(items)),
      onSearch: onSearch,
      searchHint: searchHint,
      noResultsText: noResultsText,
      loadingText: loadingText,
      needInitialFetch: needInitialFetch,
      maxDisplayChips: maxDisplayChips,
      dropdownTheme: dropdownTheme,
      themeStyle: themeStyle,
      itemBuilder: itemBuilder == null
          ? null
          : (item, isSelected) =>
              itemBuilder!(context, adapter.asValue(item), isSelected),
      selectedItemBuilder: valuesBuilder == null
          ? null
          : (items) => valuesBuilder!(adapter.asValues(items)),
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
      onLoadMore: onLoadMore,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      focusNode: focusNode,
    );
  }
}
