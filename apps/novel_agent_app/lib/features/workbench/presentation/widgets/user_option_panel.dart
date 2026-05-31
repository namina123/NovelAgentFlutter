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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '等待确认',
          style: TextStyle(
            color: colors.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
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
