import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/user_option_view_data.dart';
import 'user_option_tile.dart';

class UserOptionPanel extends StatelessWidget {
  const UserOptionPanel({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<UserOptionViewData> options;
  final ValueChanged<UserOptionViewData> onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 选项面板专门承接 AI 请求用户确认的分支，不与普通主动作列表混在一起。
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.novelThemeColors;
    final question = options.first.sourceQuestion.trim();
    // 中文注释: 权限闸和模型主动提问共用同一面板，靠标题/图标/颜色区分，避免用户把"授权工具执行"误当成普通聊天选项。
    final isPermissionApproval = options.any(
      (option) => option.permissionApprovalId.trim().isNotEmpty,
    );
    final accent =
        isPermissionApproval ? colors.warmStrongColor : colors.textColor;
    final title = isPermissionApproval ? '需要授权' : '等待确认';
    final subtitle =
        isPermissionApproval ? '工具执行需要你的许可后才能继续' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isPermissionApproval
                  ? Icons.lock_outline_rounded
                  : Icons.help_outline_rounded,
              size: 16,
              color: accent,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.mutedTextColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        if (question.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            question,
            style: TextStyle(
              color: colors.mutedTextColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: UserOptionTile(option: option, onSelected: onSelected),
          ),
        ),
      ],
    );
  }
}
