import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_group_selector_view_data.dart';

class ConversationPrimaryAgentBar extends StatelessWidget {
  const ConversationPrimaryAgentBar({super.key, required this.groupSelector});

  final ConversationGroupSelectorViewData groupSelector;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 主智能体条现在保持纯只读摘要职责，不再承接模型或 reasoning 配置。
    final surface = context.novelThemeSurfaces.inputDock;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(surface.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: _PrimaryAgentSummary(groupSelector: groupSelector),
      ),
    );
  }
}

class _PrimaryAgentSummary extends StatelessWidget {
  const _PrimaryAgentSummary({required this.groupSelector});

  final ConversationGroupSelectorViewData groupSelector;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 主智能体摘要保持纯说明语义，不再伪装成和模型、智能体组同等级的选择入口。
    final colors = context.novelThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '主智能体',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.mutedTextColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          groupSelector.primaryAgentLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: colors.textColor,
          ),
        ),
        if (groupSelector.primaryAgentDescription.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            groupSelector.primaryAgentDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.25,
              color: colors.mutedTextColor,
            ),
          ),
        ],
      ],
    );
  }
}
