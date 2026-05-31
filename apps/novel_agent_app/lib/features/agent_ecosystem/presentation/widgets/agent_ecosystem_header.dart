import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';

class AgentEcosystemHeader extends StatelessWidget {
  const AgentEcosystemHeader({super.key, required this.onBackRequested});

  final VoidCallback onBackRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 生态页头部拆开后，后续增加搜索、帮助或导出也不会把整页文件继续撑大。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ActionButton(
          label: '返回工作台',
          icon: Icons.arrow_back_rounded,
          tone: ActionButtonTone.neutral,
          compact: true,
          onPressed: onBackRequested,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '智能体生态',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
