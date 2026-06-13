import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'skill_capability_catalog_service.dart';

class ToolPermissionProfileService {
  ToolPermissionProfileService();

  JsonMap resolve({
    JsonMap profile = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) {
    // 中文注释: 工具权限画像负责把具体 tool policy 抽象成能力层表达，确保“技能需求”和“工具授权”之间有稳定桥梁。
    final directAllowed = ValueReaders.stringList(profile['allowed_tool_ids']);
    final directBlocked = ValueReaders.stringList(profile['blocked_tool_ids']);
    final directCapabilities = ValueReaders.stringList(
      profile['granted_capabilities'],
    );
    final toolPolicy = profile.isNotEmpty ? profile : _toolPolicyOf(agent);
    final allowedToolIds = directAllowed.isNotEmpty
        ? directAllowed
        : ValueReaders.stringList(toolPolicy['allowed_tools']);
    final blockedToolIds = directBlocked.isNotEmpty
        ? directBlocked
        : ValueReaders.stringList(toolPolicy['blocked_tools']);
    final grantedCapabilities = directCapabilities.isNotEmpty
        ? directCapabilities
        : _grantedCapabilities(allowedToolIds, blockedToolIds);
    return <String, Object?>{
      'allowed_tool_ids': allowedToolIds,
      'blocked_tool_ids': blockedToolIds,
      'granted_capabilities': grantedCapabilities,
      'summary_label': _summaryLabel(grantedCapabilities),
    };
  }

  String summaryLabel(JsonMap profile) {
    // 中文注释: 用户可理解摘要统一来自这里，避免不同 issue 拼接出彼此冲突的权限画像名称。
    final value = ValueReaders.stringValue(profile['summary_label']).trim();
    if (value.isNotEmpty) {
      return value;
    }
    return _summaryLabel(
      ValueReaders.stringList(profile['granted_capabilities']),
    );
  }

  JsonMap _toolPolicyOf(JsonMap agent) {
    final direct = ValueReaders.mapValue(agent['tool_policy']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final extensions = ValueReaders.mapValue(agent['novel_agent_extensions']);
    final extensionPolicy = ValueReaders.mapValue(extensions['tool_policy']);
    if (extensionPolicy.isNotEmpty) {
      return extensionPolicy;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(agent['metadata'])['tool_policy'],
    );
  }

  List<String> _grantedCapabilities(
    List<String> allowedToolIds,
    List<String> blockedToolIds,
  ) {
    final allowed = allowedToolIds
        .map((toolId) => toolId.trim())
        .where((toolId) => toolId.isNotEmpty)
        .toSet();
    allowed.removeAll(
      blockedToolIds
          .map((toolId) => toolId.trim())
          .where((toolId) => toolId.isNotEmpty),
    );
    final capabilities = <String>[];
    void addIfMatches(String capabilityId, Set<String> toolIds) {
      if (allowed.intersection(toolIds).isNotEmpty &&
          !capabilities.contains(capabilityId)) {
        capabilities.add(capabilityId);
      }
    }

    addIfMatches(SkillCapabilityCatalogService.projectRead, <String>{
      'list_project_files',
      'read_project_file',
      'get_project_file_info',
      'search_project_files',
      'list_history_sessions',
      'load_agent_skill',
    });
    addIfMatches(SkillCapabilityCatalogService.projectWrite, <String>{
      'write_project_file',
      'edit_project_file',
      'create_project_entry',
      'move_project_file',
      'rename_project_file',
      'delete_project_file',
      'manipulate_project_file_lines',
      'update_world_state',
      'update_character_state',
      'update_foreshadow_state',
      'update_timeline_state',
      'update_relationship_state',
      'summarize_context',
      'run_continuity_check',
      'create_backup',
      'restore_backup',
    });
    addIfMatches(SkillCapabilityCatalogService.networkAccess, <String>{
      'request_external_research',
      'request_gateway_tool',
    });
    addIfMatches(SkillCapabilityCatalogService.formalDelivery, <String>{
      'submit_chapter_delivery',
    });
    addIfMatches(SkillCapabilityCatalogService.userInteraction, <String>{
      'present_user_options',
      'request_profile_clarification',
    });
    addIfMatches(SkillCapabilityCatalogService.longTaskControl, <String>{
      'start_long_task_run',
      'create_chapter_task',
      'mark_task_status',
    });
    addIfMatches(SkillCapabilityCatalogService.semanticReview, <String>{
      'submit_semantic_review',
    });
    return capabilities;
  }

  String _summaryLabel(List<String> grantedCapabilities) {
    final capabilities = grantedCapabilities.toSet();
    if (capabilities.isEmpty) {
      return '无工具权限';
    }
    if (capabilities.length == 1 &&
        capabilities.contains(SkillCapabilityCatalogService.projectRead)) {
      return '只读';
    }
    if (capabilities.contains(SkillCapabilityCatalogService.networkAccess) &&
        !capabilities.contains(SkillCapabilityCatalogService.projectWrite)) {
      return '只读 + 联网研究';
    }
    if (capabilities.contains(SkillCapabilityCatalogService.projectWrite) &&
        !capabilities.contains(SkillCapabilityCatalogService.formalDelivery)) {
      return '读写';
    }
    if (capabilities.contains(SkillCapabilityCatalogService.formalDelivery)) {
      return '读写 + 正式交付';
    }
    return '受限工具权限';
  }
}
