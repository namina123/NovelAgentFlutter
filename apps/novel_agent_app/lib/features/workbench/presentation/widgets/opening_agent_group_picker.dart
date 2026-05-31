import 'package:flutter/material.dart';

import '../models/opening_agent_group_option_view_data.dart';
import 'agent_group_option_card.dart';

class OpeningAgentGroupPicker extends StatelessWidget {
  const OpeningAgentGroupPicker({
    super.key,
    required this.options,
    required this.currentGroupDisplayName,
    required this.onSelected,
  });

  final List<OpeningAgentGroupOptionViewData> options;
  final String currentGroupDisplayName;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: group picker 只负责展示当前项目可选组，不承担不可用原因解释与持久化逻辑。
    final hasCurrent = currentGroupDisplayName.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasCurrent ? '当前默认组：$currentGroupDisplayName' : '请选择当前项目默认组',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: KeyedSubtree(
              key: ValueKey<String>('opening_group_${option.groupId}'),
              child: AgentGroupOptionCard(
                title: option.displayName,
                description: option.description,
                isCurrent: option.isCurrent,
                isSelectable: true,
                isDegraded: option.isDegraded,
                extraBadges: option.isStarterGroup
                    ? const <String>['内置开局']
                    : const <String>[],
                onPressed: () => onSelected(option.groupId),
              ),
            ),
          );
        }),
      ],
    );
  }
}
