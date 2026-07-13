import 'package:flutter/material.dart';

import 'dropdown_theme_resolver.dart';

typedef DropdownErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback retry,
);

typedef DropdownEmptyBuilder = Widget Function(BuildContext context);

typedef DropdownLoadingBuilder = Widget Function(BuildContext context);

class DropdownLoadingState extends StatelessWidget {
  const DropdownLoadingState({
    required this.resolved,
    this.loadingText,
    this.loadingBuilder,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final String? loadingText;
  final DropdownLoadingBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    if (loadingBuilder != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: loadingBuilder!(context),
      );
    }

    final t = resolved.theme;
    final cs = resolved.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(resolved.loadingColor),
            ),
          ),
          if (loadingText?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                loadingText!,
                style: t.loadingTextStyle ??
                    TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class DropdownEmptyState extends StatelessWidget {
  const DropdownEmptyState({
    required this.resolved,
    this.noResultsText,
    this.emptyBuilder,
    this.compact = false,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final String? noResultsText;
  final DropdownEmptyBuilder? emptyBuilder;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (emptyBuilder != null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 32 : 32,
        ),
        child: emptyBuilder!(context),
      );
    }

    final t = resolved.theme;
    final cs = resolved.colorScheme;
    final iconSize = compact ? 48.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 32 : 16,
        vertical: compact ? 32 : 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: iconSize,
            color: resolved.noResultsIconColor,
          ),
          if (noResultsText?.isNotEmpty == true) ...[
            SizedBox(height: compact ? 12 : 8),
            Text(
              noResultsText!,
              textAlign: TextAlign.center,
              style: t.noResultsTextStyle ??
                  TextStyle(
                    fontSize: compact ? 14 : 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontWeight: compact ? FontWeight.w500 : FontWeight.w400,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class DropdownErrorState extends StatelessWidget {
  const DropdownErrorState({
    required this.resolved,
    required this.error,
    required this.onRetry,
    this.errorBuilder,
    super.key,
  });

  final DropdownResolvedTheme resolved;
  final Object error;
  final VoidCallback onRetry;
  final DropdownErrorBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (errorBuilder != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: errorBuilder!(context, error, onRetry),
      );
    }

    final cs = resolved.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 32, color: cs.error.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
