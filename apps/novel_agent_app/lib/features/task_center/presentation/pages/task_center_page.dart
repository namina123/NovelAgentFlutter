import 'package:flutter/material.dart';

import '../../../../shared/theme/novel_theme_context.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
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
  late bool _enableChapterWordConstraints;
  late final TextEditingController _outlineController;
  late final TextEditingController _seedController;
  late final TextEditingController _chapterCountController;
  late final TextEditingController _checkpointController;
  late final TextEditingController _chapterWordTargetController;
  late final TextEditingController _chapterWordMinController;
  late final TextEditingController _chapterWordMaxController;
  late final TextEditingController _sampleChapterWordTargetController;
  late final TextEditingController _sampleChapterWordMinController;
  late final TextEditingController _sampleChapterWordMaxController;
  // 中文注释: 工作流创建表单的本地校验错误（数字字段解析失败），提交时填入并展示。
  String _formError = '';

  @override
  void initState() {
    super.initState();
    _mode = widget.viewData.defaultMode;
    final chapterLength = widget.viewData.defaultChapterLength;
    _enableChapterWordConstraints = chapterLength.enableChapterWordConstraints;
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
    _chapterWordTargetController = TextEditingController(
      text: chapterLength.chapterWordTarget.toString(),
    );
    _chapterWordMinController = TextEditingController(
      text: chapterLength.chapterWordMin.toString(),
    );
    _chapterWordMaxController = TextEditingController(
      text: chapterLength.chapterWordMax.toString(),
    );
    _sampleChapterWordTargetController = TextEditingController(
      text: chapterLength.sampleChapterWordTarget.toString(),
    );
    _sampleChapterWordMinController = TextEditingController(
      text: chapterLength.sampleChapterWordMin.toString(),
    );
    _sampleChapterWordMaxController = TextEditingController(
      text: chapterLength.sampleChapterWordMax.toString(),
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
    _chapterWordTargetController.dispose();
    _chapterWordMinController.dispose();
    _chapterWordMaxController.dispose();
    _sampleChapterWordTargetController.dispose();
    _sampleChapterWordMinController.dispose();
    _sampleChapterWordMaxController.dispose();
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
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: context.novelThemeColors.mutedTextColor,
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
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _enableChapterWordConstraints,
                  title: const Text('启用章节字数约束'),
                  subtitle: const Text('把字数目标作为长任务参数传入共享运行时。'),
                  onChanged: (value) {
                    setState(() {
                      _enableChapterWordConstraints = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      Expanded(
                        child: TextField(
                          controller: _chapterWordTargetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '正文章节目标（字）',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _chapterWordMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '正文章节最小（字）'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _chapterWordMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '正文章节最大（字）'),
                        ),
                      ),
                    ];
                    if (constraints.maxWidth < 520) {
                      return Column(children: fields);
                    }
                    return Row(children: fields);
                  },
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      Expanded(
                        child: TextField(
                          controller: _sampleChapterWordTargetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '样章目标（字）'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _sampleChapterWordMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '样章最小（字）'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _sampleChapterWordMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '样章最大（字）'),
                        ),
                      ),
                    ];
                    if (constraints.maxWidth < 520) {
                      return Column(children: fields);
                    }
                    return Row(children: fields);
                  },
                ),
                const SizedBox(height: 8),
                ActionButton(
                  label: '生成队列',
                  icon: Icons.playlist_add_rounded,
                  expanded: true,
                  disabled: !widget.viewData.longTaskCreationAvailable,
                  onPressed: _submitWorkflowCreate,
                ),
                if (!widget.viewData.longTaskCreationAvailable) ...[
                  const SizedBox(height: 8),
                  // 中文注释: 告诉用户为何"生成队列"置灰——只有长篇项目支持。
                  Text(
                    '仅长篇项目支持生成长篇自动化队列。',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: context.novelThemeColors.mutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_formError.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formError,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TaskCenterSharedActionsPanel(
                  groups: widget.viewData.actionGroups,
                  onActionRequested:
                      widget.actionHandler.onTaskCenterSharedActionRequested,
                ),
                const SizedBox(height: 16),
                const SectionHeading(title: '运行动作'),
                const SizedBox(height: 10),
                // 中文注释: 原 16 个动作挤在一个 Wrap，危险动作（回滚/取消）紧挨常规动作，
                // 极易误点。按语义分四组并加小标题，撤销/终止单独成组远离常规动作。
                _actionGroup('调度执行', <Widget>[
                  ActionButton(
                    label: '准备执行',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget
                        .actionHandler
                        .onTaskCenterPrepareExecutionRequested,
                  ),
                  ActionButton(
                    label: '执行一次',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget
                        .actionHandler
                        .onTaskCenterRunSelectedOnceRequested,
                  ),
                  ActionButton(
                    label: '下一任务',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed:
                        widget.actionHandler.onTaskCenterRunNextOnceRequested,
                  ),
                  ActionButton(
                    label: '连续运行',
                    compact: true,
                    tone: ActionButtonTone.warm,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed:
                        widget.actionHandler.onTaskCenterRunQueueRequested,
                  ),
                ]),
                const SizedBox(height: 14),
                _actionGroup('完成与后处理', <Widget>[
                  ActionButton(
                    label: '标记完成',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed:
                        widget.actionHandler.onTaskCenterMarkSucceededRequested,
                  ),
                  ActionButton(
                    label: '完成并下一条',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget
                        .actionHandler
                        .onTaskCenterCompleteAndRunNextRequested,
                  ),
                  ActionButton(
                    label: '后处理一次',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget
                        .actionHandler
                        .onTaskCenterPostprocessSelectedRequested,
                  ),
                  ActionButton(
                    label: '后处理下一条',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget
                        .actionHandler
                        .onTaskCenterPostprocessNextRequested,
                  ),
                  ActionButton(
                    label: '接受修复',
                    compact: true,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget
                        .actionHandler
                        .onTaskCenterAcceptRevisionRequested,
                  ),
                ]),
                const SizedBox(height: 14),
                _actionGroup('保存与流程控制', <Widget>[
                  ActionButton(
                    label: '生成计划',
                    compact: true,
                    tone: ActionButtonTone.neutral,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed:
                        widget.actionHandler.onTaskCenterSavePlanRequested,
                  ),
                  ActionButton(
                    label: '链路快照',
                    compact: true,
                    tone: ActionButtonTone.neutral,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget
                        .actionHandler
                        .onTaskCenterSaveChainSnapshotRequested,
                  ),
                  ActionButton(
                    label: '暂停',
                    compact: true,
                    tone: ActionButtonTone.neutral,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget.actionHandler.onTaskCenterPauseRequested,
                  ),
                  ActionButton(
                    label: '恢复',
                    compact: true,
                    tone: ActionButtonTone.neutral,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget.actionHandler.onTaskCenterResumeRequested,
                  ),
                  ActionButton(
                    label: '重试',
                    compact: true,
                    tone: ActionButtonTone.neutral,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: widget.actionHandler.onTaskCenterRetryRequested,
                  ),
                ]),
                const SizedBox(height: 14),
                _actionGroup('撤销与终止', <Widget>[
                  ActionButton(
                    label: '回滚修复',
                    compact: true,
                    tone: ActionButtonTone.danger,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: () async {
                      // 中文注释: 回滚修订不可逆，二次确认避免密集按钮区误点。
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: '回滚该任务的修复？',
                        message: '回滚后该任务的修订结果将被撤销，不可恢复。',
                        confirmLabel: '回滚',
                      );
                      if (confirmed) {
                        widget.actionHandler
                            .onTaskCenterRollbackRevisionRequested();
                      }
                    },
                  ),
                  ActionButton(
                    label: '取消',
                    compact: true,
                    tone: ActionButtonTone.danger,
                    disabled:
                        widget.viewData.commandInFlight ||
                        widget.viewData.tasks.isEmpty,
                    onPressed: () async {
                      // 中文注释: 取消当前任务不可逆，二次确认避免误点。
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: '取消该任务？',
                        message: '取消后该任务将终止并标记为已取消，不可恢复。',
                        confirmLabel: '取消任务',
                      );
                      if (confirmed) {
                        widget.actionHandler.onTaskCenterCancelRequested();
                      }
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 任务中心「运行动作」的分组容器：小标题 + 一排按钮。
  ///
  /// 原先 16 个动作挤在一个 Wrap 里，危险动作（回滚/取消）紧挨常规动作，极易误点。
  /// 按语义分组、给小标题，并把撤销/终止单独成组，降低误触。
  Widget _actionGroup(String label, List<Widget> children) {
    final colors = context.novelThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: colors.mutedTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
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
    // 中文注释: 数字字段解析失败时如实报错并阻止提交，不再静默回落默认值（用户输入"2.000/两百"会被吞）。
    final errors = <String>[];
    int parseField(
      TextEditingController controller,
      String label,
      int fallback,
    ) {
      final text = controller.text.trim();
      if (text.isEmpty) {
        return fallback;
      }
      final parsed = int.tryParse(text);
      if (parsed == null) {
        errors.add('$label 不是有效整数（当前 "$text"）');
        return fallback;
      }
      return parsed;
    }

    final chapterCount = parseField(_chapterCountController, '正文章节目标', 6);
    final checkpointInterval = parseField(_checkpointController, '检查点间隔', 3);
    final chapterWordTarget = parseField(
      _chapterWordTargetController,
      '正文章节目标（字）',
      2000,
    );
    final chapterWordMin = parseField(
      _chapterWordMinController,
      '正文章节最小（字）',
      1600,
    );
    final chapterWordMax = parseField(
      _chapterWordMaxController,
      '正文章节最大（字）',
      2600,
    );
    final sampleChapterWordTarget = parseField(
      _sampleChapterWordTargetController,
      '样章目标（字）',
      1800,
    );
    final sampleChapterWordMin = parseField(
      _sampleChapterWordMinController,
      '样章最小（字）',
      1400,
    );
    final sampleChapterWordMax = parseField(
      _sampleChapterWordMaxController,
      '样章最大（字）',
      2400,
    );
    if (errors.isNotEmpty) {
      setState(() => _formError = errors.join('；'));
      return;
    }
    if (_formError.isNotEmpty) {
      setState(() => _formError = '');
    }
    widget.actionHandler.onTaskCenterWorkflowCreateSubmitted(
      TaskWorkflowCreateRequestViewData(
        mode: _mode,
        outlinePath: _outlineController.text,
        seedPrompt: _seedController.text,
        chapterCount: chapterCount,
        checkpointInterval: checkpointInterval,
        chapterLength: TaskCenterChapterLengthConfigViewData(
          enableChapterWordConstraints: _enableChapterWordConstraints,
          chapterWordTarget: chapterWordTarget,
          chapterWordMin: chapterWordMin,
          chapterWordMax: chapterWordMax,
          sampleChapterWordTarget: sampleChapterWordTarget,
          sampleChapterWordMin: sampleChapterWordMin,
          sampleChapterWordMax: sampleChapterWordMax,
        ),
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
    // 中文注释: 颜色走主题 token——亮色主题下不再用深色专用 AppPalette 导致文字不可读。
    final colors = context.novelThemeColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: colors.lineColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baselineTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.textColor,
            ),
          ),
          if (runtimeModeLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              runtimeModeLabel,
              style: TextStyle(fontSize: 12, color: colors.mutedTextColor),
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
                        border: Border.all(color: colors.lineStrongColor),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textColor,
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
