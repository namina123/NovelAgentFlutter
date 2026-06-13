import 'package:novel_agent_core/novel_agent_core.dart';

import 'chapter_delivery_outcome_projection_service.dart';
import 'project_chaptered_writing_task_service.dart';
import 'project_context_activation_service.dart';
import 'project_reference_continuity_bridge_service.dart';
import 'workflow_runtime_task_semantics_service.dart';

class ProjectWorkflowRuntimeBridgeService {
  ProjectWorkflowRuntimeBridgeService({
    required ProjectContextActivationService contextActivationService,
    ProjectReferenceContinuityBridgeService? referenceContinuityBridgeService,
    ToolExposurePolicyService? toolExposurePolicyService,
    ToolSchemaBuilderService? toolSchemaBuilderService,
    ContinuousTaskToolExposureRuntimeResolverService?
    continuousTaskToolExposureRuntimeResolverService,
    ChapterDeliveryOutcomeProjectionService? chapterDeliveryOutcomeProjection,
    ProjectChapteredWritingTaskService? chapteredWritingTaskService,
    WorkflowRuntimeTaskSemanticsService? workflowRuntimeTaskSemanticsService,
    HostPlatform hostPlatform = HostPlatform.unknown,
  }) : _contextActivationService = contextActivationService,
       _referenceContinuityBridgeService =
           referenceContinuityBridgeService ??
           ProjectReferenceContinuityBridgeService(),
       _toolExposurePolicyService =
           toolExposurePolicyService ?? const ToolExposurePolicyService(),
       _toolSchemaBuilderService =
           toolSchemaBuilderService ?? ToolSchemaBuilderService(),
       _continuousTaskToolExposureRuntimeResolverService =
           continuousTaskToolExposureRuntimeResolverService ??
           const ContinuousTaskToolExposureRuntimeResolverService(),
       _chapterDeliveryOutcomeProjection =
           chapterDeliveryOutcomeProjection ??
           const ChapterDeliveryOutcomeProjectionService(),
       _chapteredWritingTaskService =
           chapteredWritingTaskService ??
           const ProjectChapteredWritingTaskService(),
       _workflowRuntimeTaskSemanticsService =
           workflowRuntimeTaskSemanticsService ??
           WorkflowRuntimeTaskSemanticsService(),
       _hostPlatform = hostPlatform;

  final ProjectContextActivationService _contextActivationService;
  final ProjectReferenceContinuityBridgeService
  _referenceContinuityBridgeService;
  final ToolExposurePolicyService _toolExposurePolicyService;
  final ToolSchemaBuilderService _toolSchemaBuilderService;
  final ContinuousTaskToolExposureRuntimeResolverService
  _continuousTaskToolExposureRuntimeResolverService;
  final ChapterDeliveryOutcomeProjectionService
  _chapterDeliveryOutcomeProjection;
  final ProjectChapteredWritingTaskService _chapteredWritingTaskService;
  final WorkflowRuntimeTaskSemanticsService
  _workflowRuntimeTaskSemanticsService;
  final HostPlatform _hostPlatform;

