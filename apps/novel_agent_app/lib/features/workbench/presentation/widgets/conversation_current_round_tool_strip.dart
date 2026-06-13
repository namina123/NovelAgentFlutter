import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/transcript_block_view_data.dart';
import 'transcript_block_renderer_registry.dart';

class ConversationCurrentRoundToolStrip extends StatelessWidget {
  const ConversationCurrentRoundToolStrip({
    super.key,
    required this.blocks,
    required this.rendererRegistry,
    required this.renderContext,
  });

  final List<TranscriptBlockViewData> blocks;
  final TranscriptBlockRendererRegistry rendererRegistry;
  final TranscriptBlockRenderContext renderContext;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(color: colors.lineColor.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colors.accentSoftColor.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 11,
                    color: colors.lineStrongColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '当前执行',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.18,
                    color: surface.mutedForegroundColor,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < blocks.length; index++) ...[
            if (index > 0) const SizedBox(height: 6),
            rendererRegistry.build(context, blocks[index], renderContext),
          ],
        ],
      ),
    );
  }
}
