import 'package:flutter/material.dart';

import '../../../../../shared/widgets/section_heading.dart';

class SettingsPlaceholderPanel extends StatelessWidget {
  const SettingsPlaceholderPanel({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 其他设置子页先落清晰占位，避免为了“看起来全”把假逻辑硬塞进设置层。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title: title, subtitle: description),
        const SizedBox(height: 22),
        const Expanded(
          child: Center(
            child: Text(
              '该配置子页的控件入口已预留，后续按独立子模块接入。',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5E6E74),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
