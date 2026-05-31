import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../models/sub_agent_run_view_data.dart';

class SubAgentRunDetailView extends StatefulWidget {
  const SubAgentRunDetailView({
    super.key,
    required this.run,
    required this.onBack,
  });

  final SubAgentRunViewData run;
  final VoidCallback onBack;

  @override
  State<SubAgentRunDetailView> createState() => _SubAgentRunDetailViewState();
}

class _SubAgentRunDetailViewState extends State<SubAgentRunDetailView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final run = widget.run;
    return PanelSurface(
      role: PanelSurfaceRole.panel,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.lineColor,
                  width: AppChrome.borderWidth,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: '返回主会话',
                    onPressed: widget.onBack,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          run.agentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${run.status} · 工具 ${run.toolCount} 次',
                          style: TextStyle(
                            color: colors.mutedTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (run.task.trim().isNotEmpty)
                      _DetailSection(title: '委派任务', content: run.task),
                    if (run.summary.trim().isNotEmpty)
                      _DetailSection(title: '结果摘要', content: run.summary),
                    if (run.content.trim().isNotEmpty)
                      _DetailSection(title: '返回内容', content: run.content),
                    if (run.reasoning.trim().isNotEmpty)
                      _DetailSection(title: '推理摘要', content: run.reasoning),
                    if (run.events.isNotEmpty)
                      _EventSection(events: run.events),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.lineStrongColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            content.trim(),
            style: TextStyle(
              color: colors.textColor,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({required this.events});

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '协作轨迹',
            style: TextStyle(
              color: colors.lineStrongColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.fiber_manual_record_rounded,
                      size: 8,
                      color: colors.accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.trim(),
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
