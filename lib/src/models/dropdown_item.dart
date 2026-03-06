/// A generic model representing a single item in a [SearchableDropdownPlus] or
/// [MultiSelectDropdownPlus] dropdown list.
///
/// [T] is the type of the underlying data value (e.g., a `User`, `String`, `int`).
///
/// ## Example
/// ```dart
/// final item = DropdownItem<User>(
///   value: user,
///   label: user.name,
/// );
/// ```
class DropdownItem<T> {
  const DropdownItem({
    required this.value,
    required this.label,
  });

  /// The underlying data object for this item.
  final T value;

  /// The human-readable string displayed in the dropdown list and chips.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownItem<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DropdownItem(label: $label, value: $value)';
}
