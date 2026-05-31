import 'package:novel_agent_core/novel_agent_core.dart';

import '../packages/local_skill_group_catalog.dart';
import '../packages/local_skill_package_catalog.dart';
import '../storage/project_tree_order_service.dart';
import '../workflow/project_workflow_runtime_service.dart';
import '../host/desktop_process_runner.dart';
import 'project_file_edit_tool_executor.dart';
import 'project_file_read_tool_executor.dart';
import 'project_file_write_tool_executor.dart';
import 'project_agent_skill_tool_executor.dart';
import 'project_agent_skill_runtime_loadout_service.dart';
import 'project_gateway_process_service.dart';
import 'project_gateway_tool_executor.dart';
import 'project_long_task_tool_executor.dart';
import 'project_management_tool_executor.dart';
import 'project_structured_memory_tool_executor.dart';
import 'project_task_tool_executor.dart';
import 'project_tool_path_policy.dart';
import 'project_tool_relative_path_resolver.dart';
import 'project_tool_result_factory.dart';

class ProjectToolDispatcher implements ToolExecutionPort {
  ProjectToolDispatcher({
    required ProjectToolHostPort hostPort,
    LocalSkillPackageCatalog? skillPackageCatalog,
    LocalSkillGroupCatalog? skillGroupCatalog,
    ToolCallNormalizerService? toolCallNormalizerService,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
    ProjectTreeOrderService? treeOrderService,
    BuildModeGuidancePlanInputUseCase? buildModeGuidancePlanInputUseCase,
    ProjectWorkflowRuntimeService? workflowRuntimeService,
    ProjectLongTaskToolExecutor? longTaskToolExecutor,
    ProjectAgentSkillRuntimeLoadoutService? agentSkillRuntimeLoadoutService,
  }) : _toolCallNormalizerService =
           toolCallNormalizerService ?? ToolCallNormalizerService(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _relativePathResolver = ProjectToolRelativePathResolver(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
       ),
       _readToolExecutor = ProjectFileReadToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _writeToolExecutor = ProjectFileWriteToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _editToolExecutor = ProjectFileEditToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _structuredMemoryToolExecutor = ProjectStructuredMemoryToolExecutor(
         hostPort: hostPort,
         writeToolExecutor: ProjectFileWriteToolExecutor(
           hostPort: hostPort,
           pathPolicy: pathPolicy,
           resultFactory: resultFactory,
         ),
         pathPolicy: pathPolicy,
       ),
       _taskToolExecutor = ProjectTaskToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _managementToolExecutor = ProjectManagementToolExecutor(
         hostPort: hostPort,
         resultFactory: resultFactory,
         treeOrderService: treeOrderService,
         pathPolicy: pathPolicy,
         gatewayToolExecutor: ProjectGatewayToolExecutor(
           resultFactory: resultFactory,
           pathPolicy: pathPolicy,
           processService: ProjectGatewayProcessService(
             processRunner: DesktopProcessRunner(),
           ),
         ),
       ),
       _longTaskToolExecutor =
           longTaskToolExecutor ??
           (buildModeGuidancePlanInputUseCase != null &&
                   workflowRuntimeService != null
               ? ProjectLongTaskToolExecutor(
                   loadPlanInput: buildModeGuidancePlanInputUseCase.execute,
                   createLongTaskWorkflow:
                       workflowRuntimeService.createLongTaskWorkflow,
                   resultFactory: resultFactory,
                 )
               : null),
       _agentSkillToolExecutor = ProjectAgentSkillToolExecutor(
         skillPackageCatalog: skillPackageCatalog,
         skillGroupCatalog: skillGroupCatalog,
         resultFactory: resultFactory,
         runtimeLoadoutService: agentSkillRuntimeLoadoutService,
       );

  final ToolCallNormalizerService _toolCallNormalizerService;
  final ProjectToolResultFactory _resultFactory;
  final ProjectToolRelativePathResolver _relativePathResolver;
  final ProjectFileReadToolExecutor _readToolExecutor;
  final ProjectFileWriteToolExecutor _writeToolExecutor;
  final ProjectFileEditToolExecutor _editToolExecutor;
  final ProjectStructuredMemoryToolExecutor _structuredMemoryToolExecutor;
  final ProjectTaskToolExecutor _taskToolExecutor;
  final ProjectManagementToolExecutor _managementToolExecutor;
  final ProjectLongTaskToolExecutor? _longTaskToolExecutor;
  final ProjectAgentSkillToolExecutor _agentSkillToolExecutor;

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    // 中文注释: 调度器负责把显示层/模型层传来的路径折叠为英文项目相对路径，后续执行器只吃规范参数。
    final normalized = _toolCallNormalizerService.normalizeToolCall(toolCall);
    final toolName = ValueReaders.stringValue(normalized['name']).trim();
    final arguments = await _normalizeArguments(
      project: project,
      toolName: toolName,
      arguments: ValueReaders.mapValue(normalized['arguments']),
    );
    switch (toolName) {
      case 'list_project_files':
        return _readToolExecutor.listProjectFiles(project, arguments);
      case 'read_project_file':
        return _readToolExecutor.readProjectFile(project, arguments);
      case 'write_project_file':
        return _writeToolExecutor.writeProjectFile(project, arguments);
      case 'edit_project_file':
        return _editToolExecutor.editProjectFile(project, arguments);
      case 'delete_project_file':
        return _writeToolExecutor.deleteProjectFile(project, arguments);
      case 'get_project_file_info':
        return _readToolExecutor.getProjectFileInfo(project, arguments);
      case 'search_project_files':
        return _readToolExecutor.searchProjectFiles(project, arguments);
      case 'create_project_entry':
        return _writeToolExecutor.createProjectEntry(project, arguments);
      case 'move_project_file':
        return _writeToolExecutor.moveProjectFile(project, arguments);
      case 'rename_project_file':
        return _writeToolExecutor.renameProjectFile(project, arguments);
      case 'manipulate_project_file_lines':
        return _editToolExecutor.manipulateProjectFileLines(project, arguments);
      case 'list_history_sessions':
        return _readToolExecutor.listHistorySessions(project, arguments);
      case 'create_backup':
        return _writeToolExecutor.createBackup(project, arguments);
      case 'restore_backup':
        return _writeToolExecutor.restoreBackup(project, arguments);
      case 'update_world_state':
        return _structuredMemoryToolExecutor.updateWorldState(
          project,
          arguments,
        );
      case 'update_character_state':
        return _structuredMemoryToolExecutor.updateCharacterState(
          project,
          arguments,
        );
      case 'update_foreshadow_state':
        return _structuredMemoryToolExecutor.updateForeshadowState(
          project,
          arguments,
        );
      case 'update_timeline_state':
        return _structuredMemoryToolExecutor.updateTimelineState(
          project,
          arguments,
        );
      case 'update_relationship_state':
        return _structuredMemoryToolExecutor.updateRelationshipState(
          project,
          arguments,
        );
      case 'summarize_context':
        return _structuredMemoryToolExecutor.summarizeContext(
          project,
          arguments,
        );
      case 'run_continuity_check':
        return _structuredMemoryToolExecutor.runContinuityCheck(
          project,
          arguments,
        );
      case 'create_chapter_task':
        return _taskToolExecutor.createChapterTask(project, arguments);
      case 'mark_task_status':
        return _taskToolExecutor.markTaskStatus(project, arguments);
      case 'present_user_options':
        return _presentUserOptions(arguments);
      case 'start_long_task_run':
        if (_longTaskToolExecutor == null) {
          return _resultFactory.notExecuted('当前宿主尚未接入长任务启动执行器。');
        }
        return _longTaskToolExecutor.startLongTaskRun(project, arguments);
      case 'set_agent_tasks':
        return _taskToolExecutor.setAgentTasks(project, arguments);
      case 'load_agent_skill':
        return _agentSkillToolExecutor.loadAgentSkill(project, arguments);
      case 'call_sub_agent':
        return _resultFactory.notExecuted(
          'call_sub_agent 由上层 ToolExecutionService 直接接管；当前分发器只保留兜底结果。',
        );
      case 'rename_project':
        return _managementToolExecutor.renameProject(project, arguments);
      case 'reorder_project_file':
        return _managementToolExecutor.reorderProjectFile(project, arguments);
      case 'request_gateway_tool':
        return _managementToolExecutor.requestGatewayTool(project, arguments);
      default:
        return _resultFactory.error('Unknown project tool: $toolName');
    }
  }

