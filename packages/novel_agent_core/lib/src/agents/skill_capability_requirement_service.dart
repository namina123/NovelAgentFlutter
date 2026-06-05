import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/skill_package_metadata_profile_service.dart';

class SkillCapabilityRequirementService {
  SkillCapabilityRequirementService({
    SkillPackageMetadataProfileService? metadataProfileService,
  }) : _metadataProfileService =
           metadataProfileService ?? const SkillPackageMetadataProfileService();

  final SkillPackageMetadataProfileService _metadataProfileService;

  Map<String, JsonMap> indexBySkillId(List<Object?> availableSkills) {
    // 中文注释: 技能需求索引只保留兼容检查所需的轻量字段，不把完整技能包结构硬塞进 loadout 解析链。
    final result = <String, JsonMap>{};
    for (final rawSkill in availableSkills) {
      final skill = ValueReaders.mapValue(rawSkill);
      final skillId = ValueReaders.stringValue(skill['id']).trim();
      if (skillId.isEmpty) {
        continue;
      }
      final extensions = _metadataProfileService.extractExtensions(skill);
      result[skillId] = <String, Object?>{
        'id': skillId,
        'name': ValueReaders.stringValue(skill['name'], skillId).trim(),
        'required_capabilities': ValueReaders.stringList(
          extensions['required_capabilities'],
        ),
        'optional_capabilities': ValueReaders.stringList(
          extensions['optional_capabilities'],
        ),
        'safe_without_tools': ValueReaders.boolValue(
          extensions['safe_without_tools'],
          true,
        ),
        'source_kind': _sourceKind(extensions['source']),
      };
    }
    return result;
  }

  String sourceLabel(String sourceKind) {
    // 中文注释: 需求来源在用户层只区分内置/非内置，避免因为来源细分过多反而弱化真正的权限问题。
    return sourceKind == 'builtin' ? '内置技能' : '非内置技能';
  }

  String _sourceKind(Object? value) {
    final raw = ValueReaders.stringValue(value, 'package').trim();
    return raw == 'builtin' ? 'builtin' : 'non_builtin';
  }
}
