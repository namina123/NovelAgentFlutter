import '../common/json_types.dart';
import '../common/value_readers.dart';

class BuiltinSkillGroupCatalogService {
  const BuiltinSkillGroupCatalogService();

  List<JsonMap> builtinGroups() {
    // 中文注释: 内置技能组目录先在 core 保留纯数据版本，供 GUI、CLI 与适配层共用同一套声明范围。
    return _rawGroups
        .map(
          (group) => <String, Object?>{
            'id': ValueReaders.stringValue(group['id']).trim(),
            'name': ValueReaders.stringValue(group['name']).trim(),
            'description': ValueReaders.stringValue(
              group['description'],
            ).trim(),
            'source': ValueReaders.stringValue(group['source'], 'builtin'),
            'skills': ValueReaders.stringList(group['skills']),
          },
        )
        .where((group) => ValueReaders.stringValue(group['id']).isNotEmpty)
        .toList(growable: false);
  }

  List<String> skillIdsForGroup(
    String groupId, {
    List<Object?> groups = const <Object?>[],
  }) {
    // 中文注释: 技能组展开统一收口，避免调用方自行扫描数组并重复处理空值和大小写。
    final normalizedId = groupId.trim();
    if (normalizedId.isEmpty) {
      return const <String>[];
    }
    final candidates = groups.isEmpty ? builtinGroups() : groups;
    for (final rawGroup in candidates) {
      final group = ValueReaders.mapValue(rawGroup);
      if (ValueReaders.stringValue(group['id']).trim() != normalizedId) {
        continue;
      }
      return ValueReaders.stringList(group['skills']);
    }
    return const <String>[];
  }

  static const List<JsonMap> _rawGroups = <JsonMap>[
    <String, Object?>{
      'id': 'project_io',
      'name': '项目资料与归档方法',
      'description': '围绕项目资料检索、产物归档和安全修改的工作方法；不直接包含读写工具权限。',
      'source': 'builtin',
      'skills': <String>[
        'project_context_research',
        'artifact_routing',
        'revision_workflow',
      ],
    },
    <String, Object?>{
      'id': 'interactive_planning',
      'name': '交互规划',
      'description': '收敛用户偏好、设计选项、拆分多步骤任务和判断何时委派子智能体。',
      'source': 'builtin',
      'skills': <String>[
        'ask_opening_questions',
        'interactive_decision_design',
        'task_workflow_planning',
      ],
    },
    <String, Object?>{
      'id': 'memory_tools',
      'name': '记忆维护方法',
      'description': '维护世界书、角色状态、摘要、伏笔和连续性事实的方法；保存动作仍由工具策略控制。',
      'source': 'builtin',
      'skills': <String>[
        'summarize_chapter',
        'memory_maintenance',
        'check_continuity',
      ],
    },
    <String, Object?>{
      'id': 'task_flow',
      'name': '任务流',
      'description': '长任务、章节队列、检查点和修订流程的规划方法；任务创建/标记是工具能力。',
      'source': 'builtin',
      'skills': <String>[
        'task_workflow_planning',
        'chapter_drafting_method',
        'revision_workflow',
        'summarize_chapter',
      ],
    },
    <String, Object?>{
      'id': 'read_only',
      'name': '只读资料',
      'description': '只做资料理解、摘要和审查建议，不把工具权限混入技能组。',
      'source': 'builtin',
      'skills': <String>[
        'project_context_research',
        'check_continuity',
        'summarize_chapter',
      ],
    },
    <String, Object?>{
      'id': 'skill_ecology',
      'name': '技能生态设计',
      'description': '设计、审查和规范化智能体技能卡；不授予任何内置工具权限。',
      'source': 'builtin',
      'skills': <String>[
        'skill_blueprint_design',
        'interactive_decision_design',
        'task_workflow_planning',
      ],
    },
  ];
}
