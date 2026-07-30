import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/horizontal_overflow_scrollbar.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/task_center_view_data.dart';

class TaskCenterDiagnosticsPanel extends StatelessWidget {
  const TaskCenterDiagnosticsPanel({
    super.key,
    required this.chainMarkdown,
    required this.longTaskRuns,
    required this.taskQueueRuns,
    required this.longTaskRunLog,
    required this.taskQueueRunLog,
    required this.onLongTaskRunSelected,
    required this.onTaskQueueRunSelected,
  });

  final String chainMarkdown;
  final List<TaskCenterRunItemViewData> longTaskRuns;
  final List<TaskCenterRunItemViewData> taskQueueRuns;
  final String longTaskRunLog;
  final String taskQueueRunLog;
  final ValueChanged<String> onLongTaskRunSelected;
  final ValueChanged<String> onTaskQueueRunSelected;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      padding: const EdgeInsets.all(12),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: '链路与运行记录'),
            const SizedBox(height: 8),
            HorizontalOverflowScrollbar(
              builder: (context, controller) => TabBar(
                controller: DefaultTabController.of(context),
                isScrollable: true,
                tabs: const [
                  Tab(text: '链路树'),
                  Tab(text: '长任务运行'),
                  Tab(text: '队列日志'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: [
                  _MarkdownBody(
                    content: chainMarkdown.trim().isEmpty
                        ? '当前没有可展示的链路信息。'
                        : chainMarkdown,
                  ),
                  _RunLogView(
                    runs: longTaskRuns,
                    content: longTaskRunLog.trim().isEmpty
                        ? '当前没有长任务运行记录。'
                        : longTaskRunLog,
                    summaryTitle: '长任务现场',
                    onSelected: onLongTaskRunSelected,
                  ),
                  _RunLogView(
                    runs: taskQueueRuns,
                    content: taskQueueRunLog.trim().isEmpty
                        ? '当前没有受控连续运行记录。'
                        : taskQueueRunLog,
                    summaryTitle: '队列现场',
                    onSelected: onTaskQueueRunSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunLogView extends StatelessWidget {
  const _RunLogView({
    required this.runs,
    required this.content,
    required this.summaryTitle,
    required this.onSelected,
  });

  final List<TaskCenterRunItemViewData> runs;
  final String content;
  final String summaryTitle;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 颜色走主题 token(novelThemeColors)，亮色主题下不再用深色专用的 AppPalette
    // 导致白字白底不可读。selected 用 accentSoft 强调，未选中用面板底色。
    final colors = context.novelThemeColors;
    final runList = SizedBox(
      width: 220,
      child: ListView.builder(
        itemCount: runs.length,
        itemBuilder: (context, index) {
          final item = runs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onSelected(item.relativePath),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.isSelected
                      ? colors.accentSoftColor
                      : colors.panelBackground,
                  border: Border.all(
                    color: item.isSelected
                        ? colors.lineStrongColor
                        : colors.lineColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.statusLabel.trim().isEmpty
                          ? item.title
                          : item.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.textColor,
                      ),
                    ),
                    if (item.phaseLabel.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.phaseLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.mutedTextColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (item.progressPercent > 0)
                          _RunStatChip(label: '${item.progressPercent}%'),
                        if (item.activeTaskTitle.trim().isNotEmpty)
                          _RunStatChip(label: item.activeTaskTitle),
                        if (item.isWaitingUser)
                          const _RunStatChip(label: '等待确认'),
                      ],
                    ),
                    if (item.updatedAt.trim().isNotEmpty ||
                        item.controlSummary.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (item.updatedAt.trim().isNotEmpty)
                            item.updatedAt.trim(),
                          if (item.controlSummary.trim().isNotEmpty)
                            item.controlSummary.trim(),
                        ].join('｜'),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colors.mutedTextColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RunSummaryStrip(
          title: summaryTitle,
          run: runs.isEmpty
              ? null
              : runs.firstWhere(
                  (item) => item.isSelected,
                  orElse: () => runs.first,
                ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _MarkdownBody(content: content)),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              SizedBox(height: 200, child: runList),
              const SizedBox(height: 12),
              Expanded(child: detail),
            ],
          );
        }
        return Row(
          children: [
            runList,
            const SizedBox(width: 12),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

class _RunSummaryStrip extends StatelessWidget {
  const _RunSummaryStrip({required this.title, required this.run});

  final String title;
  final TaskCenterRunItemViewData? run;

  @override
  Widget build(BuildContext context) {
    if (run == null) {
      return const SizedBox.shrink();
    }
    final colors = context.novelThemeColors;
    final parts = <String>[
      if (run!.phaseLabel.trim().isNotEmpty) run!.phaseLabel.trim(),
      if (run!.progressPercent > 0) '${run!.progressPercent}%',
      if (run!.activeTaskTitle.trim().isNotEmpty) run!.activeTaskTitle.trim(),
      if (run!.isWaitingUser) '等待确认',
      if (run!.controlSummary.trim().isNotEmpty) run!.controlSummary.trim(),
      if (run!.updatedAt.trim().isNotEmpty) run!.updatedAt.trim(),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: colors.lineColor),
        color: colors.panelBackground,
      ),
      child: Text(
        parts.isEmpty ? title : '$title｜${parts.join('｜')}',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: colors.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RunStatChip extends StatelessWidget {
  const _RunStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: colors.lineColor),
        color: colors.panelBackground,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: colors.textColor,
        ),
      ),
    );
  }
}

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 链路/日志是模型与 runtime 生成的 Markdown——用真正的 Markdown 渲染，
    // 不再把 ##、-、** 当字面文本展示。超长内容截断以防 flutter_markdown 卡顿。
    // 文字颜色用主题 textColor，不再硬编码 AppPalette.text(近白)——否则亮色主题下整段不可读。
    final colors = context.novelThemeColors;
    return SingleChildScrollView(
      child: MarkdownBody(
        data: _truncateForRender(content),
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(fontSize: 12.5, height: 1.55, color: colors.textColor),
          h2: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colors.textColor,
          ),
          h3: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textColor,
          ),
          listBullet: TextStyle(color: colors.textColor),
        ),
      ),
    );
  }
}

String _truncateForRender(String content, {int max = 8000}) {
  if (content.length <= max) {
    return content;
  }
  return '${content.substring(0, max)}\n\n...（内容过长，已截断 $max 字；完整内容请查看项目 tracking/ 下的原始文件。）';
}
