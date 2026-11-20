import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../internal/dropdown_item_button.dart';
import '../internal/dropdown_overlay.dart';
import '../internal/dropdown_panel.dart';
import '../internal/dropdown_states.dart';
import '../internal/dropdown_theme_resolver.dart';
import '../internal/dropdown_trigger.dart';
import '../models/cascade_menu_item.dart';
import '../models/dropdown_plus_theme.dart';
import '../models/dropdown_plus_theme_style.dart';

/// Loads children for a lazy branch when it is opened.
typedef CascadeLoadChildren<T> = Future<List<CascadeMenuItem<T>>> Function(
  CascadeMenuItem<T> parent,
);

/// Custom loading UI while [CascadeDropdown.onLoadChildren] runs.
typedef CascadeChildrenLoadingBuilder<T> = Widget Function(
  BuildContext context,
  CascadeMenuItem<T> parent,
);

/// Custom error UI when [CascadeDropdown.onLoadChildren] fails.
typedef CascadeChildrenErrorBuilder<T> = Widget Function(
  BuildContext context,
  CascadeMenuItem<T> parent,
  Object error,
  VoidCallback retry,
);

/// High-level presentation for [CascadeDropdown] nested levels.
enum CascadeView {
  /// Fly-out on wide viewports, drill-down on narrow (see [CascadeDropdown.flyoutBreakpoint]).
  auto,

  /// Side fly-out submenus — typical web / desktop cascade.
  web,

  /// Single-panel drill-down with a back header — typical mobile.
  mobile,
}

/// Low-level presentation mode for nested levels.
///
/// Prefer [CascadeView] via [CascadeDropdown.view]. This enum remains for
/// fine-grained control and maps 1:1 with [CascadeView].
enum CascadeSubmenuMode {
  /// Same as [CascadeView.auto].
  auto,

  /// Same as [CascadeView.web].
  flyout,

  /// Same as [CascadeView.mobile].
  drillDown,
}

extension on CascadeView {
  CascadeSubmenuMode get asSubmenuMode => switch (this) {
        CascadeView.auto => CascadeSubmenuMode.auto,
        CascadeView.web => CascadeSubmenuMode.flyout,
        CascadeView.mobile => CascadeSubmenuMode.drillDown,
      };
}

/// Nested / cascade single-select dropdown.
///
/// Standalone from the searchable widgets: no search, multi-select, pagination,
/// or BLoC. Use for hierarchical picks.
///
/// - [CascadeView.web] — fly-out submenus (hover or tap).
/// - [CascadeView.mobile] — drill-down in one panel with a back header.
/// - [CascadeView.auto] — picks web vs mobile from viewport width.
/// - Leaf rows call [onChanged] and close the menu.
/// - Lazy branches: set [CascadeMenuItem.hasChildren] and [onLoadChildren].
/// - Tap outside dismisses all levels.
class CascadeDropdown<T> extends StatefulWidget {
  const CascadeDropdown({
    required this.hintText,
    required this.items,
    super.key,
    this.value,
    this.onChanged,
    this.onLoadChildren,
    this.childrenLoadingBuilder,
    this.childrenErrorBuilder,
    this.dropdownTheme,
    this.themeStyle,
    this.enabled = true,
    this.selectedValueBuilder,
    this.showPathInTrigger = false,
    this.pathSeparator = ' › ',
    this.submenuWidth = 200,
    this.view = CascadeView.auto,
    this.submenuMode,
    this.flyoutBreakpoint = 600,
    this.focusNode,
    this.semanticsLabel,
  });

  /// Placeholder when nothing is selected.
  final String hintText;

  /// Root-level menu tree.
  final List<CascadeMenuItem<T>> items;

  /// Currently selected leaf value (controlled).
  final T? value;

  /// Called when a leaf item is chosen.
  final ValueChanged<T>? onChanged;

  /// Called the first time a branch with empty [CascadeMenuItem.children] is
  /// opened. Return the child rows for that parent (may be empty).
  final CascadeLoadChildren<T>? onLoadChildren;

  /// Optional loading UI while [onLoadChildren] is in flight.
  final CascadeChildrenLoadingBuilder<T>? childrenLoadingBuilder;

