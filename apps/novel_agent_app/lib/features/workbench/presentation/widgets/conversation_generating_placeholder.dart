import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

/// 生成中的占位提示。
///
/// 提供「真在动」的进度感：旋转指示器 + 已耗时计数器，就近放一个「停止」按钮，
/// 让用户在长工具链里不必回到输入栏就能中断。
class ConversationGeneratingPlaceholder extends StatefulWidget {
  const ConversationGeneratingPlaceholder({super.key, this.onStopRequested});

  /// 可选的中断回调。传入时占位卡右侧露出「停止」按钮。
  final VoidCallback? onStopRequested;

  @override
  State<ConversationGeneratingPlaceholder> createState() =>
      _ConversationGeneratingPlaceholderState();
}

class _ConversationGeneratingPlaceholderState
    extends State<ConversationGeneratingPlaceholder> {
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds += 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$seconds 秒';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.92),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.92),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.accentSoftColor.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(5),
            ),
            child: SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accentColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '智能体正在生成回复',
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '已用 $_elapsedLabel · 输出会随工具执行与推理进度持续写入当前会话。',
                  style: TextStyle(
                    color: colors.mutedTextColor,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onStopRequested != null) ...[
            const SizedBox(width: 6),
            // 中文注释: 纯图标停止键（不放「停止」文字）——避免与输入栏的「停止」文字重复，
            // wr17 回归测试按 find.text('停止') 断言输入栏那一处恰好一个。
            Tooltip(
              message: '停止生成',
              child: TextButton(
                onPressed: widget.onStopRequested,
                style: TextButton.styleFrom(
                  foregroundColor: colors.dangerStrongColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Icon(
                  Icons.stop_rounded,
                  size: 16,
                  color: colors.dangerStrongColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
