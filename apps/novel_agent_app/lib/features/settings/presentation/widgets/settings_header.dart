import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.onBackRequested});

  final VoidCallback onBackRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 设置页头部独立出来，后续扩展搜索、说明或导出按钮时不会继续挤大整页文件。
    final surface = context.novelThemeSurfaces.panel;
    return Row(
      children: [
        ActionButton(
          label: '返回工作台',
          icon: Icons.arrow_back_rounded,
          tone: ActionButtonTone.neutral,
          onPressed: onBackRequested,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '设置',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '接口、模型、上下文、主题与工具策略都会直接保存到本地设置。',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: surface.mutedForegroundColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
