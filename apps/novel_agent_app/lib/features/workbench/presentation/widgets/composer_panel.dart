import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';

class ComposerPanel extends StatelessWidget {
  const ComposerPanel({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onOptimizeRequested,
    required this.onToolOptionsRequested,
    required this.onSendRequested,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onOptimizeRequested;
  final VoidCallback onToolOptionsRequested;
  final ValueChanged<String> onSendRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 输入区拆成独立控件后，未来接流式输入状态或草稿缓存时不会侵入右栏其他模块。
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          minLines: 3,
          decoration: InputDecoration(hintText: hintText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: '优化',
                icon: Icons.auto_fix_high_outlined,
                tone: ActionButtonTone.warm,
                compact: true,
                onPressed: onOptimizeRequested,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                label: '工具',
                icon: Icons.tune_outlined,
                tone: ActionButtonTone.neutral,
                compact: true,
                onPressed: onToolOptionsRequested,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                label: '发送',
                icon: Icons.send_rounded,
                compact: true,
                onPressed: () {
                  // 中文注释: 发送动作只回传文本，不让输入区直接知道会话网关细节。
                  onSendRequested(controller.text.trim());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
