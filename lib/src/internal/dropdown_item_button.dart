import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hover highlight for a menu row. Clears as soon as the list scrolls so a
/// stationary mouse wheel does not leave a grey "selected" row behind.
class DropdownHoverScope extends StatefulWidget {
  const DropdownHoverScope({required this.child, super.key});

  final Widget child;

  @override
  State<DropdownHoverScope> createState() => _DropdownHoverScopeState();
}

class _DropdownHoverScopeState extends State<DropdownHoverScope> {
  final ValueNotifier<int> _epoch = ValueNotifier<int>(0);

  @override
  void dispose() {
    _epoch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification &&
              notification.depth == 0 &&
              (notification.scrollDelta ?? 0) != 0) {
            _epoch.value++;
          }
          return false;
        },
        child: _DropdownHoverEpoch(
          notifier: _epoch,
          child: SelectionContainer.disabled(child: widget.child),
        ),
      ),
    );
  }
}

class _DropdownHoverEpoch extends InheritedNotifier<ValueNotifier<int>> {
  const _DropdownHoverEpoch({
    required super.notifier,
    required super.child,
  });

  static ValueNotifier<int>? notifierOf(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<_DropdownHoverEpoch>();
    return (element?.widget as _DropdownHoverEpoch?)?.notifier;
  }
}

class DropdownItemButton extends StatefulWidget {
  const DropdownItemButton({
    required this.onTap,
    required this.padding,
    required this.isSelected,
    required this.selectedColor,
    required this.hoverColor,
    required this.child,
    super.key,
  });

  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final bool isSelected;
  final Color selectedColor;
  final Color hoverColor;
  final Widget child;

  @override
  State<DropdownItemButton> createState() => _DropdownItemButtonState();
}

class _DropdownItemButtonState extends State<DropdownItemButton> {
  bool _hovered = false;
  bool _suppressHover = false;
  ValueNotifier<int>? _epoch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = _DropdownHoverEpoch.notifierOf(context);
    if (!identical(next, _epoch)) {
      _epoch?.removeListener(_clearHover);
      _epoch = next;
      _epoch?.addListener(_clearHover);
    }
  }

  @override
  void dispose() {
    _epoch?.removeListener(_clearHover);
    super.dispose();
  }

  void _clearHover() {
    _suppressHover = true;
    if (!_hovered || !mounted) return;
    setState(() => _hovered = false);
  }

  void _onEnter() {
    if (_suppressHover || _hovered) return;
    setState(() => _hovered = true);
  }

  void _onHover() {
    if (!_suppressHover && _hovered) return;
    _suppressHover = false;
    if (_hovered) return;
    setState(() => _hovered = true);
  }

  void _onExit() {
    _suppressHover = false;
    if (!_hovered) return;
    setState(() => _hovered = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? widget.selectedColor
        : _hovered
            ? widget.hoverColor
            : Colors.transparent;
    final padding = widget.padding.resolve(Directionality.of(context));
    const horizontalInset = 8.0;
    const verticalInset = 4.0;
    final leftInset = math.min(horizontalInset, padding.left);
    final rightInset = math.min(horizontalInset, padding.right);
    final topInset = math.min(verticalInset, padding.top);
    final bottomInset = math.min(verticalInset, padding.bottom);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onEnter(),
      onHover: (_) => _onHover(),
      onExit: (_) => _onExit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            leftInset,
            topInset,
            rightInset,
            bottomInset,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              padding.left - leftInset,
              padding.top - topInset,
              padding.right - rightInset,
              padding.bottom - bottomInset,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Light hover used for unselected rows. Kept separate from the selected color
/// so a hovered row is not mistaken for the current value.
Color dropdownItemHoverColor(ColorScheme colorScheme) =>
    colorScheme.onSurface.withValues(alpha: 0.06);