  Future<JsonMap> _normalizeArguments({
    required ProjectDescriptor project,
    required String toolName,
    required JsonMap arguments,
  }) async {
    // 中文注释: 中文目录名、显示名匹配和旧输入兼容只允许存在于这一层，避免渗透进核心与各执行器。
    final normalized = ValueReaders.deepCopyMap(arguments);
    switch (toolName) {
      case 'list_project_files':
      case 'search_project_files':
      case 'reorder_project_file':
        normalized['relative_path'] = await _relativePathResolver
            .resolveScopePath(project, normalized);
        return normalized;
      case 'read_project_file':
      case 'get_project_file_info':
      case 'delete_project_file':
      case 'create_backup':
      case 'edit_project_file':
      case 'rename_project_file':
        normalized['relative_path'] = await _relativePathResolver
            .resolveFilePath(project, normalized);
        return normalized;
      case 'write_project_file':
      case 'create_project_entry':
        normalized['relative_path'] = _relativePathResolver
            .normalizeProjectPath(
              ValueReaders.stringValue(normalized['relative_path']),
            );
        return normalized;
      case 'move_project_file':
        normalized['relative_path'] = await _relativePathResolver
            .resolveFilePath(project, normalized);
        normalized['target_relative_path'] = _relativePathResolver
            .normalizeProjectPath(
              ValueReaders.stringValue(normalized['target_relative_path']),
            );
        return normalized;
      case 'manipulate_project_file_lines':
        normalized['relative_path'] = await _relativePathResolver
            .resolveFilePath(project, normalized);
        normalized['target_relative_path'] = _relativePathResolver
            .normalizeProjectPath(
              ValueReaders.stringValue(normalized['target_relative_path']),
            );
        return normalized;
      case 'restore_backup':
        normalized['backup_path'] = await _relativePathResolver.resolveFilePath(
          project,
          <String, Object?>{'relative_path': normalized['backup_path']},
          allowSessions: true,
        );
        normalized['target_path'] = _relativePathResolver.normalizeProjectPath(
          ValueReaders.stringValue(normalized['target_path']),
        );
        return normalized;
      case 'request_gateway_tool':
        final nestedArguments = ValueReaders.mapValue(normalized['arguments']);
        final outputPath = ValueReaders.stringValue(
          normalized['relative_path'],
          ValueReaders.stringValue(
            normalized['output_relative_path'],
            ValueReaders.stringValue(
              nestedArguments['relative_path'],
              ValueReaders.stringValue(nestedArguments['output_relative_path']),
            ),
          ),
        );
        final normalizedOutputPath = _relativePathResolver.normalizeProjectPath(
          outputPath,
        );
        if (normalizedOutputPath.isNotEmpty) {
          normalized['relative_path'] = normalizedOutputPath;
          normalized['output_relative_path'] = normalizedOutputPath;
        }
        return normalized;
      default:
        return normalized;
    }
  }

