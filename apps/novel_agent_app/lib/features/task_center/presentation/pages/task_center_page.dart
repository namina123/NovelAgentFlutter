import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/section_heading.dart';
import '../../../../shared/widgets/workspace_page_header.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../contracts/task_center_action_handler.dart';
import '../models/task_center_view_data.dart';
import '../widgets/task_center_detail_panel.dart';
import '../widgets/task_center_diagnostics_panel.dart';
import '../widgets/task_center_shared_actions_panel.dart';
import '../widgets/task_center_task_list_panel.dart';

class TaskCenterPage extends StatefulWidget {
  const TaskCenterPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final TaskCenterViewData viewData;
  final TaskCenterActionHandler actionHandler;

  @override
  State<TaskCenterPage> createState() => _TaskCenterPageState();
}

class _TaskCenterPageState extends State<TaskCenterPage> {
  late String _mode;
  late final TextEditingController _outlineController;
  late final TextEditingController _seedController;
  late final TextEditingController _chapterCountController;
  late final TextEditingController _checkpointController;

  @override
  void initState() {
    super.initState();
    _mode = widget.viewData.defaultMode;
    _outlineController = TextEditingController(
      text: widget.viewData.defaultOutlinePath,
    );
    _seedController = TextEditingController(
      text: widget.viewData.defaultSeedPrompt,
    );
    _chapterCountController = TextEditingController(
      text: widget.viewData.defaultChapterCount.toString(),
    );
    _checkpointController = TextEditingController(
      text: widget.viewData.defaultCheckpointInterval.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant TaskCenterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData.defaultMode != widget.viewData.defaultMode &&
        widget.viewData.defaultMode.trim().isNotEmpty) {
      _mode = widget.viewData.defaultMode;
    }
  }