  Future<JsonMap> buildTaskBridge(
    ProjectDescriptor project,
    JsonMap task, {
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
  }) async {
    final runtimeTask = _workflowRuntimeTaskSemanticsService.taskForRuntime(
      task,
    );
    final taskType = ValueReaders.stringValue(
      runtimeTask['task_type'],
      'chapter',
    ).trim();
    final cleanTaskType = taskType.isEmpty ? 'chapter' : taskType;
    final chapterLabel = ValueReaders.stringValue(runtimeTask['chapter']);
    final chapteredWritingTask = _chapteredWritingTaskService
        .isChapteredWritingTask(
          taskType: cleanTaskType,
          chapterLabel: chapterLabel,
        );
    final activationReport = await _contextActivationService.buildReport(
      project: project,
      taskType: cleanTaskType,
      chapterLabel: chapterLabel,
      budgetChars: chapteredWritingTask ? 8000 : 6000,
      reservedOutputChars: 2000,
      maxFiles: chapteredWritingTask ? 16 : 12,
      pinnedRelativePaths: _pinnedRelativePaths(runtimeTask),
    );
    final referenceContinuityReport = await _referenceContinuityBridgeService
        .buildReport(project: project);
    final referenceContinuityContextMarkdown = _referenceContinuityBridgeService
        .buildContextMarkdown(referenceContinuityReport);
    final toolExposureResolution =
        _continuousTaskToolExposureRuntimeResolverService.resolve(
          candidateToolIds: const <String>[],
          selectedCollaborationGroup: selectedCollaborationGroup,
          runtimeContext: <String, Object?>{
            'task_type': cleanTaskType,
            'mode': ValueReaders.stringValue(runtimeTask['mode']),
            'runtime_baseline_id': ValueReaders.stringValue(
              ValueReaders.mapValue(
                runtimeTask['metadata'],
              )['runtime_baseline_id'],
            ),
            'task_family_id': ValueReaders.stringValue(
              ValueReaders.mapValue(runtimeTask['metadata'])['task_family_id'],
            ),
            'workflow_strategy_id': ValueReaders.stringValue(
              ValueReaders.mapValue(
                runtimeTask['metadata'],
              )['workflow_strategy_id'],
            ),
          },
          intent: 'workflow_task',
        );
    final workflowToolIds = _toolExposurePolicyService.filterExposedToolIds(
      toolExposureResolution.visibleToolIds,
      hostPlatform: _hostPlatform,
      projectType: project.projectType,
    );
    final filteredWorkflowToolIds = _filterWorkflowToolIdsForTask(
      workflowToolIds,
      runtimeTask,
    );
    final workflowToolSchemas = _toolSchemaBuilderService.buildOpenAiSchemas(
      filteredWorkflowToolIds,
    );
    return <String, Object?>{
      'activation_report': activationReport.toJson(),
      'reference_continuity_report': referenceContinuityReport,
      'reference_continuity_context_markdown':
          referenceContinuityContextMarkdown,
      'activation_context_markdown': _composeContextMarkdown(
        activationContextMarkdown: _activationContextMarkdown(activationReport),
        referenceContinuityContextMarkdown: referenceContinuityContextMarkdown,
      ),
      'workflow_tool_ids': filteredWorkflowToolIds,
      'workflow_tool_schemas': workflowToolSchemas,
      'workflow_tool_schema_names': workflowToolSchemas
          .map(
            (schema) => ValueReaders.stringValue(
              ValueReaders.mapValue(schema['function'])['name'],
            ),
          )
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false),
      'workflow_tool_exposure_resolution': toolExposureResolution.toJson(),
    };
  }

  List<String> _filterWorkflowToolIdsForTask(
    List<String> workflowToolIds,
    JsonMap runtimeTask,
  ) {
    if (!_shouldSuppressSetAgentTasks(runtimeTask)) {
      return workflowToolIds;
    }
    return workflowToolIds
        .where((toolId) => toolId != 'set_agent_tasks')
        .toList(growable: false);
  }

  bool _shouldSuppressSetAgentTasks(JsonMap runtimeTask) {
    final metadata = ValueReaders.mapValue(runtimeTask['metadata']);
    if (ValueReaders.stringValue(metadata['runtime_baseline_id']).trim() !=
        'continuous_autonomous') {
      return false;
    }
    final taskType = ValueReaders.stringValue(runtimeTask['task_type']).trim();
    if (taskType == 'chapter' ||
        taskType == 'summary' ||
        taskType == 'revision') {
      return true;
    }
    if (taskType != 'agent_task') {
      return false;
    }
    final stage = ValueReaders.stringValue(metadata['stage']).trim();
    return stage != 'planning';
  }

  JsonMap attachPreparationArtifacts(
    JsonMap execution,
    JsonMap bridge, {
    String activationReportPath = '',
  }) {
    final next = ValueReaders.deepCopyMap(execution);
    final activationReport = ValueReaders.mapValue(bridge['activation_report']);
    final referenceContinuityReport = ValueReaders.mapValue(
      bridge['reference_continuity_report'],
    );
    next['activation_report'] = activationReport;
    next['activation_report_summary'] = ValueReaders.stringValue(
      activationReport['summary'],
    );
    next['activation_context_markdown'] = ValueReaders.stringValue(
      bridge['activation_context_markdown'],
    );
    next['reference_continuity_report'] = referenceContinuityReport;
    next['reference_continuity_summary'] = ValueReaders.stringValue(
      referenceContinuityReport['summary'],
    );
    next['reference_continuity_context_markdown'] = ValueReaders.stringValue(
      bridge['reference_continuity_context_markdown'],
    );
    next['workflow_tool_ids'] = ValueReaders.stringList(
      bridge['workflow_tool_ids'],
    );
    next['workflow_tool_schema_names'] = ValueReaders.stringList(
      bridge['workflow_tool_schema_names'],
    );
    if (activationReportPath.trim().isNotEmpty) {
      next['activation_report_path'] = activationReportPath.trim();
    }
    return next;
  }

  JsonMap attachRunArtifacts(
    JsonMap execution, {
    required List<Object?> executedTools,
    required List<String> writtenPaths,
    required String draftPreview,
  }) {
    final next = ValueReaders.deepCopyMap(execution);
    final delivery = latestChapterDeliveryOutcome(executedTools);
    next['output_paths'] = resolveOutputPaths(
      executedTools: executedTools,
      writtenPaths: writtenPaths,
    );
    next['last_result_preview'] = draftPreview;
    next['updated_at'] = DateTime.now().toIso8601String();
    if (delivery.isNotEmpty) {
      next['chapter_delivery'] = delivery;
      next['chapter_delivery_outcome_status'] = ValueReaders.stringValue(
        delivery['outcome_status'],
      );
      next['chapter_delivery_state'] = ValueReaders.stringValue(
        delivery['delivery_state'],
      );
      next['chapter_delivery_path'] = ValueReaders.stringValue(
        delivery['chapter_path'],
      );
    }
    return next;
  }

  List<String> resolveOutputPaths({
    required List<Object?> executedTools,
    required List<String> writtenPaths,
  }) {
    final result = <String>[...writtenPaths];
    final delivery = latestChapterDeliveryOutcome(executedTools);
    final chapterPath = ValueReaders.stringValue(delivery['chapter_path']);
    if (chapterPath.trim().isNotEmpty && !result.contains(chapterPath)) {
      result.add(chapterPath);
    }
    return result;
  }

  JsonMap latestChapterDeliveryOutcome(List<Object?> executedTools) {
    return _chapterDeliveryOutcomeProjection.latestFromExecutedTools(
      executedTools,
    );
  }

  List<String> _pinnedRelativePaths(JsonMap task) {
    final result = <String>[];
    void addPaths(Object? value) {
      for (final path in ValueReaders.stringList(value)) {
        final normalized = path.trim().replaceAll('\\', '/');
        if (normalized.isNotEmpty && !result.contains(normalized)) {
          result.add(normalized);
        }
      }
    }

    addPaths(task['source_paths']);
    addPaths(
      ValueReaders.mapValue(task['metadata'])['persistent_context_paths'],
    );
    return result;
  }

  String _activationContextMarkdown(ContextActivationReport report) {
    final lines = <String>[
      '## Activation Report',
      '- summary: ${report.summary}',
    ];
    final selected = ValueReaders.mapList(
      report.metadata['selected_context_sections'],
    );
    final omitted = ValueReaders.mapList(
      report.metadata['omitted_context_sections'],
    );
    final truncated = ValueReaders.mapList(
      report.metadata['truncated_context_sections'],
    );
    final continuitySnapshot = _chapterContinuitySnapshot(selected);
    if (selected.isNotEmpty) {
      lines.add('- selected_context:');
      for (final item in selected.take(6)) {
        final title = ValueReaders.stringValue(item['title'], '未命名上下文');
        final targetPath = ValueReaders.stringValue(item['target_path']);
        final explanation = ValueReaders.stringValue(item['explanation']);
        lines.add(
          '  - $title${targetPath.trim().isEmpty ? '' : ' <$targetPath>'}: $explanation',
        );
      }
      if (continuitySnapshot.notes.isNotEmpty) {
        lines.add('- continuity_checkpoint:');
        for (final note in continuitySnapshot.notes) {
          lines.add('  - $note');
        }
      }
    }
    if (continuitySnapshot.guardLines.isNotEmpty) {
      lines.add('## Chapter Continuity Guard');
      for (final line in continuitySnapshot.guardLines) {
        lines.add('- $line');
      }
    }
    if (omitted.isNotEmpty) {
      lines.add('- omitted_count: ${omitted.length}');
    }
    if (truncated.isNotEmpty) {
      lines.add('- truncated_count: ${truncated.length}');
    }
    return lines.join('\n');
  }

  String _composeContextMarkdown({
    required String activationContextMarkdown,
    required String referenceContinuityContextMarkdown,
  }) {
    if (referenceContinuityContextMarkdown.trim().isEmpty) {
      return activationContextMarkdown;
    }
    if (activationContextMarkdown.trim().isEmpty) {
      return referenceContinuityContextMarkdown;
    }
    return '$activationContextMarkdown\n\n$referenceContinuityContextMarkdown';
  }

  _ChapterContinuitySnapshot _chapterContinuitySnapshot(
    List<JsonMap> selectedSections,
  ) {
    String nextChapterAnchor = '';
    String completedSummary = '';
    String settledLocation = '';
    String tailExcerpt = '';
    for (final section in selectedSections) {
      final selectedText = ValueReaders.stringValue(section['selected_text']);
      if (selectedText.trim().isEmpty) {
        continue;
      }
      nextChapterAnchor = _firstNonEmpty(
        nextChapterAnchor,
        _extractLineValue(selectedText, '下一章承接锚点（必须直接续上）：'),
        _extractLineValue(selectedText, '优先承接锚点：'),
      );
      completedSummary = _firstNonEmpty(
        completedSummary,
        _extractLineValue(selectedText, '- 上一章已完成剧情（不要重复重演）：'),
        _extractLineValue(selectedText, '- 上一章已完成剧情：'),
      );
      settledLocation = _firstNonEmpty(
        settledLocation,
        _extractLineValue(selectedText, '- 当前落点：'),
      );
      tailExcerpt = _firstNonEmpty(
        tailExcerpt,
        _extractLineValue(selectedText, '章末原文锚点：'),
      );
    }
    final notes = <String>[];
    final guardLines = <String>[];
    if (nextChapterAnchor.isNotEmpty) {
      notes.add('下一章必须直接承接：$nextChapterAnchor');
      guardLines.add('必须直接承接上一章章末锚点：$nextChapterAnchor');
    }
    if (completedSummary.isNotEmpty) {
      notes.add('上一章已完成，不要重演：$completedSummary');
      guardLines.add('上一章已完成剧情禁止重复重演：$completedSummary');
    }
    if (settledLocation.isNotEmpty) {
      notes.add('当前落点：$settledLocation');
      guardLines.add('沿用上一章已经落定的场景/位置：$settledLocation');
    }
    if (tailExcerpt.isNotEmpty) {
      notes.add('上一章章末原文锚点：$tailExcerpt');
      guardLines.add('如果交付摘要还不完整，就以这段章末原文状态为准直接续写：$tailExcerpt');
      guardLines.add('不要把这段章末原文里已经发生的动作、对话或到达重新写一遍，只写回应、结果或后续动作。');
    }
    if (notes.isEmpty) {
      return const _ChapterContinuitySnapshot();
    }
    notes.add('开篇先推进到新情节点；不要把上一章末尾已完成的动作、对话或到达重新播放一遍。');
    guardLines.add(
      '开篇先推进到新情节点，不要把上一章末尾已完成的动作、对话、到达或同一段铺垫重新播放一遍。',
    );
    guardLines.add(
      '如果上一章末尾已经敲门、开口、达成请求或进入某地，本章从回应、结果或后续动作继续，不要从同一动作重新起笔。',
    );
    return _ChapterContinuitySnapshot(
      notes: notes,
      guardLines: guardLines,
    );
  }

  String _extractLineValue(String text, String prefix) {
    for (final rawLine in text.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trim();
      if (!line.startsWith(prefix)) {
        continue;
      }
      return line.substring(prefix.length).trim();
    }
    return '';
  }

  String _firstNonEmpty(
    String current,
    String candidate, [
    String fallback = '',
  ]) {
    if (current.trim().isNotEmpty) {
      return current.trim();
    }
    if (candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
    return fallback.trim();
  }
}

class _ChapterContinuitySnapshot {
  const _ChapterContinuitySnapshot({
    this.notes = const <String>[],
    this.guardLines = const <String>[],
  });

  final List<String> notes;
  final List<String> guardLines;
}
