import 'package:flutter/material.dart';

import '../utils/debounced_callback.dart';
import 'dropdown_theme_resolver.dart';

class DropdownSearchBar extends StatefulWidget {
  const DropdownSearchBar({
    required this.resolved,
    required this.controller,
    required this.onQueryChanged,
    required this.debouncedSearch,
    this.searchHint,
    this.enabled = true,
    this.autofocus = false,
    this.minSearchLength = 0,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final TextEditingController controller;
  final Future<void> Function(String query) onQueryChanged;
  final DebouncedCallback debouncedSearch;
  final String? searchHint;
  final bool enabled;
  final bool autofocus;
  final int minSearchLength;

  @override
  State<DropdownSearchBar> createState() => _DropdownSearchBarState();
}

class _DropdownSearchBarState extends State<DropdownSearchBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(DropdownSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.autofocus && widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    if (value.isNotEmpty && value.length < widget.minSearchLength) {
      return;
    }
    widget.debouncedSearch(() => widget.onQueryChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.resolved.theme;
    final cs = widget.resolved.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: t.searchBarBackgroundColor ??
              cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(t.searchBarBorderRadius),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          style: t.searchTextStyle,
          decoration: InputDecoration(
            hintText: widget.searchHint ?? 'Search…',
            hintStyle: t.searchHintStyle ??
                TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: t.searchIconColor ?? cs.onSurface.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: _handleChanged,
        ),
      ),
    );
  }
}
