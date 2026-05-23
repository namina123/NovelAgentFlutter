import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFD9),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: const Color(0xFFD8C790),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '项目工作区',
            style: TextStyle(
              color: AppPalette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            projectPath.trim().isEmpty ? '默认项目目录尚未解析。' : projectPath,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            toolCoreStatus,
            style: const TextStyle(
              color: AppPalette.lineStrong,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
