import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

typedef SmartListItemBuilder<T> =
    Widget Function(BuildContext context, T item, int index);

class SmartList<T> extends StatefulWidget {
  const SmartList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.pageSize = 20,
    this.gutter = 10,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.loading = false,
    this.emptyText,
    this.loadingText,
    this.nomoreText,
    this.reloadKey,
  });

  final List<T> items;
  final SmartListItemBuilder<T> itemBuilder;
  final Future<void> Function()? onRefresh;
  final int pageSize;
  final double gutter;
  final EdgeInsets padding;
  final bool loading;
  final String? emptyText;
  final String? loadingText;
  final String? nomoreText;

  // Change this value to force resetting list pagination state.
  final Object? reloadKey;

  @override
  State<SmartList<T>> createState() => _SmartListState<T>();
}

class _SmartListState<T> extends State<SmartList<T>> {
  late final ScrollController _scrollController;
  int _visibleCount = 0;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _resetVisibleCount();
  }

  @override
  void didUpdateWidget(covariant SmartList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemsChanged = !identical(oldWidget.items, widget.items);
    final reloadKeyChanged = oldWidget.reloadKey != widget.reloadKey;
    if (itemsChanged || reloadKeyChanged) {
      _resetVisibleCount();
    } else if (_visibleCount > widget.items.length) {
      _visibleCount = widget.items.length;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final emptyText = widget.emptyText ?? l10n?.smartListEmpty ?? 'No data';
    final loadingText =
        widget.loadingText ?? l10n?.smartListLoading ?? 'Loading...';
    final nomoreText =
        widget.nomoreText ?? l10n?.smartListNoMore ?? 'No more data';

    if (widget.loading && widget.items.isEmpty) {
      return Center(child: Text(loadingText));
    }

    if (widget.items.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final visibleItems = widget.items
        .take(_visibleCount)
        .toList(growable: false);
    final hasMore = _visibleCount < widget.items.length;

    final list = ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: visibleItems.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: widget.gutter),
      itemBuilder: (context, index) {
        if (index < visibleItems.length) {
          return widget.itemBuilder(context, visibleItems[index], index);
        }

        if (_loadingMore) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text(loadingText)),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text(hasMore ? loadingText : nomoreText)),
        );
      },
    );

    if (widget.onRefresh == null) return list;

    return RefreshIndicator(onRefresh: widget.onRefresh!, child: list);
  }

  void _resetVisibleCount() {
    _visibleCount = widget.items.length < widget.pageSize
        ? widget.items.length
        : widget.pageSize;
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final shouldLoad = position.pixels >= position.maxScrollExtent - 120;
    if (!shouldLoad) return;
    if (_visibleCount >= widget.items.length) return;

    setState(() => _loadingMore = true);

    // Keep local pagination smooth and predictable for list-heavy screens.
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() {
        _visibleCount = (_visibleCount + widget.pageSize).clamp(
          0,
          widget.items.length,
        );
        _loadingMore = false;
      });
    });
  }
}
