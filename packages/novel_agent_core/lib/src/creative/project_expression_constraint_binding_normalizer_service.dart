import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_expression_constraint_binding.dart';

class ProjectExpressionConstraintBindingNormalizerService {
  const ProjectExpressionConstraintBindingNormalizerService();

  ProjectExpressionConstraintBinding normalize(JsonMap raw) {
    final profileId = ValueReaders.stringValue(
      raw['profile_id'] ?? raw['id'],
    ).trim();
    final bindingId = ValueReaders.stringValue(raw['id'], profileId).trim();
    return ProjectExpressionConstraintBinding(
      id: bindingId,
      profileId: profileId,
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

  JsonMap toDocument(ProjectExpressionConstraintBinding binding) {
    return <String, Object?>{
      'id': binding.id,
      'profile_id': binding.profileId,
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
