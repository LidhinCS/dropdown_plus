import 'package:flutter/material.dart';

/// Fires [onLoadMore] when the user scrolls near the bottom of a dropdown list.
class DropdownPaginationScrollController extends ScrollController {
  DropdownPaginationScrollController({
    VoidCallback? onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.threshold = 80,
  }) : _onLoadMore = onLoadMore {
    addListener(_handleScroll);
  }

  VoidCallback? _onLoadMore;
  bool hasMore;
  bool isLoadingMore;
  final double threshold;

  set onLoadMore(VoidCallback? callback) => _onLoadMore = callback;

  void _handleScroll() {
    if (_onLoadMore == null || !hasMore || isLoadingMore) return;
    if (!hasClients) return;
    final position = this.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _onLoadMore!();
    }
  }
}

class DropdownLoadMoreFooter extends StatelessWidget {
  const DropdownLoadMoreFooter({
    required this.isLoading,
    super.key,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Builds a divider between dropdown list rows.
Widget dropdownItemDivider(Color color, {double indent = 12}) => Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: indent,
      color: color,
    );