  @override
  void dispose() {
    _outlineController.dispose();
    _seedController.dispose();
    _chapterCountController.dispose();
    _checkpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedTask();
    return WorkspacePageScaffold(
      header: WorkspacePageHeader(
        title: widget.viewData.title,
        subtitle: widget.viewData.intro,
        onBackRequested: widget.actionHandler.onTaskCenterBackRequested,
        actions: [
          ActionButton(
            label: '刷新',
            icon: Icons.refresh_rounded,
            tone: ActionButtonTone.neutral,
            compact: true,
            onPressed: widget.actionHandler.onTaskCenterRefreshRequested,
          ),
        ],
      ),
      headerBottom: Text(
        widget.viewData.help,
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AppPalette.mutedText,
        ),
      ),
      statusText: widget.viewData.status,
      body: WorkspacePaneLayout(
        breakpoint: 1420,
        leadingPaneWidth: 340,
        trailingPaneWidth: 420,
        leadingCompactHeight: 260,
        trailingCompactHeight: 340,
        leadingPane: TaskCenterTaskListPanel(
          tasks: widget.viewData.tasks,
          onTaskSelected: widget.actionHandler.onTaskCenterTaskSelected,
          onTaskOpened: widget.actionHandler.onTaskCenterTaskOpened,
        ),
        mainPane: Column(
          children: [
            Expanded(
              flex: 5,
              child: TaskCenterDetailPanel(
                title: selected?.title ?? '任务详情',
                subtitle: selected?.relativePath ?? '未选中任务',
                detailBody: widget.viewData.detailBody,
                resumeBriefBody: widget.viewData.resumeBriefBody,
                queueSummary: widget.viewData.queueSummary,
                schedulerSummary: widget.viewData.schedulerSummary,
                guidanceRevisitBody: widget.viewData.guidanceRevisitBody,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: TaskCenterDiagnosticsPanel(
                chainMarkdown: widget.viewData.chainMarkdown,
                longTaskRuns: widget.viewData.longTaskRuns,
                taskQueueRuns: widget.viewData.taskQueueRuns,
                longTaskRunLog: widget.viewData.longTaskRunLog,
                taskQueueRunLog: widget.viewData.taskQueueRunLog,
                onLongTaskRunSelected:
                    widget.actionHandler.onTaskCenterLongTaskRunSelected,
                onTaskQueueRunSelected:
                    widget.actionHandler.onTaskCenterTaskQueueRunSelected,
              ),
            ),
          ],
        ),
        trailingPane: PanelSurface(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(title: '长任务开局'),
                const SizedBox(height: 10),
                if (widget.viewData.runtimeBaselineTitle.trim().isNotEmpty) ...[
                  _RuntimePresetCard(
                    baselineTitle: widget.viewData.runtimeBaselineTitle,
                    runtimeModeLabel: widget.viewData.runtimeModeLabel,
                    policyBadges: widget.viewData.runtimePolicyBadges,
                  ),
                  const SizedBox(height: 10),
                ],
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('task-mode-$_mode'),
                  initialValue: _mode.isEmpty ? null : _mode,
                  decoration: const InputDecoration(labelText: '运行模式'),
                  items: widget.viewData.modeOptions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _mode = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _outlineController,
                  decoration: const InputDecoration(labelText: '大纲路径'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _seedController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: '创作种子/说明'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chapterCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '章节数'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _checkpointController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '检查点间隔'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ActionButton(
                  label: '生成队列',
                  icon: Icons.playlist_add_rounded,
                  expanded: true,
                  onPressed: _submitWorkflowCreate,
                ),
                const SizedBox(height: 16),
                TaskCenterSharedActionsPanel(
                  groups: widget.viewData.actionGroups,
                  onActionRequested:
                      widget.actionHandler.onTaskCenterSharedActionRequested,
                ),
                const SizedBox(height: 16),
                const SectionHeading(title: '运行动作'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionButton(
                      label: '生成计划',
                      compact: true,
                      tone: ActionButtonTone.neutral,
                      onPressed:
                          widget.actionHandler.onTaskCenterSavePlanRequested,
                    ),
                    ActionButton(
                      label: '链路快照',
                      compact: true,
                      tone: ActionButtonTone.neutral,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterSaveChainSnapshotRequested,
                    ),
                    ActionButton(
                      label: '准备执行',
                      compact: true,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterPrepareExecutionRequested,
                    ),
                    ActionButton(
                      label: '执行一次',
                      compact: true,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterRunSelectedOnceRequested,
                    ),
                    ActionButton(
                      label: '下一任务',
                      compact: true,
                      onPressed:
                          widget.actionHandler.onTaskCenterRunNextOnceRequested,
                    ),
                    ActionButton(
                      label: '连续运行',
                      compact: true,
                      tone: ActionButtonTone.warm,
                      onPressed:
                          widget.actionHandler.onTaskCenterRunQueueRequested,
                    ),
                    ActionButton(
                      label: '后处理一次',
                      compact: true,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterPostprocessSelectedRequested,
                    ),
                    ActionButton(
                      label: '后处理下一条',
                      compact: true,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterPostprocessNextRequested,
                    ),
                    ActionButton(
                      label: '标记完成',
                      compact: true,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterMarkSucceededRequested,
                    ),
                    ActionButton(
                      label: '完成并下一条',
                      compact: true,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterCompleteAndRunNextRequested,
                    ),
                    ActionButton(
                      label: '接受修复',
                      compact: true,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterAcceptRevisionRequested,
                    ),
                    ActionButton(
                      label: '回滚修复',
                      compact: true,
                      tone: ActionButtonTone.danger,
                      onPressed: widget
                          .actionHandler
                          .onTaskCenterRollbackRevisionRequested,
                    ),
                    ActionButton(
                      label: '暂停',
                      compact: true,
                      tone: ActionButtonTone.neutral,
                      onPressed:
                          widget.actionHandler.onTaskCenterPauseRequested,
                    ),
                    ActionButton(
                      label: '恢复',
                      compact: true,
                      tone: ActionButtonTone.neutral,
                      onPressed:
                          widget.actionHandler.onTaskCenterResumeRequested,
                    ),
                    ActionButton(
                      label: '重试',
                      compact: true,
                      tone: ActionButtonTone.neutral,
                      onPressed:
                          widget.actionHandler.onTaskCenterRetryRequested,
                    ),
                    ActionButton(
                      label: '取消',
                      compact: true,
                      tone: ActionButtonTone.danger,
                      onPressed:
                          widget.actionHandler.onTaskCenterCancelRequested,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TaskCenterTaskItemViewData? _selectedTask() {
    for (final item in widget.viewData.tasks) {
      if (item.isSelected) {
        return item;
      }
    }
    return widget.viewData.tasks.isEmpty ? null : widget.viewData.tasks.first;
  }

  void _submitWorkflowCreate() {
    widget.actionHandler.onTaskCenterWorkflowCreateSubmitted(
      TaskWorkflowCreateRequestViewData(
        mode: _mode,
        outlinePath: _outlineController.text,
        seedPrompt: _seedController.text,
        chapterCount: int.tryParse(_chapterCountController.text.trim()) ?? 6,
        checkpointInterval:
            int.tryParse(_checkpointController.text.trim()) ?? 3,
      ),
    );
  }
}

class _RuntimePresetCard extends StatelessWidget {
  const _RuntimePresetCard({
    required this.baselineTitle,
    required this.runtimeModeLabel,
    required this.policyBadges,
  });

  final String baselineTitle;
  final String runtimeModeLabel;
  final List<String> policyBadges;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: AppPalette.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baselineTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppPalette.text,
            ),
          ),
          if (runtimeModeLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              runtimeModeLabel,
              style: const TextStyle(fontSize: 12, color: AppPalette.mutedText),
            ),
          ],
          if (policyBadges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: policyBadges
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppPalette.lineStrong),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.text,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}
