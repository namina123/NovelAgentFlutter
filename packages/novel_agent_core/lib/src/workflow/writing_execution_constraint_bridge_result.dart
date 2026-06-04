import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_profile.dart';
import '../creative/expression_constraint_profile_normalizer_service.dart';
import '../creative/project_expression_constraint_binding.dart';
import '../creative/project_expression_constraint_binding_normalizer_service.dart';

class WritingExecutionConstraintBridgeResult {
  const WritingExecutionConstraintBridgeResult({
    this.chapterLengthMetadata = const <String, Object?>{},
    this.expressionConstraintProfiles = const <ExpressionConstraintProfile>[],
    this.projectExpressionConstraintBindings =
        const <ProjectExpressionConstraintBinding>[],
    this.runtimeReport = const <String, Object?>{},
  });

  final JsonMap chapterLengthMetadata;
  final List<ExpressionConstraintProfile> expressionConstraintProfiles;
  final List<ProjectExpressionConstraintBinding>
  projectExpressionConstraintBindings;
  final JsonMap runtimeReport;

  bool get hasChapterLengthMetadata => chapterLengthMetadata.isNotEmpty;
  bool get hasExpressionConstraintRuntime =>
      expressionConstraintProfiles.isNotEmpty ||
      projectExpressionConstraintBindings.isNotEmpty;

  JsonMap toJson() {
    const profileNormalizer = ExpressionConstraintProfileNormalizerService();
    const bindingNormalizer = ProjectExpressionConstraintBindingNormalizerService();
    return <String, Object?>{
      'chapter_length_metadata': ValueReaders.deepCopyMap(
        chapterLengthMetadata,
      ),
      'expression_constraint_profiles': expressionConstraintProfiles
          .map(profileNormalizer.toDocument)
          .cast<Object?>()
          .toList(growable: false),
      'project_expression_constraint_bindings':
          projectExpressionConstraintBindings
              .map(bindingNormalizer.toDocument)
              .cast<Object?>()
              .toList(growable: false),
      'runtime_report': ValueReaders.deepCopyMap(runtimeReport),
    };
  }
}
