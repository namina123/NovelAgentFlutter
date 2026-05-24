import '../common/json_types.dart';
import 'builtin_tool_catalog.dart';
import 'builtin_tool_definition.dart';

class ToolSchemaBuilderService {
  List<JsonMap> buildOpenAiSchemas(List<String> toolIds) {
    // 中文注释: schema 生成集中在核心层，确保 CLI、GUI 和未来远程宿主暴露同一套工具协议。
    final result = <JsonMap>[];
    for (final toolId in toolIds) {
      final schema = _schemaFor(toolId);
      if (schema.isNotEmpty) {
        result.add(schema);
      }
    }
    return result;
  }

  JsonMap _schemaFor(String toolId) {
    BuiltinToolDefinition? definition;
    for (final item in BuiltinToolCatalog.definitions) {
      if (item.id == toolId) {
        definition = item;
        break;
      }
    }
    if (definition == null) {
      return <String, Object?>{};
    }
    return <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': definition.id,
        'description': definition.description,
        'parameters': _parametersFor(definition.id),
      },
    };
  }

  JsonMap _parametersFor(String toolId) {
    switch (toolId) {
      case 'list_project_files':
        return _objectSchema(
          properties: <String, Object?>{
            'relative_path': _stringSchema('可选目录范围。必须使用项目内英文相对路径。'),
          },
        );
      case 'read_project_file':
        return _objectSchema(
          required: const <String>['relative_path'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('要读取的项目英文相对路径。必须直接复制 list_project_files 返回的 relative_path。'),
          },
        );
      case 'write_project_file':
        return _objectSchema(
          required: const <String>['content_type', 'content'],
          properties: <String, Object?>{
            'content_type': _stringSchema(
              'outline、draft、chapter、setting、character、style、summary、knowledge 等内容类型。',
            ),
            'title': _stringSchema('用于自动生成文件名的标题。'),
            'relative_path': _stringSchema('可选目标相对路径；未提供时按内容类型自动规划。'),
            'content': _stringSchema('要写入的完整文本内容。'),
            'overwrite': _boolSchema('修正同一路径时显式传 true。'),
          },
        );
      case 'edit_project_file':
        return _objectSchema(
          required: const <String>['relative_path', 'operation'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('要修改的文件相对路径。'),
            'operation': _stringSchema(
              'append、prepend、replace、overwrite、insert_before、insert_after、delete。',
            ),
            'content': _stringSchema('新增或替换后的文本内容。'),
            'old_text': _stringSchema(
              'replace、insert_before、insert_after、delete 所依赖的原文锚点。',
            ),
            'expected_occurrences': _intSchema('可选，replace 时期望命中次数。'),
            'replace_all': _boolSchema('replace/delete 是否处理全部命中。'),
            'content_type': _stringSchema('可选内容类型，用于权限和目录语义。'),
          },
        );
      case 'delete_project_file':
        return _objectSchema(
          required: const <String>['relative_path'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('要删除的项目相对路径。'),
            'create_backup': _boolSchema('删除前是否先创建备份。'),
          },
        );
      case 'present_user_options':
        return _objectSchema(
          required: const <String>['question', 'options'],
          properties: <String, Object?>{
            'question': _stringSchema('要用户选择的简短问题。'),
            'options': <String, Object?>{
              'type': 'array',
              'items': _objectSchema(
                required: const <String>['id', 'title'],
                properties: <String, Object?>{
                  'id': _stringSchema('选项标识。'),
                  'title': _stringSchema('选项标题。'),
                  'description': _stringSchema('选项补充说明。'),
                },
              ),
            },
          },
        );
      case 'set_agent_tasks':
        return _objectSchema(
          required: const <String>['goal', 'tasks'],
          properties: <String, Object?>{
            'goal': _stringSchema('当前任务总目标。'),
            'tasks': <String, Object?>{
              'type': 'array',
              'items': _objectSchema(
                properties: <String, Object?>{
                  'id': _stringSchema('任务标识。'),
                  'title': _stringSchema('任务标题。'),
                  'description': _stringSchema('任务说明。'),
                  'status': _stringSchema('任务状态。'),
                },
              ),
            },
          },
        );
      case 'load_agent_skill':
        return _objectSchema(
          properties: <String, Object?>{
            'skill_id': _stringSchema('要读取的技能 ID。'),
            'query': _stringSchema('当尚未确定 skill_id 时，用任务描述匹配最合适的技能。'),
          },
        );
      case 'call_sub_agent':
        return _objectSchema(
          required: const <String>['agent_id', 'task'],
          properties: <String, Object?>{
            'agent_id': _stringSchema('子智能体 ID。'),
            'task': _stringSchema('委派任务说明。'),
            'context_excerpt': _stringSchema('传给子智能体的上下文摘录。'),
            'expected_output': _stringSchema('期望产物格式。'),
          },
        );
      case 'update_world_state':
        return _objectSchema(
          required: const <String>['title', 'content'],
          properties: <String, Object?>{
            'title': _stringSchema('世界设定条目标题。'),
            'entry_type': _stringSchema(
              'rule、location、faction、timeline 等条目类型。',
            ),
            'content': _stringSchema('完整设定正文。'),
            'keywords': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关键词。'),
            },
          },
        );
      case 'update_character_state':
        return _objectSchema(
          required: const <String>['name'],
          properties: <String, Object?>{
            'name': _stringSchema('角色名。'),
            'status': _stringSchema('角色当前状态。'),
            'role': _stringSchema('角色定位或职责。'),
            'content': _stringSchema('完整角色卡正文；未提供时可根据其他字段自动生成。'),
          },
        );
      case 'create_chapter_task':
        return _objectSchema(
          required: const <String>['title', 'goal'],
          properties: <String, Object?>{
            'title': _stringSchema('任务标题。'),
            'goal': _stringSchema('任务目标。'),
            'task_type': _stringSchema('chapter、scene、revision 等类型。'),
            'chapter_index': _intSchema('可选章节序号。'),
            'notes': _stringSchema('附加说明。'),
          },
        );
      case 'mark_task_status':
        return _objectSchema(
          properties: <String, Object?>{
            'task_id': _stringSchema('任务 ID。'),
            'relative_path': _stringSchema('任务文件相对路径。'),
            'status': _stringSchema('pending、running、done 等状态。'),
            'note': _stringSchema('进展说明。'),
            'output_path': _stringSchema('相关产出路径。'),
          },
        );
      case 'summarize_context':
        return _objectSchema(
          required: const <String>['title', 'summary'],
          properties: <String, Object?>{
            'title': _stringSchema('摘要标题。'),
            'scope': _stringSchema('session、chapter、stage 等范围。'),
            'summary': _stringSchema('摘要正文。'),
            'relative_path': _stringSchema('可选目标相对路径。'),
          },
        );
      case 'run_continuity_check':
        return _objectSchema(
          required: const <String>['title', 'summary'],
          properties: <String, Object?>{
            'title': _stringSchema('检查标题。'),
            'review_type': _stringSchema('continuity、style、plot 等检查类型。'),
            'scope': _stringSchema('检查范围。'),
            'summary': _stringSchema('检查摘要。'),
            'issues': <String, Object?>{
              'type': 'array',
              'items': _objectSchema(
                properties: <String, Object?>{
                  'title': _stringSchema('问题标题。'),
                  'severity': _stringSchema('low、medium、high。'),
                  'detail': _stringSchema('问题细节。'),
                  'suggestion': _stringSchema('建议修复方式。'),
                },
              ),
            },
            'suggestions': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('补充建议。'),
            },
            'source_paths': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('相关源文件路径。'),
            },
          },
        );
      case 'create_backup':
        return _objectSchema(
          required: const <String>['relative_path'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('要备份的文件相对路径。'),
            'reason': _stringSchema('备份原因。'),
          },
        );
      case 'restore_backup':
        return _objectSchema(
          required: const <String>['backup_path'],
          properties: <String, Object?>{
            'backup_path': _stringSchema('backups/ 下的备份相对路径。'),
            'target_path': _stringSchema('可选恢复目标路径。'),
          },
        );
      case 'get_project_file_info':
        return _objectSchema(
          required: const <String>['relative_path'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('要检查的文件相对路径。'),
            'start_line': _intSchema('可选起始行，1-based。'),
            'end_line': _intSchema('可选结束行，1-based。'),
          },
        );
      case 'search_project_files':
        return _objectSchema(
          required: const <String>['pattern'],
          properties: <String, Object?>{
            'pattern': _stringSchema('搜索关键词。'),
            'relative_path': _stringSchema('可选搜索范围目录。'),
            'limit': _intSchema('最大返回命中数。'),
            'case_sensitive': _boolSchema('是否区分大小写。'),
            'include_json': _boolSchema('是否搜索 json/jsonl。'),
          },
        );
      case 'create_project_entry':
        return _objectSchema(
          required: const <String>['relative_path'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('要创建的文件或目录相对路径。'),
            'is_folder': _boolSchema('是否创建目录。'),
            'content': _stringSchema('创建文件时的初始文本。'),
            'overwrite': _boolSchema('文件存在时是否覆盖。'),
          },
        );
      case 'move_project_file':
        return _objectSchema(
          required: const <String>['relative_path', 'target_relative_path'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('源文件相对路径。'),
            'target_relative_path': _stringSchema('目标文件相对路径。'),
            'overwrite': _boolSchema('目标存在时是否覆盖。'),
          },
        );
      case 'reorder_project_file':
        return _objectSchema(
          required: const <String>['relative_path', 'target_index'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('要重排的文件相对路径。'),
            'target_index': _intSchema('目标排序位置。'),
          },
        );
      case 'rename_project_file':
        return _objectSchema(
          required: const <String>['relative_path', 'new_name'],
          properties: <String, Object?>{
            'relative_path': _stringSchema('源文件相对路径。'),
            'new_name': _stringSchema('新的文件名。'),
          },
        );
      case 'rename_project':
        return _objectSchema(
          required: const <String>['new_name'],
          properties: <String, Object?>{'new_name': _stringSchema('新的项目标题。')},
        );
      case 'manipulate_project_file_lines':
        return _objectSchema(
          required: const <String>[
            'relative_path',
            'operation',
            'start_line',
            'end_line',
          ],
          properties: <String, Object?>{
            'relative_path': _stringSchema('源文件相对路径。'),
            'operation': _stringSchema('copy、cut、delete。'),
            'start_line': _intSchema('起始行，1-based。'),
            'end_line': _intSchema('结束行，1-based。'),
            'target_relative_path': _stringSchema('copy/cut 时可选目标文件路径。'),
            'target_line': _intSchema('插入到目标文件的行号。'),
          },
        );
      case 'list_history_sessions':
        return _objectSchema(
          properties: <String, Object?>{
            'start': _intSchema('起始偏移。'),
            'length': _intSchema('返回条数。'),
          },
        );
      case 'request_gateway_tool':
        return _objectSchema(
          required: const <String>['gateway_tool'],
          properties: <String, Object?>{
            'gateway_tool': _stringSchema('要请求的网关工具名。'),
            'arguments': _objectSchema(
              properties: const <String, Object?>{},
              additionalProperties: true,
            ),
          },
        );
      default:
        return _objectSchema(
          properties: const <String, Object?>{},
          additionalProperties: true,
        );
    }
  }

  JsonMap _objectSchema({
    Map<String, Object?> properties = const <String, Object?>{},
    List<String> required = const <String>[],
    bool additionalProperties = true,
  }) {
    return <String, Object?>{
      'type': 'object',
      'properties': properties,
      'required': required,
      'additionalProperties': additionalProperties,
    };
  }

  JsonMap _stringSchema(String description) {
    return <String, Object?>{'type': 'string', 'description': description};
  }

  JsonMap _boolSchema(String description) {
    return <String, Object?>{'type': 'boolean', 'description': description};
  }

  JsonMap _intSchema(String description) {
    return <String, Object?>{'type': 'integer', 'description': description};
  }
}
