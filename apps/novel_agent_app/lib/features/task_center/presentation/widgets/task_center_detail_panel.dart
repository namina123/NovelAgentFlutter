import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';

class TaskCenterDetailPanel extends StatelessWidget {
  const TaskCenterDetailPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailBody,
    required this.resumeBriefBody,
    required this.queueSummary,
    required this.schedulerSummary,
    required this.guidanceRevisitBody,
  });

  final String title;
  final String subtitle;
  final String detailBody;
  final String resumeBriefBody;
  final String queueSummary;
  final String schedulerSummary;
  final String guidanceRevisitBody;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              // 中文注释: detail body 含 ## 队列预检 等 Markdown，按 Markdown 渲染而非字面文本；
              // 超长则截断，避免 flutter_markdown 渲染卡顿。
              child: MarkdownBody(
                selectable: true,
                data: () {
                  final joined = [
                    detailBody.trim(),
                    if (resumeBriefBody.trim().isNotEmpty)
                      '\n\n$resumeBriefBody',
                    if (queueSummary.trim().isNotEmpty)
                      '\n\n## 队列预检\n$queueSummary',
                    if (schedulerSummary.trim().isNotEmpty)
                      '\n\n## 调度摘要\n$schedulerSummary',
                    if (guidanceRevisitBody.trim().isNotEmpty)
                      '\n\n$guidanceRevisitBody',
                  ].join();
                  const max = 12000;
                  if (joined.length <= max) {
                    return joined;
                  }
                  return '${joined.substring(0, max)}\n\n...（内容过长，已截断；完整内容请到该任务的运行记录文件中查看。）';
                }(),
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                  // 中文注释: 正文颜色走主题 textColor，不再硬编码深色专用 AppPalette.text，
                  // 否则亮色主题下整段详情 Markdown 白字白底不可读。
                  p: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: context.novelThemeColors.textColor,
                  ),
                  h2: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.novelThemeColors.textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
