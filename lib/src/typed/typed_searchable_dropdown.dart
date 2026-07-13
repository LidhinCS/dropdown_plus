import 'package:flutter/material.dart';

import '../internal/dropdown_states.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../widgets/searchable_dropdown.dart';
import 'typed_dropdown_adapter.dart';

/// Typed single-select searchable dropdown without BLoC/Cubit.
///
/// Opt-in API — import `package:dropdown_plus_bloc/typed.dart`.
class TypedSearchableDropdown<T> extends StatelessWidget {
  const TypedSearchableDropdown({
    required this.hintText,
    required this.items,
    required this.isLoading,
    required this.itemLabel,
    super.key,
    this.value,
    this.onChanged,
    this.itemEquals,
    this.onSearch,
    this.searchHint,
    this.noResultsText,
    this.loadingText,
    this.needInitialFetch = false,
    this.dropdownTheme,
    this.themeStyle,
    this.itemBuilder,
    this.valueBuilder,
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
  final T? value;
  final void Function(T? value)? onChanged;
  final ItemEquals<T>? itemEquals;
  final void Function(String query)? onSearch;
  final String? searchHint;
  final String? noResultsText;
  final String? loadingText;
  final bool needInitialFetch;
  final DropdownPlusTheme? dropdownTheme;
  final DropdownPlusThemeStyle? themeStyle;
  final TypedItemBuilder<T>? itemBuilder;
  final TypedValueBuilder<T>? valueBuilder;
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

    return SearchableDropdown(
      hintText: hintText,
      items: adapter.toItems(items),
      isLoading: isLoading,
      selectedValue: adapter.toOptionalItem(value),
      onSelectionChanged: (item) => onChanged?.call(adapter.asValue(item)),
      onSearch: onSearch,
      searchHint: searchHint,
      noResultsText: noResultsText,
      loadingText: loadingText,
      needInitialFetch: needInitialFetch,
      dropdownTheme: dropdownTheme,
      themeStyle: themeStyle,
      itemBuilder: itemBuilder == null
          ? null
          : (item, isSelected) =>
              itemBuilder!(context, adapter.asValue(item), isSelected),
      selectedValueBuilder: valueBuilder == null
          ? null
          : (item) => valueBuilder!(adapter.asValue(item)),
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
