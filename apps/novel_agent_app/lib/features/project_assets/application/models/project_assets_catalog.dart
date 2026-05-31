import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectAssetsCatalog {
  const ProjectAssetsCatalog({
    this.styles = const <JsonMap>[],
    this.expressionConstraints = const <ExpressionConstraintProfile>[],
    this.expressionConstraintBindings =
        const <ProjectExpressionConstraintBinding>[],
    this.foreshadows = const <ForeshadowRecord>[],
    this.timelines = const <TimelineRecord>[],
    this.relationships = const <RelationshipRecord>[],
    this.referenceIndex = const SharedNarrativeAssetReferenceIndex(),
  });

  final List<JsonMap> styles;
  final List<ExpressionConstraintProfile> expressionConstraints;
  final List<ProjectExpressionConstraintBinding> expressionConstraintBindings;
  final List<ForeshadowRecord> foreshadows;
  final List<TimelineRecord> timelines;
  final List<RelationshipRecord> relationships;
  final SharedNarrativeAssetReferenceIndex referenceIndex;

  factory ProjectAssetsCatalog.empty() => const ProjectAssetsCatalog();
}