  /// Optional error UI when [onLoadChildren] throws.
  final CascadeChildrenErrorBuilder<T>? childrenErrorBuilder;

  final DropdownPlusTheme? dropdownTheme;
  final DropdownPlusThemeStyle? themeStyle;

  /// When `false`, the trigger cannot open the menu.
  final bool enabled;

  /// Custom closed-trigger content for the selected value.
  final Widget Function(T value)? selectedValueBuilder;

  /// When `true`, the trigger shows `Parent › Child › Leaf`.
  final bool showPathInTrigger;

  /// Separator used when [showPathInTrigger] is true.
  final String pathSeparator;

  /// Width of each fly-out submenu panel.
  final double submenuWidth;

  /// Cascade presentation: [CascadeView.auto], [CascadeView.web], or
  /// [CascadeView.mobile]. Default: [CascadeView.auto].
  ///
  /// Overridden when [submenuMode] is non-null.
  final CascadeView view;

  /// Optional low-level override for [view]. When set, takes precedence.
  final CascadeSubmenuMode? submenuMode;

  /// Minimum viewport width that uses fly-outs when [view] is
  /// [CascadeView.auto]. Default: `600`.
  final double flyoutBreakpoint;

  final FocusNode? focusNode;
  final String? semanticsLabel;

  @override
  State<CascadeDropdown<T>> createState() => _CascadeDropdownState<T>();
}

