import 'package:flutter/widgets.dart';

import '../models/dropdown_item.dart';

/// Label function for typed dropdown items.
typedef ItemLabel<T> = String Function(T item);

/// Equality function for typed dropdown values.
typedef ItemEquals<T> = bool Function(T a, T b);

/// Typed single-select item row builder.
typedef TypedItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  bool isSelected,
);

/// Typed selected-value display builder (single select).
typedef TypedValueBuilder<T> = Widget Function(T selected);

/// Typed multi-select chip display builder.
typedef TypedValuesBuilder<T> = Widget Function(List<T> selected);

/// Maps between domain type [T] and [DropdownItem] for typed dropdown widgets.
class TypedDropdownAdapter<T> {
  const TypedDropdownAdapter({
    required this.itemLabel,
    this.itemEquals,
  });

  final String Function(T) itemLabel;
  final bool Function(T, T)? itemEquals;

  bool equals(T a, T b) => itemEquals?.call(a, b) ?? a == b;

  DropdownItem<dynamic> toItem(T value) =>
      DropdownItem<T>(value: value, label: itemLabel(value));

  List<DropdownItem<dynamic>> toItems(List<T> values) =>
      values.map(toItem).toList();

  DropdownItem<dynamic>? toOptionalItem(T? value) =>
      value == null ? null : toItem(value);

  T asValue(DropdownItem<dynamic> item) => item.value as T;

  List<T> asValues(List<DropdownItem<dynamic>> items) =>
      items.map(asValue).toList();
}
