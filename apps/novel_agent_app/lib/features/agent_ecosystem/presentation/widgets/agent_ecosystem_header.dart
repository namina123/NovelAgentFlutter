import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';

class AgentEcosystemHeader extends StatelessWidget {
  const AgentEcosystemHeader({super.key, required this.onBackRequested});

  final VoidCallback onBackRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 生态页头部拆开后，后续增加搜索、帮助或导出也不会把整页文件继续撑大。
    return Row(
      children: [
        ActionButton(
          label: '返回工作台',
          icon: Icons.arrow_back_rounded,
          tone: ActionButtonTone.neutral,
          onPressed: onBackRequested,
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '智能体生态',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                '生态页只负责浏览、导入和新建入口，编辑细节后续按独立表单面板接入。',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5E6E74),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
