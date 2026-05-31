import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'expression_constraint_scope.dart';

class ExpressionConstraintScopeNormalizerService {
  const ExpressionConstraintScopeNormalizerService();

  ExpressionConstraintScope normalize(JsonMap raw) {
    return ExpressionConstraintScope(
      projectTypeIds: ValueReaders.stringList(
        raw['project_type_ids'] ?? raw['project_types'],
      ),
      agentIds: ValueReaders.stringList(raw['agent_ids'] ?? raw['agents']),
      modeIds: ValueReaders.stringList(raw['mode_ids'] ?? raw['modes']),
      stageIds: ValueReaders.stringList(raw['stage_ids'] ?? raw['stages']),
    );
  }

  JsonMap toDocument(ExpressionConstraintScope scope) {
    return <String, Object?>{
      'project_type_ids': ValueReaders.deepCopyList(
        scope.projectTypeIds.cast<Object?>(),
      ),
      'agent_ids': ValueReaders.deepCopyList(scope.agentIds.cast<Object?>()),
      'mode_ids': ValueReaders.deepCopyList(scope.modeIds.cast<Object?>()),
      'stage_ids': ValueReaders.deepCopyList(scope.stageIds.cast<Object?>()),
    };
  }
}
