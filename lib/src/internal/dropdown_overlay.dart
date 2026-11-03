import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dropdown_panel.dart';

const double _menuGap = 6;

/// Places [panel] in an overlay anchored to [trigger], so opening the menu
/// does not change the height of the surrounding layout.
class DropdownOverlayHost extends StatefulWidget {
  const DropdownOverlayHost({
    required this.isOpen,
    required this.onDismiss,
    required this.trigger,
    required this.panel,
    required this.menuMaxHeight,
    super.key,
  });

  final bool isOpen;
  final VoidCallback onDismiss;
  final Widget trigger;
  final Widget panel;
  final double menuMaxHeight;

  @override
  State<DropdownOverlayHost> createState() => _DropdownOverlayHostState();
}

class _DropdownOverlayHostState extends State<DropdownOverlayHost> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();

  double _width = 0;
  double _maxHeight = 0;
  bool _openUp = false;

  @override
  void initState() {
    super.initState();
    _maxHeight = widget.menuMaxHeight;
    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openOverlay());
    }
  }

  @override
  void didUpdateWidget(DropdownOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openOverlay());
    } else if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    }
  }

  void _openOverlay() {
    if (!mounted || !widget.isOpen) return;
    _applyMeasure();
    if (_width <= 0) return;
    setState(() {});
    if (!_portal.isShowing) {
      _portal.show();
    }
  }

  void _remeasure() {
    if (!mounted || !widget.isOpen) return;
    if (_applyMeasure()) setState(() {});
  }

  bool _applyMeasure() {
    final triggerContext = _triggerKey.currentContext;
    final box = triggerContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return false;

    final origin = box.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final below = media.size.height -
        media.viewInsets.bottom -
        media.padding.bottom -
        origin.dy -
        box.size.height -
        _menuGap;
    final above = origin.dy - media.padding.top - _menuGap;
    final openUp = below < math.min(widget.menuMaxHeight, 240) && above > below;
    final space = openUp ? above : below;
    final maxHeight = !space.isFinite || space <= 0
        ? widget.menuMaxHeight
        : math.min(space, widget.menuMaxHeight);
    final width = box.size.width;

    final changed =
        width != _width || openUp != _openUp || maxHeight != _maxHeight;
    _width = width;
    _openUp = openUp;
    _maxHeight = maxHeight;
    return changed;
  }

  void _handleClosed() {
    if (!mounted || widget.isOpen) return;
    if (_portal.isShowing) _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: ModalBarrier(
                color: Colors.transparent,
                dismissible: true,
                onDismiss: widget.onDismiss,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: _openUp ? Alignment.topLeft : Alignment.bottomLeft,
              followerAnchor:
                  _openUp ? Alignment.bottomLeft : Alignment.topLeft,
              offset: Offset(0, _openUp ? -_menuGap : _menuGap),
              child: DropdownMenuMetrics(
                maxHeight: _maxHeight,
                child: _DropdownMenuMotion(
                  isOpen: widget.isOpen,
                  openUpward: _openUp,
                  onClosed: _handleClosed,
                  child: SizedBox(
                    width: _width,
                    child: widget.panel,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: KeyedSubtree(
          key: _triggerKey,
          child: widget.trigger,
        ),
      ),
    );
  }
}

class _DropdownMenuMotion extends StatefulWidget {
  const _DropdownMenuMotion({
    required this.isOpen,
    required this.openUpward,
    required this.onClosed,
    required this.child,
  });

  final bool isOpen;
  final bool openUpward;
  final VoidCallback onClosed;
  final Widget child;

  @override
  State<_DropdownMenuMotion> createState() => _DropdownMenuMotionState();
}

class _DropdownMenuMotionState extends State<_DropdownMenuMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_DropdownMenuMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen == oldWidget.isOpen) return;
    if (widget.isOpen) {
      _token++;
      _controller.forward();
      return;
    }

    final token = _token;
    _controller.reverse().whenComplete(() {
      if (!mounted || token != _token || widget.isOpen) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || token != _token || widget.isOpen) return;
        widget.onClosed();
      });
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        final dy = (1 - t) * (widget.openUpward ? 8 : -8);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: child,
          ),
        );
      },
      child: RepaintBoundary(child: widget.child),
    );
  }
}
