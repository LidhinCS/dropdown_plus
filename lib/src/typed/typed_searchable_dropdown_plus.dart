import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../internal/dropdown_states.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../widgets/searchable_dropdown_plus.dart';
import 'dropdown_plus_controller.dart';
import 'typed_dropdown_adapter.dart';

/// Typed single-select searchable dropdown with BLoC/Cubit integration.
///
/// Opt-in API — import `package:dropdown_plus_bloc/typed.dart`.
///
/// Works with [User] (or any [T]) directly instead of [DropdownItem].
class TypedSearchableDropdownPlus<T, C extends BlocBase<S>, S>
    extends StatefulWidget {
  const TypedSearchableDropdownPlus({
    required this.cubit,
    required this.onSearch,
    required this.onStateChange,
    required this.hintText,
    required this.itemLabel,
    super.key,
    this.value,
    this.onChanged,
    this.controller,
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
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.focusNode,
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

  /// When set, owns selection; [value] is only an initial seed.
  final DropdownPlusController<T>? controller;
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
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final FocusNode? focusNode;

  @override
  State<TypedSearchableDropdownPlus<T, C, S>> createState() =>
      _TypedSearchableDropdownPlusState<T, C, S>();
}

class _TypedSearchableDropdownPlusState<T, C extends BlocBase<S>, S>
    extends State<TypedSearchableDropdownPlus<T, C, S>> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
    _maybeSeed();
  }

  @override
  void didUpdateWidget(TypedSearchableDropdownPlus<T, C, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _unbindController(oldWidget.controller);
      _bindController(widget.controller);
      _seeded = false;
      _maybeSeed();
    }
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    super.dispose();
  }

  void _bindController(DropdownPlusController<T>? controller) {
    if (controller == null) return;
    controller.addListener(_onController);
    controller.bindSelectionListener((value) {
      widget.onChanged?.call(value);
      if (mounted) setState(() {});
    });
  }

  void _unbindController(DropdownPlusController<T>? controller) {
    if (controller == null) return;
    controller.removeListener(_onController);
    controller.bindSelectionListener(null);
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  void _maybeSeed() {
    final controller = widget.controller;
    if (controller == null || _seeded) return;
    _seeded = true;
    if (controller.value == null && widget.value != null) {
      controller.applyFromUi(widget.value);
    }
  }

  T? get _effectiveValue =>
      widget.controller != null ? widget.controller!.value : widget.value;

  @override
  Widget build(BuildContext context) {
    final adapter = TypedDropdownAdapter<T>(
      itemLabel: widget.itemLabel,
      itemEquals: widget.itemEquals,
    );

    return SearchableDropdownPlus<C, S>(
      cubit: widget.cubit,
      onSearch: widget.onSearch,
      hintText: widget.hintText,
      selectedValue: adapter.toOptionalItem(_effectiveValue),
      menuController: widget.controller,
      onSelectionChanged: (item) {
        final value = adapter.asValue(item);
        widget.controller?.applyFromUi(value);
        widget.onChanged?.call(value);
      },
      onStateChange: (state, updateList, updateLoading) {
        widget.onStateChange(
          state,
          (items) => updateList(adapter.toItems(items)),
          updateLoading,
        );
      },
      searchHint: widget.searchHint,
      noResultsText: widget.noResultsText,
      loadingText: widget.loadingText,
      needInitialFetch: widget.needInitialFetch,
      dropdownTheme: widget.dropdownTheme,
      themeStyle: widget.themeStyle,
      itemBuilder: widget.itemBuilder == null
          ? null
          : (item, isSelected) => widget.itemBuilder!(
                context,
                adapter.asValue(item),
                isSelected,
              ),
      selectedValueBuilder: widget.valueBuilder == null
          ? null
          : (item) => widget.valueBuilder!(adapter.asValue(item)),
      checkInternetConnection: widget.checkInternetConnection,
      debounceDuration: widget.debounceDuration,
      enabled: widget.enabled,
      autofocusSearch: widget.autofocusSearch,
      emptyBuilder: widget.emptyBuilder,
      loadingBuilder: widget.loadingBuilder,
      error: widget.error,
      onRetry: widget.onRetry,
      errorBuilder: widget.errorBuilder,
      semanticsLabel: widget.semanticsLabel,
      minSearchLength: widget.minSearchLength,
      onLoadMore: widget.onLoadMore,
      hasMore: widget.hasMore,
      isLoadingMore: widget.isLoadingMore,
      focusNode: widget.focusNode,
    );
  }
}