  JsonMap _presentUserOptions(JsonMap arguments) {
    // 中文注释: 选项工具是纯状态结果，不需要宿主 IO，但要告诉主循环当前应该等待用户选择。
    final options = _normalizedUserOptions(arguments);
    if (options.isEmpty) {
      return _resultFactory.notExecuted(
        'present_user_options 至少需要 1 个可点击选项。请提供 options/choices/items 数组，并为每项补齐 title 或 label。',
        data: <String, Object?>{
          'question': ValueReaders.stringValue(arguments['question']),
          'suggested_tool': 'present_user_options',
        },
      );
    }
    return _resultFactory.success(
      '已生成用户选项：${options.length} 个',
      data: <String, Object?>{
        'question': ValueReaders.stringValue(arguments['question']),
        'options': options,
        'waiting_for_user_choice': true,
      },
    );
  }

  List<JsonMap> _normalizedUserOptions(JsonMap arguments) {
    // 中文注释: 这里兼容 options/choices/items 等常见别名，避免模型轻微字段漂移就把整组按钮吞掉。
    final rawOptions = ValueReaders.objectList(
      arguments['options'] ??
          arguments['choices'] ??
          arguments['items'] ??
          arguments['buttons'] ??
          arguments['suggestions'] ??
          arguments['entries'],
    );
    final result = <JsonMap>[];
    for (final rawEntry in rawOptions) {
      if (rawEntry is String || rawEntry is num) {
        final text = ValueReaders.stringValue(rawEntry).trim();
        if (text.isEmpty) {
          continue;
        }
        result.add(<String, Object?>{
          'id': 'option_${result.length + 1}',
          'label': text,
          'title': text,
          'description': '',
          'prompt': text,
        });
        continue;
      }
      final entry = ValueReaders.mapValue(rawEntry);
      if (entry.isEmpty) {
        continue;
      }
      final label = ValueReaders.stringValue(
        entry['label'],
        ValueReaders.stringValue(
          entry['title'],
          ValueReaders.stringValue(
            entry['name'],
            ValueReaders.stringValue(entry['text'], '选项'),
          ),
        ),
      ).trim();
      final description = ValueReaders.stringValue(
        entry['description'],
        ValueReaders.stringValue(
          entry['detail'],
          ValueReaders.stringValue(
            entry['summary'],
            ValueReaders.stringValue(entry['subtitle']),
          ),
        ),
      ).trim();
      final prompt = ValueReaders.stringValue(
        entry['prompt'],
        ValueReaders.stringValue(
          entry['value'],
          ValueReaders.stringValue(
            entry['title'],
            ValueReaders.stringValue(entry['text'], label),
          ),
        ),
      ).trim();
      final id = ValueReaders.stringValue(
        entry['id'],
        label.isEmpty ? 'option_${result.length + 1}' : label,
      ).trim();
      if (label.isEmpty && prompt.isEmpty) {
        continue;
      }
      result.add(<String, Object?>{
        'id': id.isEmpty ? 'option_${result.length + 1}' : id,
        'label': label.isEmpty ? prompt : label,
        'title': label.isEmpty ? prompt : label,
        'description': description,
        'prompt': prompt.isEmpty ? label : prompt,
      });
    }
    return result;
  }
}
