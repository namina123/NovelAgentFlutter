import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_style_binding.dart';

class ProjectStyleBindingNormalizerService {
  const ProjectStyleBindingNormalizerService();

  ProjectStyleBinding normalize(JsonMap raw) {
    // 中文注释: 风格绑定是项目级规则，不直接挤进风格资产本体，避免“风格定义”和“项目采用方式”互相污染。
    final styleId = ValueReaders.stringValue(
      raw['style_id'] ?? raw['id'],
    ).trim();
    final bindingId = ValueReaders.stringValue(raw['id'], styleId).trim();
    return ProjectStyleBinding(
      id: bindingId,
      styleId: styleId,
      displayName: ValueReaders.stringValue(
        raw['display_name'] ?? raw['name'],
      ).trim(),
      enabled: ValueReaders.boolValue(raw['enabled'], true),
      defaultForProject: ValueReaders.boolValue(
        raw['default_for_project'] ?? raw['default'],
      ),
      targetAgentIds: ValueReaders.stringList(
        raw['target_agent_ids'] ?? raw['agents'],
      ),
      targetModeIds: ValueReaders.stringList(
        raw['target_mode_ids'] ?? raw['modes'],
      ),
      targetStageIds: ValueReaders.stringList(
        raw['target_stage_ids'] ?? raw['stages'],
      ),
      weight: ValueReaders.intValue(raw['weight'], 100),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(ProjectStyleBinding binding) {
    return <String, Object?>{
      'id': binding.id,
      'style_id': binding.styleId,
      'display_name': binding.displayName,
      'enabled': binding.enabled,
      'default_for_project': binding.defaultForProject,
      'target_agent_ids': ValueReaders.deepCopyList(
        binding.targetAgentIds.cast<Object?>(),
      ),
      'target_mode_ids': ValueReaders.deepCopyList(
        binding.targetModeIds.cast<Object?>(),
      ),
      'target_stage_ids': ValueReaders.deepCopyList(
        binding.targetStageIds.cast<Object?>(),
      ),
      'weight': binding.weight,
      'metadata': ValueReaders.deepCopyMap(binding.metadata),
    };
  }
}
