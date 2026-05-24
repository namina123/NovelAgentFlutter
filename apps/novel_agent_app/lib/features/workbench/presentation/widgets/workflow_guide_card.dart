import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';

class WorkflowGuideCard extends StatelessWidget {
  const WorkflowGuideCard({
    super.key,
    required this.title,
    required this.description,
    required this.onSettingsRequested,
  });

  final String title;
  final String description;
  final VoidCallback onSettingsRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工作流引导卡独立后，未来切换不同项目体验 profile 时只需替换这个信息组件。
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: AppPalette.line,
          width: AppChrome.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppPalette.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            ActionButton(
              label: '工作台设置',
              expanded: true,
              tone: ActionButtonTone.neutral,
              icon: Icons.tune_outlined,
              compact: true,
              onPressed: onSettingsRequested,
            ),
          ],
        ),
      ),
    );
  }
}
