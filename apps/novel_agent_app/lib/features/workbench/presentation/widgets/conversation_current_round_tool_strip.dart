import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (index > 0) const SizedBox(height: 6),
          rendererRegistry.build(context, blocks[index], renderContext),
        ],
      ],
    );
  }
}
