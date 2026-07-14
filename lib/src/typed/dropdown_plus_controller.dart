import 'package:flutter/foundation.dart';

import '../internal/dropdown_menu_controller.dart';

/// Programmatic control for typed single-select dropdowns.
///
/// Pass to any `TypedSearchableDropdown*` via `controller:`. When set, the
/// controller owns selection; [value] on the widget is only used as an
/// initial seed when the controller has no value yet.
///
/// ```dart
/// final controller = DropdownPlusController<User>();
///
/// controller.select(user);
/// controller.clear();
/// controller.open();
/// controller.close();
/// ```
class DropdownPlusController<T> extends DropdownMenuController {
  T? _value;
  void Function(T? value)? _selectionListener;

  /// Currently selected value, or `null` if cleared / unset.
  T? get value => _value;

  /// Registers a listener invoked by [select] / [clear] (programmatic changes).
  ///
  /// Used by typed widgets to forward [onChanged]. Not for application code.
  @protected
  void setSelectionListener(void Function(T? value)? listener) {
    _selectionListener = listener;
  }

  /// Updates [value] from UI interaction without invoking the selection listener.
  @protected
  void updateFromUi(T? value) {
    if (identical(_value, value) || _value == value) return;
    _value = value;
    notifyListeners();
  }

  /// Selects [value] programmatically, notifies listeners, and invokes
  /// the attached selection listener (`onChanged`).
  void select(T? value) {
    if (identical(_value, value) || _value == value) {
      return;
    }
    _value = value;
    notifyListeners();
    _selectionListener?.call(value);
  }

  /// Clears the selection (`value` → `null`).
  void clear() => select(null);

  @override
  void dispose() {
    _selectionListener = null;
    super.dispose();
  }
}

/// Programmatic control for typed multi-select dropdowns.
///
/// Pass to any `TypedMultiSelectDropdown*` via `controller:`.
///
/// ```dart
/// final controller = DropdownPlusMultiController<User>();
///
/// controller.setValues([a, b]);
/// controller.select(user);
/// controller.deselect(user);
/// controller.clear();
/// controller.open();
/// controller.close();
/// ```
class DropdownPlusMultiController<T> extends DropdownMenuController {
  List<T> _values = const [];
  void Function(List<T> values)? _selectionListener;
  bool Function(T a, T b)? _equals;

  /// Currently selected values.
  List<T> get values => List.unmodifiable(_values);

  /// Optional equality used by [select] / [deselect]. Set by the typed widget.
  @protected
  void setItemEquals(bool Function(T a, T b)? equals) {
    _equals = equals;
  }

  bool _same(T a, T b) => _equals?.call(a, b) ?? a == b;

  bool _listEquals(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }

  /// Registers a listener invoked by programmatic selection changes.
  @protected
  void setSelectionListener(void Function(List<T> values)? listener) {
    _selectionListener = listener;
  }

  /// Updates [values] from UI without invoking the selection listener.
  @protected
  void updateFromUi(List<T> values) {
    if (_listEquals(_values, values)) return;
    _values = List<T>.from(values);
    notifyListeners();
  }

  void _apply(List<T> next) {
    if (_listEquals(_values, next)) return;
    _values = List<T>.from(next);
    notifyListeners();
    _selectionListener?.call(List<T>.from(_values));
  }

  /// Replaces the selection with [values].
  void setValues(List<T> values) => _apply(values);

  /// Adds [value] if not already selected.
  void select(T value) {
    if (_values.any((v) => _same(v, value))) return;
    _apply([..._values, value]);
  }

  /// Removes [value] if selected.
  void deselect(T value) {
    if (!_values.any((v) => _same(v, value))) return;
    _apply(_values.where((v) => !_same(v, value)).toList());
  }

  /// Clears all selected values.
  void clear() => _apply(const []);

  @override
  void dispose() {
    _selectionListener = null;
    super.dispose();
  }
}

/// Typed-widget helpers for wiring selection listeners (same package).
extension DropdownPlusControllerWiring<T> on DropdownPlusController<T> {
  void bindSelectionListener(void Function(T? value)? listener) =>
      setSelectionListener(listener);

  void applyFromUi(T? value) => updateFromUi(value);
}

/// Typed-widget helpers for multi-controller wiring (same package).
extension DropdownPlusMultiControllerWiring<T> on DropdownPlusMultiController<T> {
  void bindSelectionListener(void Function(List<T> values)? listener) =>
      setSelectionListener(listener);

  void bindEquals(bool Function(T a, T b)? equals) => setItemEquals(equals);

  void applyFromUi(List<T> values) => updateFromUi(values);
}
