import '../common/json_types.dart';
import 'builtin_tool_catalog.dart';
import 'builtin_tool_definition.dart';
import 'domain/narrative_domain_tool_catalog.dart';
import 'domain/narrative_domain_tool_names.dart';

class ToolSchemaBuilderService {
  ToolSchemaBuilderService({
    NarrativeDomainToolCatalog? narrativeDomainToolCatalog,
  }) : _narrativeDomainToolCatalog =
           narrativeDomainToolCatalog ?? NarrativeDomainToolCatalog();

  final NarrativeDomainToolCatalog _narrativeDomainToolCatalog;

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
    if (NarrativeDomainToolNames.all.contains(toolId)) {
      final schemas = _narrativeDomainToolCatalog.buildOpenAiSchemas(<String>[
        toolId,
      ]);
      return schemas.isEmpty ? <String, Object?>{} : schemas.single;
    }
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
            'relative_path': _stringSchema(
              '要读取的项目英文相对路径。必须直接复制 list_project_files 返回的 relative_path。',
            ),
            'start_line': _intSchema('可选起始行，1-based；负数表示从文件尾部反向定位。'),
            'end_line': _intSchema('可选结束行，1-based；负数表示从文件尾部反向定位。'),
            'limit': _intSchema('可选最大返回行数；只在行范围读取时生效。'),
            'exclude_line_numbers': _boolSchema('行范围读取时是否不要在 content 中附带行号。'),
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
            'pattern': _stringSchema('可选正则表达式；当 use_regex=true 时作为匹配模式。'),
            'use_regex': _boolSchema(
              'replace/delete 是否把 pattern 或 old_text 当作正则表达式。',
            ),
            'start_text': _stringSchema('可选范围起始锚点；replace/delete 时可用于锚点范围处理。'),
            'end_text': _stringSchema('可选范围结束锚点；replace/delete 时可用于锚点范围处理。'),
            'include_start': _boolSchema('锚点范围处理时是否连同 start_text 一起替换或删除。'),
            'include_end': _boolSchema('锚点范围处理时是否连同 end_text 一起替换或删除。'),
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
      case 'start_long_task_run':
        return _objectSchema(
          properties: <String, Object?>{
            'mode_id': _stringSchema(
              '可选模式引导 ID，例如 seed_autopilot_novel 或 full_outline_consensus；未提供时会尝试按项目运行基准推断。',
            ),
            'mode': _stringSchema('mode_id 的兼容别名。'),
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
                  'goal': _stringSchema('任务目标。'),
                  'description': _stringSchema('任务说明。'),
                  'brief': _stringSchema('给执行层的简短说明。'),
                  'task_type': _stringSchema(
                    'planning、chapter、checkpoint、revision 等任务类型。',
                  ),
                  'mode': _stringSchema('任务运行模式，例如 seed_to_full_novel。'),
                  'status': _stringSchema('任务状态。'),
                  'chapter': _stringSchema('章节名或阶段名。'),
                  'depends_on': <String, Object?>{
                    'type': 'array',
                    'items': _stringSchema('依赖任务 ID。'),
                  },
                  'source_paths': <String, Object?>{
                    'type': 'array',
                    'items': _stringSchema('执行前应优先读取的项目路径。'),
                  },
                  'output_paths': <String, Object?>{
                    'type': 'array',
                    'items': _stringSchema('该任务预期写出的项目路径。'),
                  },
                  'tool_hint': _stringSchema('给后续执行层的工具使用提示。'),
                  'metadata': _objectSchema(
                    properties: <String, Object?>{
                      'plan_id': _stringSchema('所属计划 ID。'),
                      'workflow_mode': _stringSchema('工作流模式。'),
                      'stage': _stringSchema('阶段标识。'),
                      'sort_order': <String, Object?>{'type': 'integer'},
                      'persistent_context_paths': <String, Object?>{
                        'type': 'array',
                        'items': _stringSchema('需要长期保留的约束路径。'),
                      },
                    },
                  ),
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
            'detail_level': _stringSchema(
              'summary、full 或 reference。默认 summary，只返回压缩后的技能执行摘要。',
            ),
            'reference_path': _stringSchema(
              '可选，读取技能包内某个 reference 文件时使用，路径必须来自上次 load_agent_skill 返回的 resource_hints.references。',
            ),
          },
        );
      case 'call_sub_agent':
        return _objectSchema(
          required: const <String>['agent_id', 'task'],
          properties: <String, Object?>{
            'agent_id': _stringSchema(
              '子智能体 ID。优先填写协作视角清单里的 agent_id；如果一时拿不准精确 id，也可以传空字符串，运行时会按 task 自动兜底选取最匹配的子智能体。',
            ),
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
            'character_id': _stringSchema('可选稳定角色 ID；未提供时会按当前角色名生成稳定路径。'),
            'name': _stringSchema('角色名。'),
            'status': _stringSchema('角色当前状态。'),
            'role': _stringSchema('角色定位或职责。'),
            'content': _stringSchema('角色本轮阶段状态说明或主档补充说明。'),
            'stage_id': _stringSchema('可选阶段 ID，例如 chapter_03、checkpoint_02。'),
            'stage_label': _stringSchema('可选阶段展示名，例如 第3章后、卷一收束。'),
            'source_paths': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('触发本次状态更新的相关项目路径。'),
            },
            'related_timeline_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('可选关联时间线 ID。'),
            },
          },
        );
      case 'update_foreshadow_state':
        return _objectSchema(
          required: const <String>['title'],
          properties: <String, Object?>{
            'foreshadow_id': _stringSchema('可选稳定伏笔 ID；未提供时会按标题生成稳定路径。'),
            'title': _stringSchema('伏笔标题。'),
            'status': _stringSchema(
              'planted、pending_payoff、partial_payoff、resolved、abandoned、at_risk。',
            ),
            'summary': _stringSchema('伏笔概述。'),
            'content': _stringSchema('可选摘要正文；未传 summary 时可用它兜底。'),
            'planted_chapter_path': _stringSchema('可选埋设章节路径。'),
            'target_payoff_path': _stringSchema('可选目标回收路径。'),
            'related_entity_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联角色或组织 ID。'),
            },
            'related_timeline_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联时间线 ID。'),
            },
            'related_relationship_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联关系 ID。'),
            },
            'related_paths': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('触发本次更新的相关项目路径。'),
            },
            'trigger_conditions': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('触发条件。'),
            },
            'payoff_expectations': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('回收预期。'),
            },
            'tags': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('标签。'),
            },
            'notes': _stringSchema('备注。'),
          },
        );
      case 'update_timeline_state':
        return _objectSchema(
          required: const <String>['title'],
          properties: <String, Object?>{
            'timeline_id': _stringSchema('可选稳定时间线 ID。'),
            'title': _stringSchema('时间线事件标题。'),
            'display_name': _stringSchema('可选显示名；未提供时使用 title。'),
            'summary': _stringSchema('时间线事件概述。'),
            'content': _stringSchema('可选事件正文；未传 summary 时可用它兜底。'),
            'event_type': _stringSchema(
              'event、turning_point、setup、payoff 等事件类型。',
            ),
            'status': _stringSchema('planned、active、done 等状态。'),
            'phase_label': _stringSchema('阶段标签，例如 第三章后、卷一尾声。'),
            'sequence': _intSchema('可选顺序号。'),
            'related_entity_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联角色或组织 ID。'),
            },
            'related_foreshadow_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联伏笔 ID。'),
            },
            'related_relationship_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联关系 ID。'),
            },
            'related_paths': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('触发本次更新的相关项目路径。'),
            },
            'notes': _stringSchema('备注。'),
          },
        );
      case 'update_relationship_state':
        return _objectSchema(
          required: const <String>[
            'title',
            'left_entity_id',
            'right_entity_id',
          ],
          properties: <String, Object?>{
            'relationship_id': _stringSchema('可选稳定关系 ID。'),
            'title': _stringSchema('关系标题。'),
            'display_name': _stringSchema('可选显示名；未提供时使用 title。'),
            'left_entity_id': _stringSchema('左侧实体 ID。'),
            'right_entity_id': _stringSchema('右侧实体 ID。'),
            'summary': _stringSchema('关系变化概述。'),
            'content': _stringSchema('可选正文；未传 summary 时可用它兜底。'),
            'relationship_type': _stringSchema(
              'alliance、hostility、mentor 等关系类型。',
            ),
            'status': _stringSchema('active、broken、hidden 等状态。'),
            'related_foreshadow_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联伏笔 ID。'),
            },
            'related_timeline_ids': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('关联时间线 ID。'),
            },
            'tags': <String, Object?>{
              'type': 'array',
              'items': _stringSchema('标签。'),
            },
            'notes': _stringSchema('备注。'),
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
            'use_regex': _boolSchema('是否把 pattern 作为正则表达式。'),
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
            'start_line': _intSchema('起始行，1-based；负数表示从文件尾部反向定位。'),
            'end_line': _intSchema('结束行，1-based；负数表示从文件尾部反向定位。'),
            'target_relative_path': _stringSchema('copy/cut 时可选目标文件路径。'),
            'target_line': _intSchema('插入到目标文件的行号；负数表示按目标文件尾部反向定位。'),
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
