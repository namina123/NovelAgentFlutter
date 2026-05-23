import 'package:flutter/material.dart';

import '../../../../../shared/widgets/section_heading.dart';
import '../../../../../shared/widgets/toolbar_icon_button.dart';

class ResourceManagerHeader extends StatelessWidget {
  const ResourceManagerHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSettingsPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 资源面板头部独立出来，后续即使项目状态区变动也不会挤进整块资源面板文件。
    return SectionHeading(
      title: title,
      subtitle: subtitle,
      trailing: ToolbarIconButton(
        icon: Icons.tune_rounded,
        tooltip: '模型与接口设置',
        tone: ToolbarIconTone.accent,
        onPressed: onSettingsPressed,
      ),
    );
  }
}