class _CascadeDropdownState<T> extends State<CascadeDropdown<T>> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _triggerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();

  bool _isOpen = false;
  bool _openUp = false;
  T? _selected;
  double _triggerWidth = 0;
  double _menuMaxHeight = 320;

  /// Working tree (updated when lazy children load).
  late List<CascadeMenuItem<T>> _tree;

  /// Open branch indices from root depth → deeper levels.
  List<int> _path = const [];

  /// Layer links for each open branch row (fly-out only).
  final List<LayerLink> _branchLinks = [];

  /// Whether each open submenu prefers the left side (fly-out only).
  List<bool> _openLeft = const [];

  /// Whether each open submenu grows upward from its row (fly-out only).
  List<bool> _submenuOpenUp = const [];

  /// Per-submenu height caps from remaining viewport space (fly-out only).
  List<double> _submenuMaxHeights = const [];

  final Set<String> _loadingKeys = {};
  final Map<String, Object> _errors = {};
  final Set<String> _loadedKeys = {};

  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
    _tree = widget.items;
  }

  @override
  void didUpdateWidget(CascadeDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _selected = widget.value;
    }
    if (!identical(oldWidget.items, widget.items)) {
      _tree = widget.items;
      _loadingKeys.clear();
      _errors.clear();
      _loadedKeys.clear();
    }
    if (oldWidget.view != widget.view ||
        oldWidget.submenuMode != widget.submenuMode) {
      _path = const [];
      _branchLinks.clear();
      _openLeft = const [];
      _submenuOpenUp = const [];
      _submenuMaxHeights = const [];
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  CascadeSubmenuMode get _effectiveMode =>
      widget.submenuMode ?? widget.view.asSubmenuMode;

  bool _useDrillDown(BuildContext context) {
    switch (_effectiveMode) {
      case CascadeSubmenuMode.drillDown:
        return true;
      case CascadeSubmenuMode.flyout:
        return false;
      case CascadeSubmenuMode.auto:
        return MediaQuery.sizeOf(context).width < widget.flyoutBreakpoint;
    }
  }

  void _open() {
    if (!widget.enabled || _isOpen) return;
    setState(() {
      _isOpen = true;
      _path = const [];
      _branchLinks.clear();
      _openLeft = const [];
      _submenuOpenUp = const [];
      _submenuMaxHeights = const [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  void _close() {
    _closeTimer?.cancel();
    if (!_isOpen) return;
    setState(() {
      _isOpen = false;
      _openUp = false;
      _path = const [];
      _branchLinks.clear();
      _openLeft = const [];
      _submenuOpenUp = const [];
      _submenuMaxHeights = const [];
    });
    if (_portal.isShowing) _portal.hide();
  }

  double _estimateLevelHeight(
    List<CascadeMenuItem<T>> items, {
    bool withHeader = false,
  }) {
    const row = 48.0;
    const listPadding = 8.0;
    const headerReserve = 52.0;
    const border = 2.0;
    final list = items.length * row + listPadding;
    return list + border + (withHeader ? headerReserve : 0);
  }

  /// Recompute open direction / max height from the trigger and current panel
  /// content (root items or drilled-in children).
  void _applyOverlayPlacement({bool showIfNeeded = false}) {
    if (!mounted || !_isOpen) return;
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final media = MediaQuery.of(context);
    final origin = box.localToGlobal(Offset.zero);
    const edgeReserve = 2.0;
    final below = media.size.height -
        media.viewInsets.bottom -
        media.padding.bottom -
        origin.dy -
        box.size.height -
        dropdownMenuGap -
        edgeReserve;
    final above = origin.dy - media.padding.top - dropdownMenuGap - edgeReserve;
    final themeMax = DropdownResolvedTheme.resolve(
      context,
      dropdownTheme: widget.dropdownTheme,
      themeStyle: widget.themeStyle,
    ).theme.menuMaxHeight;
    final depth = _path.length;
    final preferred = _estimateLevelHeight(
      _itemsAtDepth(depth),
      withHeader: depth > 0,
    );
    final openUp = dropdownShouldOpenUpward(
      spaceBelow: below,
      spaceAbove: above,
      menuMaxHeight: themeMax,
      preferredHeight: preferred,
    );
    final space = openUp ? above : below;
    final maxHeight = dropdownPanelMaxHeight(
      availableSpace: space,
      menuMaxHeight: themeMax,
    );
    final changed = box.size.width != _triggerWidth ||
        openUp != _openUp ||
        maxHeight != _menuMaxHeight;
    if (changed) {
      setState(() {
        _triggerWidth = box.size.width;
        _openUp = openUp;
        _menuMaxHeight = maxHeight;
      });
    }
    if (showIfNeeded && !_portal.isShowing) _portal.show();
  }

  void _showOverlay() => _applyOverlayPlacement(showIfNeeded: true);

  void _remeasureOverlay() => _applyOverlayPlacement();

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _cancelPendingClose() {
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _scheduleCollapseTo(int depth) {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || !_isOpen) return;
      setState(() => _collapsePathTo(depth));
    });
  }

  void _collapsePathTo(int depth) {
    if (depth <= 0) {
      _path = const [];
      _branchLinks.clear();
      _openLeft = const [];
      _submenuOpenUp = const [];
      _submenuMaxHeights = const [];
      return;
    }
    _path = _path.sublist(0, depth);
    _openLeft = _openLeft.sublist(0, math.min(depth, _openLeft.length));
    _submenuOpenUp =
        _submenuOpenUp.sublist(0, math.min(depth, _submenuOpenUp.length));
    _submenuMaxHeights = _submenuMaxHeights.sublist(
      0,
      math.min(depth, _submenuMaxHeights.length),
    );
    while (_branchLinks.length > _path.length) {
      _branchLinks.removeLast();
    }
  }

  String _pathKey(List<int> path) => path.join('/');

  void _drillInto(int index) {
    _cancelPendingClose();
    final next = [..._path, index];
    setState(() => _path = next);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _remeasureOverlay());
    _ensureChildrenLoaded(next);
  }

  void _drillBack() {
    if (_path.isEmpty) return;
    setState(() => _collapsePathTo(_path.length - 1));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _remeasureOverlay());
  }

  void _openBranchFlyout(
    int depth,
    int index,
    LayerLink link,
    BuildContext rowContext,
  ) {
    _cancelPendingClose();
    var openLeft = false;
    var openUp = false;
    var submenuMax = _menuMaxHeight;
    final box = rowContext.findRenderObject() as RenderBox?;
    if (box != null && box.attached && box.hasSize) {
      final media = MediaQuery.of(context);
      final origin = box.localToGlobal(Offset.zero);
      final rightSpace = media.size.width - origin.dx - box.size.width - 4;
      openLeft = rightSpace < widget.submenuWidth;

      // Top-aligned submenu grows from the row top; bottom-aligned from
      // the row bottom. Prefer the side that can fit the children panel.
      const reserved = 8.0;
      final spaceBelow = media.size.height -
          media.viewInsets.bottom -
          media.padding.bottom -
          origin.dy -
          reserved;
      final spaceAbove =
          origin.dy + box.size.height - media.padding.top - reserved;
      final themeMax = DropdownResolvedTheme.resolve(
        context,
        dropdownTheme: widget.dropdownTheme,
        themeStyle: widget.themeStyle,
      ).theme.menuMaxHeight;
      final branch = _itemsAtDepth(depth);
      final childItems = (index >= 0 && index < branch.length)
          ? branch[index].children
          : <CascadeMenuItem<T>>[];
      final preferred = childItems.isEmpty
          ? themeMax
          : _estimateLevelHeight(childItems);
      openUp = dropdownShouldOpenUpward(
        spaceBelow: spaceBelow,
        spaceAbove: spaceAbove,
        menuMaxHeight: themeMax,
        preferredHeight: preferred,
      );
      submenuMax = dropdownPanelMaxHeight(
        availableSpace: openUp ? spaceAbove : spaceBelow,
        menuMaxHeight: themeMax,
      );
    }

    final next = [..._path.sublist(0, depth), index];
    setState(() {
      _path = next;
      while (_branchLinks.length > depth) {
        _branchLinks.removeLast();
      }
      if (_branchLinks.length == depth) {
        _branchLinks.add(link);
      } else {
        _branchLinks[depth] = link;
      }
      _openLeft = _writeFlagAt(_openLeft, depth, openLeft);
      _submenuOpenUp = _writeFlagAt(_submenuOpenUp, depth, openUp);
      _submenuMaxHeights =
          _writeDoubleAt(_submenuMaxHeights, depth, submenuMax);
    });
    _ensureChildrenLoaded(next);
  }

  List<bool> _writeFlagAt(List<bool> source, int depth, bool value) {
    final next = [...source.sublist(0, math.min(depth, source.length))];
    while (next.length < depth) {
      next.add(false);
    }
    if (next.length == depth) {
      next.add(value);
    } else {
      next[depth] = value;
    }
    return next;
  }

  List<double> _writeDoubleAt(List<double> source, int depth, double value) {
    final next = [...source.sublist(0, math.min(depth, source.length))];
    while (next.length < depth) {
      next.add(_menuMaxHeight);
    }
    if (next.length == depth) {
      next.add(value);
    } else {
      next[depth] = value;
    }
    return next;
  }

  Future<void> _ensureChildrenLoaded(
    List<int> parentPath, {
    bool force = false,
  }) async {
    final loader = widget.onLoadChildren;
    if (loader == null || parentPath.isEmpty) return;

    final parent = CascadeMenuItem.nodeAt(_tree, parentPath);
    if (parent == null || !parent.isBranch) return;
    if (parent.children.isNotEmpty && !force) return;

    final key = _pathKey(parentPath);
    if (!force && (_loadingKeys.contains(key) || _loadedKeys.contains(key))) {
      return;
    }

    setState(() {
      _loadingKeys.add(key);
      _errors.remove(key);
      if (force) _loadedKeys.remove(key);
    });

    try {
      final children = await loader(parent);
      if (!mounted) return;
      setState(() {
        _tree = CascadeMenuItem.replaceChildrenAt(_tree, parentPath, children);
        _loadingKeys.remove(key);
        _loadedKeys.add(key);
        _errors.remove(key);
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _remeasureOverlay());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingKeys.remove(key);
        _errors[key] = error;
      });
    }
  }

  void _selectLeaf(T value) {
    setState(() => _selected = value);
    widget.onChanged?.call(value);
    _close();
  }

  List<CascadeMenuItem<T>> _itemsAtDepth(int depth) {
    var items = _tree;
    for (var i = 0; i < depth; i++) {
      if (i >= _path.length) return const [];
      final index = _path[i];
      if (index < 0 || index >= items.length) return const [];
      items = items[index].children;
    }
    return items;
  }

  String? _titleAtDepth(int depth) {
    if (depth <= 0 || depth > _path.length) return null;
    return CascadeMenuItem.nodeAt(_tree, _path.sublist(0, depth))?.label;
  }

  /// Row to emphasize at [depth]: open branch first, else selected-value path
  /// while navigation still follows that branch.
  int? _highlightIndexAt(int depth) {
    if (depth < _path.length) return _path[depth];

    final selected = _selected;
    if (selected == null) return null;
    final selectedPath = CascadeMenuItem.pathIndicesForValue(_tree, selected);
    if (depth >= selectedPath.length) return null;

    for (var i = 0; i < _path.length; i++) {
      if (i >= selectedPath.length || _path[i] != selectedPath[i]) {
        return null;
      }
    }
    return selectedPath[depth];
  }

  Widget _buildLevelBody({
    required DropdownResolvedTheme resolved,
    required List<int> parentPath,
    required int depth,
    required List<CascadeMenuItem<T>> items,
    required bool drillDown,
    required void Function(
      int depth,
      int index,
      LayerLink link,
      BuildContext rowContext,
    )? onOpenBranch,
    required ValueChanged<int>? onDrillInto,
    required VoidCallback onKeepOpen,
    required VoidCallback onExitLevel,
    double? maxHeight,
  }) {
    final key = parentPath.isEmpty ? '' : _pathKey(parentPath);
    final parent =
        parentPath.isEmpty ? null : CascadeMenuItem.nodeAt(_tree, parentPath);

    if (parentPath.isNotEmpty && _loadingKeys.contains(key)) {
      if (widget.childrenLoadingBuilder != null && parent != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: widget.childrenLoadingBuilder!(context, parent),
        );
      }
      return DropdownLoadingState(
        resolved: resolved,
        loadingText: 'Loading…',
      );
    }

    if (parentPath.isNotEmpty && _errors.containsKey(key) && parent != null) {
      final error = _errors[key]!;
      void retry() => _ensureChildrenLoaded(parentPath, force: true);
      if (widget.childrenErrorBuilder != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: widget.childrenErrorBuilder!(
            context,
            parent,
            error,
            retry,
          ),
        );
      }
      return DropdownErrorState(
        resolved: resolved,
        error: error,
        onRetry: retry,
      );
    }

    if (items.isEmpty) {
      return DropdownEmptyState(
        resolved: resolved,
        noResultsText: 'No items',
        compact: true,
      );
    }

    return _CascadeMenuList<T>(
      resolved: resolved,
      items: items,
      depth: depth,
      highlightIndex: _highlightIndexAt(depth),
      selectedValue: _selected,
      drillDown: drillDown,
      maxHeight: maxHeight,
      onOpenBranch: onOpenBranch,
      onDrillInto: onDrillInto,
      onSelectLeaf: _selectLeaf,
      onKeepOpen: onKeepOpen,
      onExitLevel: onExitLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = DropdownResolvedTheme.resolve(
      context,
      dropdownTheme: widget.dropdownTheme,
      themeStyle: widget.themeStyle,
    );
    final menuMax = math.min(
      _menuMaxHeight,
      resolved.theme.menuMaxHeight,
    );
    final drillDown = _useDrillDown(context);

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: ModalBarrier(
                color: Colors.transparent,
                dismissible: true,
                onDismiss: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _triggerLink,
              showWhenUnlinked: false,
              targetAnchor: _openUp ? Alignment.topLeft : Alignment.bottomLeft,
              followerAnchor:
                  _openUp ? Alignment.bottomLeft : Alignment.topLeft,
              offset: Offset(0, _openUp ? -dropdownMenuGap : dropdownMenuGap),
              child: DropdownMenuMetrics(
                maxHeight: menuMax,
                child: SizedBox(
                  width: _triggerWidth,
                  child: drillDown
                      ? _buildDrillDownPanel(resolved, menuMax)
                      : _buildFlyoutRootPanel(resolved, menuMax),
                ),
              ),
            ),
            if (!drillDown)
              for (var depth = 0; depth < _path.length; depth++)
                if (depth < _branchLinks.length)
                  Builder(
                    builder: (context) {
                      final openLeft =
                          _openLeft.length > depth && _openLeft[depth];
                      final openUp = _submenuOpenUp.length > depth &&
                          _submenuOpenUp[depth];
                      final submenuMax = _submenuMaxHeights.length > depth
                          ? math.min(menuMax, _submenuMaxHeights[depth])
                          : menuMax;
                      final targetAnchor = openUp
                          ? (openLeft
                              ? Alignment.bottomLeft
                              : Alignment.bottomRight)
                          : (openLeft ? Alignment.topLeft : Alignment.topRight);
                      final followerAnchor = openUp
                          ? (openLeft
                              ? Alignment.bottomRight
                              : Alignment.bottomLeft)
                          : (openLeft ? Alignment.topRight : Alignment.topLeft);
                      return CompositedTransformFollower(
                        link: _branchLinks[depth],
                        showWhenUnlinked: false,
                        targetAnchor: targetAnchor,
                        followerAnchor: followerAnchor,
                        offset: Offset(
                          openLeft ? -4 : 4,
                          // Keep a slight overlap with the parent row on
                          // both sides so height math stays in-viewport.
                          -6,
                        ),
                        child: DropdownMenuMetrics(
                          maxHeight: submenuMax,
                          child: _CascadeSubmenuPanel<T>(
                            resolved: resolved,
                            width: widget.submenuWidth,
                            body: _buildLevelBody(
                              resolved: resolved,
                              parentPath: _path.sublist(0, depth + 1),
                              depth: depth + 1,
                              items: _itemsAtDepth(depth + 1),
                              drillDown: false,
                              maxHeight: submenuMax,
                              onOpenBranch: _openBranchFlyout,
                              onDrillInto: null,
                              onKeepOpen: _cancelPendingClose,
                              onExitLevel: () => _scheduleCollapseTo(depth + 1),
                            ),
                            onKeepOpen: _cancelPendingClose,
                            onExitLevel: () => _scheduleCollapseTo(depth + 1),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _triggerLink,
        child: KeyedSubtree(
          key: _triggerKey,
          child: DropdownTriggerButton(
            resolved: resolved,
            isOpen: _isOpen,
            enabled: widget.enabled,
            semanticsLabel: widget.semanticsLabel ?? widget.hintText,
            focusNode: widget.focusNode,
            onTap: _toggle,
            child: _buildTriggerContent(resolved),
          ),
        ),
      ),
    );
  }

  Widget _buildFlyoutRootPanel(
    DropdownResolvedTheme resolved,
    double menuMax,
  ) {
    return DropdownPanelShell(
      resolved: resolved,
      maxHeight: menuMax,
      children: [
        _buildLevelBody(
          resolved: resolved,
          parentPath: const [],
          depth: 0,
          items: _tree,
          drillDown: false,
          maxHeight: menuMax,
          onOpenBranch: _openBranchFlyout,
          onDrillInto: null,
          onKeepOpen: _cancelPendingClose,
          onExitLevel: () => _scheduleCollapseTo(0),
        ),
      ],
    );
  }

  Widget _buildDrillDownPanel(
    DropdownResolvedTheme resolved,
    double menuMax,
  ) {
    final depth = _path.length;
    final items = _itemsAtDepth(depth);
    final title = _titleAtDepth(depth);
    // Keep a safe reserve for the back header so short lists stay tight
    // while tall ones still clamp inside the viewport.
    const headerReserve = 52.0;
    final listMax =
        depth > 0 ? math.max(80.0, menuMax - headerReserve) : menuMax;

    return DropdownPanelShell(
      resolved: resolved,
      maxHeight: menuMax,
      children: [
        if (depth > 0)
          _CascadeDrillHeader(
            resolved: resolved,
            title: title ?? widget.hintText,
            onBack: _drillBack,
          ),
        _buildLevelBody(
          resolved: resolved,
          parentPath: depth == 0 ? const [] : _path,
          depth: depth,
          items: items,
          drillDown: true,
          maxHeight: listMax,
          onOpenBranch: null,
          onDrillInto: _drillInto,
          onKeepOpen: _cancelPendingClose,
          onExitLevel: () {},
        ),
      ],
    );
  }

  Widget _buildTriggerContent(DropdownResolvedTheme resolved) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;
    final selected = _selected;

    if (selected == null) {
      return Text(
        widget.hintText,
        style: t.hintStyle ??
            TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
      );
    }

    if (widget.selectedValueBuilder != null) {
      return widget.selectedValueBuilder!(selected);
    }

    final label = widget.showPathInTrigger
        ? CascadeMenuItem.pathLabelsForValue(_tree, selected)
            .join(widget.pathSeparator)
        : (CascadeMenuItem.findByValue(_tree, selected)?.label ??
            selected.toString());

    return Text(
      label.isEmpty ? selected.toString() : label,
      style: t.triggerTextStyle ??
          Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CascadeDrillHeader extends StatelessWidget {
  const _CascadeDrillHeader({
    required this.resolved,
    required this.title,
    required this.onBack,
  });

  final DropdownResolvedTheme resolved;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = resolved.theme;
    final cs = resolved.colorScheme;
    final divCol = resolved.dividerColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divCol)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: cs.onSurface.withValues(alpha: 0.7),
              visualDensity: VisualDensity.compact,
              tooltip: 'Back',
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: t.selectedItemTextStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CascadeSubmenuPanel<T> extends StatelessWidget {
  const _CascadeSubmenuPanel({
    required this.resolved,
    required this.width,
    required this.body,
    required this.onKeepOpen,
    required this.onExitLevel,
  });

  final DropdownResolvedTheme resolved;
  final double width;
  final Widget body;
  final VoidCallback onKeepOpen;
  final VoidCallback onExitLevel;

  @override
  Widget build(BuildContext context) {
    final overlayMax = DropdownMenuMetrics.maybeOf(context)?.maxHeight;
    final maxH = overlayMax == null
        ? resolved.theme.menuMaxHeight
        : math.min(resolved.theme.menuMaxHeight, overlayMax);

    return MouseRegion(
      onEnter: (_) => onKeepOpen(),
      onExit: (_) => onExitLevel(),
      child: SizedBox(
        width: width,
        child: DropdownPanelShell(
          resolved: resolved,
          maxHeight: maxH,
          children: [body],
        ),
      ),
    );
  }
}

class _CascadeMenuList<T> extends StatelessWidget {
  const _CascadeMenuList({
    required this.resolved,
    required this.items,
    required this.depth,
    required this.highlightIndex,
    required this.selectedValue,
    required this.drillDown,
    required this.onOpenBranch,
    required this.onDrillInto,
    required this.onSelectLeaf,
    required this.onKeepOpen,
    required this.onExitLevel,
    this.maxHeight,
  });

  final DropdownResolvedTheme resolved;
  final List<CascadeMenuItem<T>> items;
  final int depth;
  final int? highlightIndex;
  final T? selectedValue;
  final bool drillDown;
  final void Function(
    int depth,
    int index,
    LayerLink link,
    BuildContext rowContext,
  )? onOpenBranch;
  final ValueChanged<int>? onDrillInto;
  final ValueChanged<T> onSelectLeaf;
  final VoidCallback onKeepOpen;
  final VoidCallback onExitLevel;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final overlayMax = DropdownMenuMetrics.maybeOf(context)?.maxHeight;
    final cap = [
      if (maxHeight != null) maxHeight!,
      if (overlayMax != null) overlayMax,
      resolved.theme.menuMaxHeight,
    ].reduce(math.min);

    // Size to content so short menus don't leave empty tail space; clamp
    // so tall menus scroll inside the viewport budget.
    const estimatedRowHeight = 48.0;
    const listPadding = 8.0;
    final contentHeight = items.length * estimatedRowHeight + listPadding;
    final listHeight = contentHeight.clamp(0.0, cap);

    return DropdownHoverScope(
      child: SizedBox(
        height: listHeight,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _CascadeMenuRow<T>(
              resolved: resolved,
              item: item,
              depth: depth,
              index: index,
              isInPath: highlightIndex == index,
              isSelected: item.value != null && item.value == selectedValue,
              drillDown: drillDown,
              onOpenBranch: onOpenBranch,
              onDrillInto: onDrillInto,
              onSelectLeaf: onSelectLeaf,
              onKeepOpen: onKeepOpen,
              onExitLevel: onExitLevel,
            );
          },
        ),
      ),
    );
  }
}

class _CascadeMenuRow<T> extends StatefulWidget {
  const _CascadeMenuRow({
    required this.resolved,
    required this.item,
    required this.depth,
    required this.index,
    required this.isInPath,
    required this.isSelected,
    required this.drillDown,
    required this.onOpenBranch,
    required this.onDrillInto,
    required this.onSelectLeaf,
    required this.onKeepOpen,
    required this.onExitLevel,
  });

  final DropdownResolvedTheme resolved;
  final CascadeMenuItem<T> item;
  final int depth;
  final int index;
  final bool isInPath;
  final bool isSelected;
  final bool drillDown;
  final void Function(
    int depth,
    int index,
    LayerLink link,
    BuildContext rowContext,
  )? onOpenBranch;
  final ValueChanged<int>? onDrillInto;
  final ValueChanged<T> onSelectLeaf;
  final VoidCallback onKeepOpen;
  final VoidCallback onExitLevel;

  @override
  State<_CascadeMenuRow<T>> createState() => _CascadeMenuRowState<T>();
}

class _CascadeMenuRowState<T> extends State<_CascadeMenuRow<T>> {
  late final LayerLink _link = LayerLink();

  void _activateBranch() {
    if (!widget.item.enabled || !widget.item.isBranch) return;
    if (widget.drillDown) {
      widget.onDrillInto?.call(widget.index);
      return;
    }
    widget.onOpenBranch?.call(widget.depth, widget.index, _link, context);
  }

  void _handleTap() {
    if (!widget.item.enabled) return;
    if (widget.item.isBranch) {
      _activateBranch();
      return;
    }
    final value = widget.item.value;
    if (value != null) widget.onSelectLeaf(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.resolved.theme;
    final cs = widget.resolved.colorScheme;
    final item = widget.item;
    final selectedColor = t.selectedItemBackgroundColor ??
        cs.primaryContainer.withValues(alpha: 0.3);
    final pathColor = cs.primary.withValues(alpha: 0.12);
    final emphasized = widget.isSelected || widget.isInPath;
    final rowColor = widget.isSelected
        ? selectedColor
        : widget.isInPath
            ? pathColor
            : Colors.transparent;
    final textStyle = widget.isSelected || widget.isInPath
        ? (t.selectedItemTextStyle ??
            TextStyle(
              fontSize: 14,
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ))
        : (t.itemTextStyle ?? TextStyle(fontSize: 14, color: cs.onSurface));

    final row = DropdownItemButton(
      onTap: _handleTap,
      padding: t.itemPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isSelected: emphasized,
      selectedColor: rowColor,
      hoverColor: dropdownItemHoverColor(cs),
      child: Row(
        children: [
          if (item.leading != null) ...[
            IconTheme(
              data: IconThemeData(
                size: 18,
                color: emphasized
                    ? (t.selectedItemTextStyle?.color ?? cs.primary)
                    : (t.itemTextStyle?.color ?? cs.onSurface),
              ),
              child: item.leading!,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              item.label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.isBranch)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: emphasized
                  ? cs.primary.withValues(alpha: 0.7)
                  : cs.onSurface.withValues(alpha: 0.45),
            )
          else if (widget.isSelected)
            Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
        ],
      ),
    );

    Widget child = Semantics(
      button: true,
      enabled: item.enabled,
      selected: widget.isSelected || widget.isInPath,
      label: item.label,
      onTap: item.enabled ? _handleTap : null,
      child: Opacity(
        opacity: item.enabled ? 1 : 0.45,
        child: row,
      ),
    );

    if (item.isBranch && !widget.drillDown) {
      child = CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) {
            widget.onKeepOpen();
            _activateBranch();
          },
          onExit: (_) => widget.onExitLevel(),
          child: child,
        ),
      );
    }

    return child;
  }
}
