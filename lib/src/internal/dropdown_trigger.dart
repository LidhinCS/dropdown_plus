import 'package:flutter/material.dart';

import 'dropdown_theme_resolver.dart';

class DropdownTriggerButton extends StatelessWidget {
  const DropdownTriggerButton({
    required this.resolved,
    required this.isOpen,
    required this.onTap,
    required this.child,
    this.showLoadingSpinner = false,
    this.enabled = true,
    this.semanticsLabel,
    this.width,
    this.height,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final bool isOpen;
  final VoidCallback onTap;
  final Widget child;
  final bool showLoadingSpinner;
  final bool enabled;
  final String? semanticsLabel;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = resolved.theme;
    final borderCol = resolved.borderColor;
    final activeBorderCol = resolved.activeBorderColor;
    final loadCol = resolved.loadingColor;
    final arrowCol = resolved.arrowColor(isOpen);
    final effectiveOpen = enabled && isOpen;

    Widget trigger = GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          padding: t.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(t.borderRadius),
            border: Border.all(
              color: effectiveOpen ? activeBorderCol : borderCol,
              width: effectiveOpen ? t.activeBorderWidth : t.borderWidth,
            ),
            boxShadow: effectiveOpen
                ? [
                    BoxShadow(
                      color: activeBorderCol.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(child: child),
              if (showLoadingSpinner) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(loadCol),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              AnimatedRotation(
                turns: effectiveOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: arrowCol,
                  size: t.arrowIconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (semanticsLabel != null) {
      trigger = Semantics(
        button: true,
        enabled: enabled,
        label: semanticsLabel,
        child: trigger,
      );
    }

    return trigger;
  }
}
