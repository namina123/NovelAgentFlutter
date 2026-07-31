import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

class ProjectStatusCard extends StatelessWidget {
  const ProjectStatusCard({
    super.key,
    required this.projectPath,
    required this.toolCoreStatus,
  });

  final String projectPath;
  final String toolCoreStatus;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目状态卡只承接路径和运行状态展示，不把项目动作按钮和文件树也混进来。
    final colors = context.novelThemeColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warmColor.withValues(alpha: 0.55),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: colors.warmStrongColor.withValues(alpha: 0.7),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '项目工作区',
            style: TextStyle(
              color: colors.mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            projectPath.trim().isEmpty ? '默认项目目录尚未选择。' : projectPath,
            style: TextStyle(
              color: colors.textColor,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (toolCoreStatus.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              toolCoreStatus,
              style: TextStyle(
                color: colors.lineStrongColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
