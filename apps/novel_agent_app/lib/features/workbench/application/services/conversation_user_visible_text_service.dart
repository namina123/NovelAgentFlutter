import '../models/workbench_primary_action_plan.dart';
import '../../presentation/models/primary_action_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';

class ConversationUserVisibleTextService {
  const ConversationUserVisibleTextService();

  String textForPrimaryAction(
    PrimaryActionViewData action,
    WorkbenchPrimaryActionPlan plan,
  ) {
    // 中文注释: 这里专门负责把内部动作计划映射成用户可见的话术，不参与真正的 prompt 组装。
    final title = action.title.trim();
    if (title.isEmpty) {
      return plan.message.trim().isEmpty ? '我选择了一个流程入口。' : plan.message;
    }
    return '我选择了“$title”';
  }

  String textForUserOption(UserOptionViewData option) {
    // 中文注释: 选项点击后的显示文本统一在这里生成，避免控制器写死某个按钮或流程名称。
    final label = option.label.trim();
    if (label.isNotEmpty) {
      return '我选择了“$label”';
    }
    final prompt = option.prompt.trim();
    return prompt.isEmpty ? '我做出了一个选择。' : prompt;
  }
}
