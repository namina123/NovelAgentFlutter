import 'package:flutter/material.dart';

import '../models/model_editor_view_data.dart';

/// 连接探测结果卡片：接口页（已移除连接测试）与模型页共用同一呈现。
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
    final foregroundColor = result.isSuccess
        ? const Color(0xFF23663A)
        : const Color(0xFF8A5A12);
    final backgroundColor = result.isSuccess
        ? const Color(0xFFE8F5EC)
        : const Color(0xFFFCF2DD);
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
          if (result.hideOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '需要隐藏的选项：${result.hideOptions.join('、')}',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
          if (result.fallbackNotAllowed) ...[
            const SizedBox(height: 8),
            Text(
              '当前组合不允许 fallback。',
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
