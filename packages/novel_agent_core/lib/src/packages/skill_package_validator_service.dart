import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'skill_package_metadata_profile_service.dart';

class SkillPackageValidatorService {
  SkillPackageValidatorService({
    SkillPackageMetadataProfileService? metadataProfileService,
  }) : _metadataProfileService =
           metadataProfileService ?? const SkillPackageMetadataProfileService();

  final SkillPackageMetadataProfileService _metadataProfileService;

  JsonMap validate(JsonMap skill) {
    // 中文注释: 技能校验服务集中给出错误和警告，保证外部技能包进入项目前就能发现结构性问题。
    final errors = <String>[];
    final warnings = <String>[];
    final id = ValueReaders.stringValue(skill['id']).trim();
    final name = ValueReaders.stringValue(skill['name']).trim();
    final description = ValueReaders.stringValue(skill['description']).trim();
    final instruction = ValueReaders.stringValue(
      skill['instruction_markdown'],
    ).trim();
    final extensions = _metadataProfileService.extractExtensions(skill);
    final requiredCapabilities = ValueReaders.stringList(
      extensions['required_capabilities'],
    );
    final optionalCapabilities = ValueReaders.stringList(
      extensions['optional_capabilities'],
    );
    final safeWithoutTools = ValueReaders.boolValue(
      extensions['safe_without_tools'],
      true,
    );
    if (id.isEmpty) {
      errors.add('技能缺少 id。');
    } else if (!RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(id)) {
      warnings.add('技能 id 建议使用小写 kebab/snake 风格，便于目录和引用稳定。');
    }
    if (name.isEmpty) {
      errors.add('技能缺少 name。');
    }
    if (description.isEmpty) {
      errors.add('技能缺少 description。');
    }
    if (instruction.isEmpty) {
      errors.add('技能缺少 instruction_markdown。');
    }
    final overlap = requiredCapabilities
        .where(optionalCapabilities.contains)
        .toList(growable: false);
    if (overlap.isNotEmpty) {
      errors.add(
        'required_capabilities 与 optional_capabilities 不能重复：${overlap.join('、')}',
      );
    }
    if (!safeWithoutTools && requiredCapabilities.isEmpty) {
      warnings.add(
        'safe_without_tools=false 但未声明 required_capabilities，技能边界不够清楚。',
      );
    }
    if (safeWithoutTools && requiredCapabilities.isNotEmpty) {
      warnings.add('技能声明了 required_capabilities；请确认在能力缺失时仍能提供降级指导。');
    }
    final resourceHints = ValueReaders.mapValue(skill['resource_hints']);
    final hasResources =
        ValueReaders.stringList(resourceHints['scripts']).isNotEmpty ||
        ValueReaders.stringList(resourceHints['references']).isNotEmpty ||
        ValueReaders.stringList(resourceHints['assets']).isNotEmpty;
    if (!hasResources && instruction.length > 4000) {
      warnings.add('SKILL.md 正文较长但未声明 references/scripts/assets，建议把细节下沉到包内资源。');
    }
    if (ValueReaders.mapValue(extensions['tool_schema']).isNotEmpty) {
      warnings.add('技能携带了 tool_schema；请确认这是技能自己的调用入口，而不是对宿主内置工具的硬依赖。');
    }
    if (ValueReaders.mapValue(skill['portable_core']).isEmpty) {
      warnings.add('建议补齐可移植核心字段，提升技能被其他宿主部分理解的概率。');
    }
    return <String, Object?>{
      'ok': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }
}
