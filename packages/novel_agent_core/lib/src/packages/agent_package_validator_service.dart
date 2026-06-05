import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../agents/skill_capability_catalog_service.dart';
import 'agent_package_metadata_profile_service.dart';

class AgentPackageValidatorService {
  AgentPackageValidatorService({
    AgentPackageMetadataProfileService? metadataProfileService,
    SkillCapabilityCatalogService? capabilityCatalogService,
  }) : _metadataProfileService =
           metadataProfileService ?? const AgentPackageMetadataProfileService(),
       _capabilityCatalogService =
           capabilityCatalogService ?? const SkillCapabilityCatalogService();

  final AgentPackageMetadataProfileService _metadataProfileService;
  final SkillCapabilityCatalogService _capabilityCatalogService;

  JsonMap validate(JsonMap agent) {
    // 中文注释: 这里集中校验智能体包的目标、边界、能力和输出合同，避免“只有人设没有约束”的空壳智能体混进项目。
    final errors = <String>[];
    final warnings = <String>[];
    final version = ValueReaders.stringValue(agent['version'], '1').trim();
    final name = ValueReaders.stringValue(agent['name']).trim();
    final description = ValueReaders.stringValue(agent['description']).trim();
    final role = ValueReaders.stringValue(agent['role']).trim();
    final objective = ValueReaders.stringValue(agent['objective']).trim();
    final systemPrompt = ValueReaders.stringValue(
      agent['system_prompt'],
    ).trim();
    final canDo = ValueReaders.stringList(agent['can_do']);
    final mustNotDo = ValueReaders.stringList(agent['must_not_do']);
    final requiredCapabilities = ValueReaders.stringList(
      agent['required_capabilities'],
    );
    final optionalCapabilities = ValueReaders.stringList(
      agent['optional_capabilities'],
    );
    final overlap = requiredCapabilities
        .where(optionalCapabilities.contains)
        .toList(growable: false);

    if (name.isEmpty) {
      errors.add('智能体缺少 name。');
    }
    if (description.isEmpty) {
      errors.add('智能体缺少 description。');
    }
    if (version.isEmpty) {
      errors.add('智能体缺少 version。');
    }
    if (role.isEmpty) {
      errors.add('智能体缺少 role。');
    }
    if (objective.isEmpty) {
      errors.add('智能体缺少 objective。');
    }
    if (systemPrompt.isEmpty) {
      errors.add('智能体缺少 system_prompt 或正文操作说明。');
    }
    if (canDo.isEmpty) {
      warnings.add('建议声明 can_do，明确该智能体应该承担的任务类型。');
    }
    if (mustNotDo.isEmpty) {
      warnings.add('建议声明 must_not_do，明确该智能体绝不做什么。');
    }
    if (overlap.isNotEmpty) {
      errors.add(
        'required_capabilities 与 optional_capabilities 不能重复：${overlap.join('、')}',
      );
    }
    final unknownCapabilities =
        <String>[...requiredCapabilities, ...optionalCapabilities]
            .where(
              (capabilityId) =>
                  !_capabilityCatalogService.isKnownCapability(capabilityId),
            )
            .toSet()
            .toList(growable: false);
    if (unknownCapabilities.isNotEmpty) {
      warnings.add(
        '存在未识别的 capability requirement：${unknownCapabilities.join('、')}；请先确认宿主是否真的支持这些能力。',
      );
    }
    if (ValueReaders.stringValue(agent['preferred_output']).trim().isEmpty &&
        ValueReaders.stringValue(agent['output_schema_path']).trim().isEmpty &&
        ValueReaders.mapValue(agent['output_schema']).isEmpty) {
      warnings.add('建议提供 preferred_output 或 output_schema，用来约束产出格式。');
    }
    if (ValueReaders.stringList(agent['knowledge_sources']).isEmpty) {
      warnings.add('建议显式声明 knowledge_sources，哪怕只是项目目录或包内参考资料路径。');
    }
    if (ValueReaders.stringValue(agent['reflection_mode']).trim().isEmpty) {
      warnings.add('建议显式声明 reflection_mode。');
    }
    if (_metadataProfileService.extractExtensions(agent).isEmpty) {
      warnings.add('建议把宿主私有配置收进 metadata.novel_agent，保持智能体包核心字段更可移植。');
    }

    return <String, Object?>{
      'ok': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }
}
