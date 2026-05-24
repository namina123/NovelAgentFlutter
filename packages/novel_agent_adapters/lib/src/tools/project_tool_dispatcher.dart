import 'package:novel_agent_core/novel_agent_core.dart';

import '../packages/local_skill_group_catalog.dart';
import '../packages/local_skill_package_catalog.dart';
import 'project_file_edit_tool_executor.dart';
import 'project_file_read_tool_executor.dart';
import 'project_file_write_tool_executor.dart';
import 'project_agent_skill_tool_executor.dart';
import 'project_management_tool_executor.dart';
import 'project_structured_memory_tool_executor.dart';
import 'project_task_tool_executor.dart';
import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectToolDispatcher implements ToolExecutionPort {
  ProjectToolDispatcher({
    required ProjectToolHostPort hostPort,
    LocalSkillPackageCatalog? skillPackageCatalog,
    LocalSkillGroupCatalog? skillGroupCatalog,
    ToolCallNormalizerService? toolCallNormalizerService,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
  }) : _toolCallNormalizerService =
           toolCallNormalizerService ?? ToolCallNormalizerService(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
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
       ),
       _agentSkillToolExecutor = ProjectAgentSkillToolExecutor(
         skillPackageCatalog: skillPackageCatalog,
         skillGroupCatalog: skillGroupCatalog,
         resultFactory: resultFactory,
       );

  final ToolCallNormalizerService _toolCallNormalizerService;
  final ProjectToolResultFactory _resultFactory;
  final ProjectFileReadToolExecutor _readToolExecutor;
  final ProjectFileWriteToolExecutor _writeToolExecutor;
  final ProjectFileEditToolExecutor _editToolExecutor;
  final ProjectStructuredMemoryToolExecutor _structuredMemoryToolExecutor;
  final ProjectTaskToolExecutor _taskToolExecutor;
  final ProjectManagementToolExecutor _managementToolExecutor;
  final ProjectAgentSkillToolExecutor _agentSkillToolExecutor;

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    // 中文注释: 调度器只负责归一化和路由，不把具体文件编辑、任务写入和摘要格式揉在一起。
    final normalized = _toolCallNormalizerService.normalizeToolCall(toolCall);
    final toolName = ValueReaders.stringValue(normalized['name']).trim();
    final arguments = ValueReaders.mapValue(normalized['arguments']);
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
      case 'set_agent_tasks':
        return _setAgentTasks(arguments);
      case 'load_agent_skill':
        return _agentSkillToolExecutor.loadAgentSkill(project, arguments);
      case 'call_sub_agent':
        return _resultFactory.notExecuted(
          'call_sub_agent 由上层 ToolExecutionService 直接接管；当前分发器只保留兜底结果。',
        );
      case 'rename_project':
        return _managementToolExecutor.renameProject(project, arguments);
      case 'reorder_project_file':
        return _managementToolExecutor.reorderProjectFile(arguments);
      case 'request_gateway_tool':
        return _managementToolExecutor.requestGatewayTool(arguments);
      default:
        return _resultFactory.error('Unknown project tool: $toolName');
    }
  }

  JsonMap _presentUserOptions(JsonMap arguments) {
    // 中文注释: 选项工具是纯状态结果，不需要宿主 IO，但要告诉主循环当前应该等待用户选择。
    final options = ValueReaders.objectList(arguments['options'])
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    return _resultFactory.success(
      '已生成用户选项：${options.length} 个',
      data: <String, Object?>{
        'question': ValueReaders.stringValue(arguments['question']),
        'options': options,
        'waiting_for_user_choice': true,
      },
    );
  }

  JsonMap _setAgentTasks(JsonMap arguments) {
    // 中文注释: 计划工具只返回结构化任务清单，供主循环记录，不直接改写项目文件。
    final tasks = ValueReaders.objectList(arguments['tasks'])
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    return _resultFactory.success(
      '已更新任务清单：${tasks.length} 项',
      data: <String, Object?>{
        'goal': ValueReaders.stringValue(arguments['goal']),
        'tasks': tasks,
      },
    );
  }
}
