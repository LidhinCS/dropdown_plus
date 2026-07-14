import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../internal/dropdown_states.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';
import '../widgets/multi_select_dropdown_plus.dart';
import 'dropdown_plus_controller.dart';
import 'typed_dropdown_adapter.dart';

/// Typed multi-select searchable dropdown with BLoC/Cubit integration.
///
/// Opt-in API — import `package:dropdown_plus_bloc/typed.dart`.
class TypedMultiSelectDropdownPlus<T, C extends BlocBase<S>, S>
    extends StatefulWidget {
  const TypedMultiSelectDropdownPlus({
    required this.cubit,
    required this.onSearch,
    required this.onStateChange,
    required this.hintText,
    required this.itemLabel,
    super.key,
    this.values = const [],
    this.onChanged,
    this.controller,
    this.itemEquals,
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

  final C cubit;
  final void Function(String query) onSearch;
  final void Function(
    S state,
    void Function(List<T> items) updateItems,
    void Function(bool) updateLoading,
  ) onStateChange;
  final String hintText;
  final ItemLabel<T> itemLabel;
  final List<T> values;
  final void Function(List<T> values)? onChanged;

  /// When set, owns selection; [values] is only an initial seed.
  final DropdownPlusMultiController<T>? controller;
  final ItemEquals<T>? itemEquals;
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
  State<TypedMultiSelectDropdownPlus<T, C, S>> createState() =>
      _TypedMultiSelectDropdownPlusState<T, C, S>();
}

class _TypedMultiSelectDropdownPlusState<T, C extends BlocBase<S>, S>
    extends State<TypedMultiSelectDropdownPlus<T, C, S>> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
    _maybeSeed();
  }

  @override
  void didUpdateWidget(TypedMultiSelectDropdownPlus<T, C, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _unbindController(oldWidget.controller);
      _bindController(widget.controller);
      _seeded = false;
      _maybeSeed();
    } else if (widget.controller != null) {
      widget.controller!.bindEquals(widget.itemEquals);
    }
  }

  @override
  void dispose() {
    _unbindController(widget.controller);
    super.dispose();
  }

  void _bindController(DropdownPlusMultiController<T>? controller) {
    if (controller == null) return;
    controller.addListener(_onController);
    controller.bindEquals(widget.itemEquals);
    controller.bindSelectionListener((values) {
      widget.onChanged?.call(values);
      if (mounted) setState(() {});
    });
  }

  void _unbindController(DropdownPlusMultiController<T>? controller) {
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
    if (controller.values.isEmpty && widget.values.isNotEmpty) {
      controller.applyFromUi(widget.values);
    }
  }

  List<T> get _effectiveValues =>
      widget.controller != null ? widget.controller!.values : widget.values;

  @override
  Widget build(BuildContext context) {
    final adapter = TypedDropdownAdapter<T>(
      itemLabel: widget.itemLabel,
      itemEquals: widget.itemEquals,
    );

    return MultiSelectDropdownPlus<C, S>(
      cubit: widget.cubit,
      onSearch: widget.onSearch,
      hintText: widget.hintText,
      selectedItems: adapter.toItems(_effectiveValues),
      menuController: widget.controller,
      onSelectionChanged: (items) {
        final values = adapter.asValues(items);
        widget.controller?.applyFromUi(values);
        widget.onChanged?.call(values);
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
      maxDisplayChips: widget.maxDisplayChips,
      dropdownTheme: widget.dropdownTheme,
      themeStyle: widget.themeStyle,
      itemBuilder: widget.itemBuilder == null
          ? null
          : (item, isSelected) => widget.itemBuilder!(
                context,
                adapter.asValue(item),
                isSelected,
              ),
      selectedItemBuilder: widget.valuesBuilder == null
          ? null
          : (items) => widget.valuesBuilder!(adapter.asValues(items)),
      buttonHeight: widget.buttonHeight,
      buttonWidth: widget.buttonWidth,
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
