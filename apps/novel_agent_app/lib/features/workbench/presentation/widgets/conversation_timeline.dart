import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
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
  bool _initialRevealScheduled = false;

  @override
  void initState() {
    super.initState();
    _snapshot = _currentSnapshot();
    _scrollController.addListener(_handleScrollChanged);
    _scheduleInitialReveal();
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
    final items = _buildItems();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final panelSurface = context.novelThemeSurfaces.panel;
    final panelStyle = ConversationPanelStyle.of(context);
    final colors = context.novelThemeColors;
    final isLive =
        widget.lanes.currentRoundToolBlocks.isNotEmpty ||
        widget.lanes.streamingAppendixBlocks.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelStyle.timelineBackgroundColor.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(panelStyle.sectionRadius),
        border: Border.all(
          color: panelSurface.borderColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: panelStyle.inset(bottom: -1),
            child: Row(
              children: [
                Icon(
                  Icons.subject_rounded,
                  size: 13,
                  color: colors.mutedTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '会话记录',
                  style: TextStyle(
                    color: panelSurface.foregroundColor,
                    fontSize: panelStyle.compactLabelFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accentSoftColor.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '处理中',
                      style: TextStyle(
                        color: colors.lineStrongColor,
                        fontSize: panelStyle.metaFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: AppChrome.borderWidth,
            color: panelSurface.borderColor.withValues(alpha: 0.08),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: false,
              child: ListView.separated(
                controller: _scrollController,
                primary: false,
                padding: EdgeInsets.fromLTRB(
                  panelStyle.bandPadding.left,
                  panelStyle.bandPadding.top + 1,
                  panelStyle.bandPadding.right,
                  panelStyle.bandPadding.bottom + 10,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: panelStyle.bodyGap + 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return KeyedSubtree(
                    key: ValueKey(item.key),
                    child: item.child,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  ConversationTimelineSnapshot _currentSnapshot() {
    return ConversationTimelineSnapshot.fromViewData(lanes: widget.lanes);
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

  void _scheduleInitialReveal() {
    if (_initialRevealScheduled || _snapshot.blockCount <= 0) {
      return;
    }
    _initialRevealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealLatest());
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
  const _ConversationTimelineItem({required this.key, required this.child});

  final String key;
  final Widget child;
}
