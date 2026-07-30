import 'package:flutter/material.dart';

import '../models/model_editor_view_data.dart';

/// 连接探测结果卡片：仅模型页使用，渲染"接口+模型"真实配对的
/// 本地自检 + 联网探测合并结果。
///
/// 中文注释: 这里只负责把 [ProviderConnectionValidationResultViewData] 渲染成
/// 人话化的成功/失败卡片，不持有状态；调用方决定何时显示与隐藏。
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({
    super.key,
    required this.result,
  });

  final ProviderConnectionValidationResultViewData result;

  @override
  Widget build(BuildContext context) {
    final isEmpty = result.summary.trim().isEmpty &&
        result.details.isEmpty &&
        result.errors.isEmpty;
    if (isEmpty) {
      return const SizedBox.shrink();
    }
    // 中文注释: 配色跟随 colorScheme，避免深色主题下浅黄/浅绿背景与品牌色板冲突。
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        result.isSuccess ? colorScheme.primary : colorScheme.tertiary;
    final backgroundColor = result.isSuccess
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.tertiary.withValues(alpha: 0.14);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result.isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.summary,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
          for (final detail in result.details) ...[
            const SizedBox(height: 6),
            Text(
              '• $detail',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '错误：${result.errors.join('；')}',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // 中文注释: hideOptions/fallbackNotAllowed 是内部 API 模式路由信号，原文案
          // ("需要隐藏的选项：chat、responses" / "当前组合不允许 fallback。") 对普通用户是术语。
          // 合并成一句人话提示，指明去高级设置切换 API 模式。
          if (result.hideOptions.isNotEmpty || result.fallbackNotAllowed) ...[
            const SizedBox(height: 8),
            Text(
              '当前接口模板与所选 API 模式组合不完全兼容，建议到高级设置里切换 API 模式后再重试。',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '警告：${result.warnings.join('；')}',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
