import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../internal/dropdown_states.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../widgets/searchable_dropdown_plus.dart';
import 'typed_dropdown_adapter.dart';

/// Typed single-select searchable dropdown with BLoC/Cubit integration.
///
/// Opt-in API — import `package:dropdown_plus_bloc/typed.dart`.
///
/// Works with [User] (or any [T]) directly instead of [DropdownItem].
class TypedSearchableDropdownPlus<T, C extends BlocBase<S>, S>
    extends StatelessWidget {
  const TypedSearchableDropdownPlus({
    required this.cubit,
    required this.onSearch,
    required this.onStateChange,
    required this.hintText,
    required this.itemLabel,
    super.key,
    this.value,
    this.onChanged,
    this.itemEquals,
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
  });

  final C cubit;
  final void Function(String query) onSearch;
  final void Function(
    S state,
    void Function(List<T> items) updateItems,
    void Function(bool) updateLoading,
  ) onStateChange;
  final String hintText;
  final ItemLabel<T> itemLabel;
  final T? value;
  final void Function(T? value)? onChanged;
  final ItemEquals<T>? itemEquals;
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

  @override
  Widget build(BuildContext context) {
    final adapter = TypedDropdownAdapter<T>(
      itemLabel: itemLabel,
      itemEquals: itemEquals,
    );

    return SearchableDropdownPlus<C, S>(
      cubit: cubit,
      onSearch: onSearch,
      hintText: hintText,
      selectedValue: adapter.toOptionalItem(value),
      onSelectionChanged: (item) => onChanged?.call(adapter.asValue(item)),
      onStateChange: (state, updateList, updateLoading) {
        onStateChange(
          state,
          (items) => updateList(adapter.toItems(items)),
          updateLoading,
        );
      },
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
    );
  }
}
