import 'package:flutter/material.dart';

/// 通用确认弹窗。返回 `true` 表示用户确认，`false`（或关闭弹窗）表示放弃。
///
/// 用于删除 / 重置 / 覆盖等不可恢复操作，避免"一点即删"。多处删除入口
/// （provider / 风格 / 伏笔 等）共用同一个交互，保持一致的二次确认。
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确认',
  String cancelLabel = '取消',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(dialogContext).colorScheme.errorContainer,
                    foregroundColor:
                        Theme.of(dialogContext).colorScheme.onErrorContainer,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
