import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_context_activation_service.dart';

class ProjectWorkflowRuntimeBridgeService {
  ProjectWorkflowRuntimeBridgeService({
    required ProjectContextActivationService contextActivationService,
    ToolStrategyService? toolStrategyService,
    ToolExposurePolicyService? toolExposurePolicyService,
    ToolSchemaBuilderService? toolSchemaBuilderService,
    HostPlatform hostPlatform = HostPlatform.unknown,
  }) : _contextActivationService = contextActivationService,
       _toolStrategyService = toolStrategyService ?? ToolStrategyService(),
       _toolExposurePolicyService =
           toolExposurePolicyService ?? const ToolExposurePolicyService(),
       _toolSchemaBuilderService =
           toolSchemaBuilderService ?? ToolSchemaBuilderService(),
       _hostPlatform = hostPlatform;

  final ProjectContextActivationService _contextActivationService;
  final ToolStrategyService _toolStrategyService;
  final ToolExposurePolicyService _toolExposurePolicyService;
  final ToolSchemaBuilderService _toolSchemaBuilderService;
  final HostPlatform _hostPlatform;

  Future<JsonMap> buildTaskBridge(
    ProjectDescriptor project,
    JsonMap task,
  ) async {
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final activationReport = await _contextActivationService.buildReport(
      project: project,
      taskType: taskType.isEmpty ? 'chapter' : taskType,
      pinnedRelativePaths: _pinnedRelativePaths(task),
    );
    final workflowToolIds = _toolExposurePolicyService.filterExposedToolIds(
      _workflowToolIdsForTask(task),
      hostPlatform: _hostPlatform,
      projectType: project.projectType,
    );
    final workflowToolSchemas = _toolSchemaBuilderService.buildOpenAiSchemas(
      workflowToolIds,
    );
    return <String, Object?>{
      'activation_report': activationReport.toJson(),
      'activation_context_markdown': _activationContextMarkdown(
        activationReport,
      ),
      'workflow_tool_ids': workflowToolIds,
      'workflow_tool_schemas': workflowToolSchemas,
      'workflow_tool_schema_names': workflowToolSchemas
          .map(
            (schema) => ValueReaders.stringValue(
              ValueReaders.mapValue(schema['function'])['name'],
            ),
          )
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false),
    };
  }

  JsonMap attachPreparationArtifacts(
    JsonMap execution,
    JsonMap bridge, {
    String activationReportPath = '',
  }) {
    final next = ValueReaders.deepCopyMap(execution);
    final activationReport = ValueReaders.mapValue(bridge['activation_report']);
    next['activation_report'] = activationReport;
    next['activation_report_summary'] = ValueReaders.stringValue(
      activationReport['summary'],
    );
    next['activation_context_markdown'] = ValueReaders.stringValue(
      bridge['activation_context_markdown'],
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
    for (final rawTool in executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != 'submit_chapter_delivery') {
        continue;
      }
      final result = ValueReaders.mapValue(tool['result']);
      final outcome = ValueReaders.mapValue(result['domain_outcome']);
      final payload = ValueReaders.mapValue(outcome['outcome_payload']);
      if (payload.isEmpty) {
        continue;
      }
      return <String, Object?>{
        'tool_name': 'submit_chapter_delivery',
        'outcome_status': ValueReaders.stringValue(
          outcome['outcome_status'],
          ValueReaders.stringValue(result['domain_outcome_status']),
        ),
        'delivery_id': ValueReaders.stringValue(payload['delivery_id']),
        'chapter_path': ValueReaders.stringValue(payload['chapter_path']),
        'delivery_state': ValueReaders.stringValue(payload['delivery_state']),
        'chapter_body_state': ValueReaders.stringValue(
          payload['chapter_body_state'],
        ),
        'sidecar_state': ValueReaders.stringValue(payload['sidecar_state']),
        'state_result': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(payload['state_result']),
        ),
      };
    }
    return const <String, Object?>{};
  }

  List<String> _workflowToolIdsForTask(JsonMap task) {
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final base = _toolStrategyService.enabledToolIds(
      _toolStrategyService.defaultSettings(),
    );
    final preferred = switch (taskType) {
      'review' => const <String>[
        'submit_semantic_review',
        'read_project_file',
        'list_project_files',
      ],
      'planning' => const <String>[
        'propose_narrative_profile_update',
        'request_profile_clarification',
        'read_project_file',
        'write_project_file',
      ],
      'revision' => const <String>[
        'submit_chapter_delivery',
        'read_project_file',
        'edit_project_file',
        'write_project_file',
      ],
      _ => const <String>[
        'submit_chapter_delivery',
        'read_project_file',
        'write_project_file',
        'edit_project_file',
      ],
    };
    final result = <String>[];
    for (final toolId in preferred) {
      if (base.contains(toolId) && !result.contains(toolId)) {
        result.add(toolId);
      }
    }
    for (final toolId in base) {
      if (!result.contains(toolId)) {
        result.add(toolId);
      }
    }
    return result;
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
    }
    if (omitted.isNotEmpty) {
      lines.add('- omitted_count: ${omitted.length}');
    }
    if (truncated.isNotEmpty) {
      lines.add('- truncated_count: ${truncated.length}');
    }
    return lines.join('\n');
  }
}
