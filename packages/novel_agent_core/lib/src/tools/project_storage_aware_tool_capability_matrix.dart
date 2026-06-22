import '../project/project_storage_strategy.dart';
import 'project_tool_exposure_context.dart';

enum ProjectToolExposureRole {
  primary,
  compatibility,
  hostOrSupervisorOnly,
  transportOnly,
}

class ProjectStorageAwareToolCapabilityMatrix {
  const ProjectStorageAwareToolCapabilityMatrix();

  static const List<String> _sqlitePrimaryToolIds = <String>[
    'submit_chapter_delivery',
    'submit_narrative_state_claims',
    'submit_semantic_review',
    'request_profile_clarification',
    'request_external_research',
    'submit_research_note',
    'propose_knowledge_card',
    'propose_design_element',
    'link_information_evidence',
    'propose_reference_work',
    'summarize_context',
    'run_continuity_check',
    'list_history_sessions',
    'create_backup',
    'restore_backup',
    'read_project_file',
    'list_project_files',
    'get_project_file_info',
    'search_project_files',
  ];

  static const List<String> _sqliteCompatibilityToolIds = <String>[
    'write_project_file',
    'edit_project_file',
    'create_project_entry',
    'move_project_file',
    'delete_project_file',
    'rename_project_file',
    'reorder_project_file',
    'manipulate_project_file_lines',
  ];

  static const List<String> _markdownPrimaryToolIds = <String>[
    ..._sqlitePrimaryToolIds,
    ..._sqliteCompatibilityToolIds,
  ];

  ProjectToolExposureRole roleForTool(
    String toolId, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: 这层只做“工具在当前存储策略下属于主链、兼容层还是宿主层”的判定，不直接拼 prompt。
    final normalized = toolId.trim();
    if (normalized.isEmpty) {
      return ProjectToolExposureRole.transportOnly;
    }
    if (normalized == 'request_gateway_tool') {
      return ProjectToolExposureRole.transportOnly;
    }
    if (normalized == 'start_long_task_run') {
      if (context.isSubAgent || context.projectType != 'long_novel') {
        return ProjectToolExposureRole.hostOrSupervisorOnly;
      }
      return ProjectToolExposureRole.primary;
    }
    if (context.storageStrategy == ProjectStorageStrategy.sqliteProjectStore) {
      if (_sqliteCompatibilityToolIds.contains(normalized)) {
        return ProjectToolExposureRole.compatibility;
      }
      if (_sqlitePrimaryToolIds.contains(normalized)) {
        return ProjectToolExposureRole.primary;
      }
      return ProjectToolExposureRole.primary;
    }
    if (_markdownPrimaryToolIds.contains(normalized)) {
      return ProjectToolExposureRole.primary;
    }
    return ProjectToolExposureRole.primary;
  }

  bool isPrimaryTool(
    String toolId, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: 主链判断用于 prompt 排序和 surface 解释，不代表额外的权限检查。
    return roleForTool(toolId, context: context) ==
        ProjectToolExposureRole.primary;
  }

  bool isCompatibilityTool(
    String toolId, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: 兼容层判断帮助 SQLite 项目把文件树工具留在次级 surface，避免把旧心智继续放到主链上。
    return roleForTool(toolId, context: context) ==
        ProjectToolExposureRole.compatibility;
  }

  bool isHostOrSupervisorOnlyTool(
    String toolId, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: 宿主/监督者专属工具只在上层服务里保留，不让模型把它们当成普通项目工具。
    return roleForTool(toolId, context: context) ==
        ProjectToolExposureRole.hostOrSupervisorOnly;
  }

  bool isTransportOnlyTool(
    String toolId, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: 传输层工具不进入正常 tool surface，避免模型误以为自己可以直接发网关或协议级请求。
    return roleForTool(toolId, context: context) ==
        ProjectToolExposureRole.transportOnly;
  }

  List<String> sortToolIds(
    Iterable<String> toolIds, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: 排序规则把主链工具放前面、兼容层放后面，让 storage-aware surface 在 prompt 里自然靠前。
    final ranked = <_RankedToolId>[];
    final seen = <String>{};
    var index = 0;
    for (final toolId in toolIds) {
      final normalized = toolId.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      ranked.add(
        _RankedToolId(
          toolId: normalized,
          rank: _roleRank(roleForTool(normalized, context: context)),
          index: index,
        ),
      );
      index += 1;
    }
    ranked.sort((left, right) {
      final rankComparison = left.rank.compareTo(right.rank);
      if (rankComparison != 0) {
        return rankComparison;
      }
      return left.index.compareTo(right.index);
    });
    return ranked.map((entry) => entry.toolId).toList(growable: false);
  }

  List<String> primaryToolIds(
    Iterable<String> toolIds, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: 这个筛选只负责把主链工具单独抽出来，方便 prompt 或测试做主能力面断言。
    return toolIds
        .where((toolId) => isPrimaryTool(toolId, context: context))
        .map((toolId) => toolId.trim())
        .where((toolId) => toolId.isNotEmpty)
        .toList(growable: false);
  }

  List<String> compatibilityToolIds(
    Iterable<String> toolIds, {
    required ProjectToolExposureContext context,
  }) {
    // 中文注释: SQLite 项目里的兼容层工具保留可见，但不应和主链工具混在一起。
    return toolIds
        .where((toolId) => isCompatibilityTool(toolId, context: context))
        .map((toolId) => toolId.trim())
        .where((toolId) => toolId.isNotEmpty)
        .toList(growable: false);
  }

  String guidanceFor(ProjectToolExposureContext context) {
    // 中文注释: 这段说明直接给 prompt 使用，把“主链 / 兼容层 / 宿主层”边界讲清楚。
    if (context.storageStrategy == ProjectStorageStrategy.sqliteProjectStore) {
      return [
        'SQLite 项目优先使用结构化/领域工具作为主链：submit_chapter_delivery、submit_narrative_state_claims、submit_semantic_review、研究/知识/设计/引用工具是正式能力面。',
        'read_project_file、list_project_files、get_project_file_info、search_project_files 只用于读取 SQLite 投影或兼容镜像，不要把它们当成主事实源写作面。',
        'write_project_file、edit_project_file、create_project_entry、move_project_file、delete_project_file、rename_project_file、reorder_project_file、manipulate_project_file_lines 属于兼容层或修复层工具，只在确实需要兼容旧文件树、导入导出或局部修复时使用。',
        if (context.projectType == 'knowledge_base')
          'knowledge_base 项目必须遵守 sqlite_project_store 主存储策略，资料治理与提取结果优先通过 SQLite 结构化事实源和投影层表达。',
      ].join('\n');
    }
    return [
      'Markdown 项目仍以文件树为主事实源；结构化/领域工具用于正式章节交付与长期记忆收口，但不改变 Markdown 作为主内容存储的地位。',
      '文件写入、编辑、移动和删除仍属于主链工具的一部分，但正式章节交付依然优先使用 submit_chapter_delivery。',
    ].join('\n');
  }

  int _roleRank(ProjectToolExposureRole role) {
    switch (role) {
      case ProjectToolExposureRole.primary:
        return 0;
      case ProjectToolExposureRole.compatibility:
        return 1;
      case ProjectToolExposureRole.hostOrSupervisorOnly:
        return 2;
      case ProjectToolExposureRole.transportOnly:
        return 3;
    }
  }
}

class _RankedToolId {
  const _RankedToolId({
    required this.toolId,
    required this.rank,
    required this.index,
  });

  final String toolId;
  final int rank;
  final int index;
}
