import '../models/dropdown_item.dart';
import 'typed_dropdown_adapter.dart';

/// Bridges [List<T>] to legacy [DropdownItem] lists.
extension TypedDropdownListX<T> on List<T> {
  List<DropdownItem<T>> toDropdownItems(ItemLabel<T> label) =>
      map((item) => DropdownItem<T>(value: item, label: label(item))).toList();
}

/// Reads the typed value from a [DropdownItem].
extension TypedDropdownItemX<T> on DropdownItem<T> {
  T get typedValue => value;
}
