import 'package:flutter/material.dart';

/// 中文注释: RAG 入库状态文案的统一展示：含降级标记时用警示色卡片突出，否则按普通正文呈现。
///
/// 降级标记覆盖上游真实文案——"关键词(检索)/向量化失败/仅写入元数据/未配置 embedding/退回"，
/// 而不是早期错配的"关键词匹配"。供"资料库嵌入式面板"与"知识库 RAG 工作区"两处复用，
/// 避免降级提示只在一处显眼、另一处被埋成普通正文（B10 修复后知识库工作区出现的回归）。
class RagStatusText extends StatelessWidget {
  const RagStatusText({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final text = status;
    final isDegraded = text.contains('关键词') ||
        text.contains('仅写入元数据') ||
        text.contains('向量化失败') ||
        text.contains('未配置向量化') ||
        text.contains('退回');
    if (isDegraded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}
