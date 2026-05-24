import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../tools/builtin_tool_catalog.dart';
import 'builtin_skill_group_catalog_service.dart';

class AgentSkillScopeService {
  AgentSkillScopeService({
    BuiltinSkillGroupCatalogService? skillGroupCatalogService,
    List<String>? builtinToolIds,
  }) : _skillGroupCatalogService =
           skillGroupCatalogService ?? const BuiltinSkillGroupCatalogService(),
       _builtinToolIds =
           builtinToolIds ??
           BuiltinToolCatalog.definitions
               .map((definition) => definition.id)
               .toList(growable: false);

  final BuiltinSkillGroupCatalogService _skillGroupCatalogService;
  final List<String> _builtinToolIds;

  List<String> declaredSkillIds(
    JsonMap agent, {
    List<Object?> availableSkillGroups = const <Object?>[],
  }) {
    // 中文注释: 这里只展开智能体声明的技能与技能组，不掺入宿主权限、工具策略或文件系统判断。
    if (agent.isEmpty) {
      return const <String>[];
    }
    final result = <String>[];
    for (final skillId in ValueReaders.stringList(agent['skills'])) {
      _appendIfAllowed(result, skillId);
    }
    for (final groupId in ValueReaders.stringList(agent['skill_groups'])) {
      final groupSkillIds = _skillGroupCatalogService.skillIdsForGroup(
        groupId,
        groups: availableSkillGroups,
      );
      for (final skillId in groupSkillIds) {
        _appendIfAllowed(result, skillId);
      }
    }
    return List<String>.unmodifiable(result);
  }

  List<String> enabledSkillIds(
    JsonMap agent, {
    List<Object?> availableSkillGroups = const <Object?>[],
    List<String> availableSkillIds = const <String>[],
  }) {
    // 中文注释: 启用范围在声明范围之上再与实际可加载技能交集，避免智能体读取不存在的技能包。
    final declared = declaredSkillIds(
      agent,
      availableSkillGroups: availableSkillGroups,
    );
    if (availableSkillIds.isEmpty) {
      return declared;
    }
    final availableSet = availableSkillIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return declared
        .where((skillId) => availableSet.contains(skillId))
        .toList(growable: false);
  }

  void _appendIfAllowed(List<String> result, String rawSkillId) {
    final cleanId = rawSkillId.trim();
    if (cleanId.isEmpty ||
        _builtinToolIds.contains(cleanId) ||
        result.contains(cleanId)) {
      return;
    }
    result.add(cleanId);
  }
}
