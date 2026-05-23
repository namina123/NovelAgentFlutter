import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/workbench_view_data.dart';

class PrimaryActionList extends StatelessWidget {
  const PrimaryActionList({
    super.key,
    required this.actions,
    required this.actionHandler,
  });

  final List<PrimaryActionViewData> actions;
  final ConversationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 主操作列表只管渲染右侧工作流入口，不承接模型配置和发送区逻辑。
    return Column(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActionButton(
                label: action.title,
                expanded: true,
                onPressed: () {
                  // 中文注释: 主动作按钮只上传动作 id，工作流编排后续仍由外层控制器决定。
                  actionHandler.onPrimaryActionRequested(action.id);
                },
              ),
              const SizedBox(height: 6),
              Text(
                action.description,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5E6E74),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
