import 'package:flutter/material.dart';

import '../internal/dropdown_states.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../widgets/searchable_dropdown.dart';
import 'dropdown_plus_controller.dart';
import 'typed_dropdown_adapter.dart';

/// Typed single-select searchable dropdown without BLoC/Cubit.
///
/// Opt-in API — import `package:dropdown_plus_bloc/typed.dart`.
class TypedSearchableDropdown<T> extends StatefulWidget {
  const TypedSearchableDropdown({
    required this.hintText,
    required this.items,
    required this.isLoading,
    required this.itemLabel,
    super.key,
    this.value,
    this.onChanged,
    this.controller,
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

  /// When set, owns selection; [value] is only an initial seed.
  final DropdownPlusController<T>? controller;
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
  State<TypedSearchableDropdown<T>> createState() =>
      _TypedSearchableDropdownState<T>();
}

class _TypedSearchableDropdownState<T> extends State<TypedSearchableDropdown<T>> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
    _maybeSeed();
  }

  @override
  void didUpdateWidget(TypedSearchableDropdown<T> oldWidget) {
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

    return SearchableDropdown(
      hintText: widget.hintText,
      items: adapter.toItems(widget.items),
      isLoading: widget.isLoading,
      selectedValue: adapter.toOptionalItem(_effectiveValue),
      menuController: widget.controller,
      onSelectionChanged: (item) {
        final value = adapter.asValue(item);
        widget.controller?.applyFromUi(value);
        widget.onChanged?.call(value);
      },
      onSearch: widget.onSearch,
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
