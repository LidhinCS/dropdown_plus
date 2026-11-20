import 'package:flutter/widgets.dart';

/// A node in a [CascadeDropdown] menu tree.
///
/// - **Leaf** — not a branch; [value] is selected on tap.
/// - **Branch** — [hasChildren] is true and/or [children] is non-empty; opens a submenu.
///
/// For API-loaded submenus, set [hasChildren] to `true` with empty [children] and
/// provide [CascadeDropdown.onLoadChildren].
///
/// ```dart
/// CascadeMenuItem<String>(
///   label: 'Europe',
///   value: 'eu',
///   hasChildren: true, // load children via onLoadChildren
/// )
/// ```
class CascadeMenuItem<T> {
  const CascadeMenuItem({
    required this.label,
    this.value,
    this.children = const [],
    this.hasChildren = false,
    this.leading,
    this.enabled = true,
  });

  /// Display label for this row and (for leaves) the closed trigger.
  final String label;

  /// Selection payload. Required for leaves; optional for branches (e.g. API id).
  final T? value;

  /// Nested items. May be empty when [hasChildren] is true (lazy load).
  final List<CascadeMenuItem<T>> children;

  /// When `true`, this row is a branch even if [children] is still empty.
  final bool hasChildren;

  /// Optional leading widget (icon, avatar, etc.).
  final Widget? leading;

  /// When `false`, the row is not interactive.
  final bool enabled;

  /// Whether this node opens a submenu.
  bool get isBranch => hasChildren || children.isNotEmpty;

  /// Whether this node can be selected directly.
  bool get isLeaf => !isBranch;

  CascadeMenuItem<T> copyWith({
    String? label,
    T? value,
    List<CascadeMenuItem<T>>? children,
    bool? hasChildren,
    Widget? leading,
    bool? enabled,
  }) {
    return CascadeMenuItem<T>(
      label: label ?? this.label,
      value: value ?? this.value,
      children: children ?? this.children,
      hasChildren: hasChildren ?? this.hasChildren,
      leading: leading ?? this.leading,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Depth-first search for the first item whose [value] equals [target].
  static CascadeMenuItem<T>? findByValue<T>(
    List<CascadeMenuItem<T>> items,
    T target,
  ) {
    for (final item in items) {
      if (item.value == target) return item;
      final nested = findByValue(item.children, target);
      if (nested != null) return nested;
    }
    return null;
  }

  /// Labels from root to the item that holds [target], or empty if not found.
  static List<String> pathLabelsForValue<T>(
    List<CascadeMenuItem<T>> items,
    T target,
  ) {
    List<String>? walk(List<CascadeMenuItem<T>> nodes, List<String> path) {
      for (final item in nodes) {
        final next = [...path, item.label];
        if (item.value == target) return next;
        final found = walk(item.children, next);
        if (found != null) return found;
      }
      return null;
    }

    return walk(items, const []) ?? const [];
  }

  /// Child indices from root to the item that holds [target], or empty if not found.
  static List<int> pathIndicesForValue<T>(
    List<CascadeMenuItem<T>> items,
    T target,
  ) {
    List<int>? walk(List<CascadeMenuItem<T>> nodes, List<int> path) {
      for (var i = 0; i < nodes.length; i++) {
        final item = nodes[i];
        final next = [...path, i];
        if (item.value == target) return next;
        final found = walk(item.children, next);
        if (found != null) return found;
      }
      return null;
    }

    return walk(items, const []) ?? const [];
  }

  /// Replaces [children] of the node at [path] (list of child indices from root).
  static List<CascadeMenuItem<T>> replaceChildrenAt<T>(
    List<CascadeMenuItem<T>> nodes,
    List<int> path,
    List<CascadeMenuItem<T>> children,
  ) {
    if (path.isEmpty) return children;
    final index = path.first;
    if (index < 0 || index >= nodes.length) return nodes;
    final rest = path.sublist(1);
    return [
      for (var i = 0; i < nodes.length; i++)
        if (i != index)
          nodes[i]
        else if (rest.isEmpty)
          nodes[i].copyWith(
            children: children,
            hasChildren: children.isNotEmpty || nodes[i].hasChildren,
          )
        else
          nodes[i].copyWith(
            children: replaceChildrenAt(nodes[i].children, rest, children),
          ),
    ];
  }

  /// Returns the node at [path], or null if the path is invalid.
  static CascadeMenuItem<T>? nodeAt<T>(
    List<CascadeMenuItem<T>> nodes,
    List<int> path,
  ) {
    CascadeMenuItem<T>? node;
    var level = nodes;
    for (final index in path) {
      if (index < 0 || index >= level.length) return null;
      node = level[index];
      level = node.children;
    }
    return node;
  }
}
