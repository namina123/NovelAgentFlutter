import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';

class SettingsHeader extends StatefulWidget {
  const SettingsHeader({
    super.key,
    required this.onBackRequested,
    this.announcement = '',
  });

  final VoidCallback onBackRequested;
  /// 中文注释: 设置页瞬态反馈（保存成功/校验失败）。非空时在头部展示一条横幅，3.5s 后自动收起。
  final String announcement;

  @override
  State<SettingsHeader> createState() => _SettingsHeaderState();
}

class _SettingsHeaderState extends State<SettingsHeader> {
  Timer? _hideTimer;
  bool _visible = false;
  // 中文注释: initState 时若 announcement 非空，记为"已展示过"，避免用户离开设置页再回来时
  // 把上一次的陈旧"保存成功/失败"横幅再次弹出（State 重建后 _lastShown 会归空）。
  late String _lastShown = widget.announcement.trim();

  @override
  void didUpdateWidget(covariant SettingsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final message = widget.announcement;
    if (message.trim().isNotEmpty && message != _lastShown) {
      _lastShown = message;
      _visible = true;
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _visible = false;
            // 中文注释: 收起后清掉去重 key，这样连续两次相同消息（如重复保存）也能再次弹出。
            _lastShown = '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 设置页头部独立出来，后续扩展搜索、说明或导出按钮时不会继续挤大整页文件。
    final surface = context.novelThemeSurfaces.panel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        final titleBlock = Column(
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
        );
        final backButton = ActionButton(
          label: '返回工作台',
          labelMaxLines: 2,
          icon: Icons.arrow_back_rounded,
          tone: ActionButtonTone.neutral,
          onPressed: widget.onBackRequested,
        );

        final headerRow = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [backButton, const SizedBox(height: 12), titleBlock],
              )
            : Row(
                children: [
                  backButton,
                  const SizedBox(width: 14),
                  Expanded(child: titleBlock),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerRow,
            // 中文注释: AnimatedSize/AnimatedSwitcher 让反馈横幅平滑出现/消失，不顶撞布局。
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _visible && widget.announcement.trim().isNotEmpty
                  ? Padding(
                      key: ValueKey(widget.announcement),
                      padding: const EdgeInsets.only(top: 12),
                      child: _AnnouncementBanner(
                        message: widget.announcement,
                        onDismiss: () => setState(() => _visible = false),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 含"失败/请先/错误"等判定为警示，否则为成功。中文无大小写，统一用 message.contains。
    final isError = message.contains('失败') ||
        message.contains('错误') ||
        message.contains('请先') ||
        message.contains('请选择') ||
        message.contains('请填写');
    final colorScheme = Theme.of(context).colorScheme;
    final fg = isError ? colorScheme.error : colorScheme.primary;
    final bg = fg.withValues(alpha: 0.12);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onDismiss,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
