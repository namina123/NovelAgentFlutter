import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_transcript_lane_view_data.dart';
import '../models/conversation_timeline_snapshot.dart';
import '../services/conversation_timeline_auto_reveal_policy.dart';
import 'conversation_panel_style.dart';
import 'conversation_current_round_tool_strip.dart';
import 'transcript_block_renderer_registry.dart';

class ConversationTimeline extends StatefulWidget {
  const ConversationTimeline({
    super.key,
    required this.lanes,
    required this.renderContext,
    this.rendererRegistry = const TranscriptBlockRendererRegistry(),
  });

  final ConversationTranscriptLaneViewData lanes;
  final TranscriptBlockRenderContext renderContext;
  final TranscriptBlockRendererRegistry rendererRegistry;

  @override
  State<ConversationTimeline> createState() => _ConversationTimelineState();
}

class _ConversationTimelineState extends State<ConversationTimeline> {
  static const double _bottomAnchorThreshold = 72;

  final ScrollController _scrollController = ScrollController();
  final ConversationTimelineAutoRevealPolicy _autoRevealPolicy =
      const ConversationTimelineAutoRevealPolicy();

  late ConversationTimelineSnapshot _snapshot;
  bool _anchoredToLatest = true;

  @override
  void initState() {
    super.initState();
    _snapshot = _currentSnapshot();
    _scrollController.addListener(_handleScrollChanged);
  }

  @override
  void didUpdateWidget(covariant ConversationTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSnapshot = _currentSnapshot();
    if (_autoRevealPolicy.shouldAutoReveal(
      previous: _snapshot,
      current: nextSnapshot,
      anchoredToLatest: _anchoredToLatest,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealLatest());
    }
    _snapshot = nextSnapshot;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScrollChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话时间线只负责按 block 排列，不再自行理解 tool/choice/retry/sub-agent 等细节语义。
    final items = _buildItems();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final panelSurface = context.novelThemeSurfaces.panel;
    final panelStyle = ConversationPanelStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelStyle.timelineBackgroundColor,
        border: Border.all(
          color: panelSurface.borderColor,
          width: panelSurface.borderWidth,
        ),
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: ListView.separated(
          controller: _scrollController,
          primary: false,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return KeyedSubtree(
              key: ValueKey(item.key),
              child: item.child,
            );
          },
        ),
      ),
    );
  }

  ConversationTimelineSnapshot _currentSnapshot() {
    return ConversationTimelineSnapshot.fromViewData(
      lanes: widget.lanes,
    );
  }

  List<_ConversationTimelineItem> _buildItems() {
    final items = <_ConversationTimelineItem>[];
    for (final block in widget.lanes.stableHistoryBlocks) {
      items.add(
        _ConversationTimelineItem(
          key: 'stable_${block.id}',
          child: widget.rendererRegistry.build(
            context,
            block,
            widget.renderContext,
          ),
        ),
      );
    }
    if (widget.lanes.currentRoundToolBlocks.isNotEmpty) {
      items.add(
        _ConversationTimelineItem(
          key: 'current_round_tool_strip',
          child: ConversationCurrentRoundToolStrip(
            blocks: widget.lanes.currentRoundToolBlocks,
            rendererRegistry: widget.rendererRegistry,
            renderContext: widget.renderContext,
          ),
        ),
      );
    }
    for (final block in widget.lanes.streamingAppendixBlocks) {
      items.add(
        _ConversationTimelineItem(
          key: 'streaming_${block.id}',
          child: widget.rendererRegistry.build(
            context,
            block,
            widget.renderContext,
          ),
        ),
      );
    }
    for (final block in widget.lanes.footerBlocks) {
      items.add(
        _ConversationTimelineItem(
          key: 'footer_${block.id}',
          child: widget.rendererRegistry.build(
            context,
            block,
            widget.renderContext,
          ),
        ),
      );
    }
    return items;
  }

  void _handleScrollChanged() {
    _anchoredToLatest = _isNearBottom();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= _bottomAnchorThreshold;
  }

  void _revealLatest() {
    if (!_scrollController.hasClients) {
      return;
    }
    final target = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(target);
  }
}

class _ConversationTimelineItem {
  const _ConversationTimelineItem({
    required this.key,
    required this.child,
  });

  final String key;
  final Widget child;
}
