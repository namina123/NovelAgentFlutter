import '../assets/project_style_binding.dart';
import '../assets/project_style_binding_normalizer_service.dart';
import '../assets/style_profile.dart';
import '../assets/style_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'expression_constraint_profile.dart';
import 'expression_constraint_profile_normalizer_service.dart';
import 'project_expression_constraint_binding.dart';
import 'project_expression_constraint_binding_normalizer_service.dart';
import 'mode_guidance.dart';
import 'project_constitution.dart';
import 'project_constitution_normalizer_service.dart';

class CreativeRuleStack {
  CreativeRuleStack({
    this.constitution,
    this.modeGuidance,
    this.expressionConstraints = const <ExpressionConstraintProfile>[],
    this.expressionConstraintBindings =
        const <ProjectExpressionConstraintBinding>[],
    this.styles = const <StyleProfile>[],
    this.styleBindings = const <ProjectStyleBinding>[],
    this.consumedMemorySectionIds = const <String>[],
    this.sourcePaths = const <String>[],
  });

  final ProjectConstitution? constitution;
  final ModeGuidance? modeGuidance;
  final List<ExpressionConstraintProfile> expressionConstraints;
  final List<ProjectExpressionConstraintBinding> expressionConstraintBindings;
  final List<StyleProfile> styles;
  final List<ProjectStyleBinding> styleBindings;
  final List<String> consumedMemorySectionIds;
  final List<String> sourcePaths;

  bool get isEmpty =>
      (constitution == null || constitution!.isEmpty) &&
      (modeGuidance == null || modeGuidance!.isEmpty) &&
      expressionConstraints.isEmpty &&
      styles.isEmpty;

  CreativeRuleStack copyWith({
    ProjectConstitution? constitution,
    ModeGuidance? modeGuidance,
    List<ExpressionConstraintProfile>? expressionConstraints,
    List<ProjectExpressionConstraintBinding>? expressionConstraintBindings,
    List<StyleProfile>? styles,
    List<ProjectStyleBinding>? styleBindings,
    List<String>? consumedMemorySectionIds,
    List<String>? sourcePaths,
  }) {
    return CreativeRuleStack(
      constitution: constitution ?? this.constitution,
      modeGuidance: modeGuidance ?? this.modeGuidance,
      expressionConstraints:
          expressionConstraints ?? this.expressionConstraints,
      expressionConstraintBindings:
          expressionConstraintBindings ?? this.expressionConstraintBindings,
      styles: styles ?? this.styles,
      styleBindings: styleBindings ?? this.styleBindings,
      consumedMemorySectionIds:
          consumedMemorySectionIds ?? this.consumedMemorySectionIds,
      sourcePaths: sourcePaths ?? this.sourcePaths,
    );
  }

  JsonMap toJson() {
    final constitutionNormalizer = ProjectConstitutionNormalizerService();
    final expressionConstraintNormalizer =
        ExpressionConstraintProfileNormalizerService();
    final expressionConstraintBindingNormalizer =
        ProjectExpressionConstraintBindingNormalizerService();
    final styleNormalizer = StyleProfileNormalizerService();
    final bindingNormalizer = ProjectStyleBindingNormalizerService();
    return <String, Object?>{
      if (constitution != null)
        'constitution': constitutionNormalizer.toDocument(constitution!),
      if (modeGuidance != null)
        'mode_guidance': <String, Object?>{
          'mode_id': modeGuidance!.modeId,
          'title': modeGuidance!.title,
          'summary': modeGuidance!.summary,
          'current_stage_title': modeGuidance!.currentStageTitle,
          'confirmed_facts': modeGuidance!.confirmedFacts,
          'boundaries': modeGuidance!.boundaries,
          'source_path': modeGuidance!.sourcePath,
          'metadata': ValueReaders.deepCopyMap(modeGuidance!.metadata),
        },
      'expression_constraints': expressionConstraints
          .map(expressionConstraintNormalizer.toDocument)
          .toList(growable: false),
      'expression_constraint_bindings': expressionConstraintBindings
          .map(expressionConstraintBindingNormalizer.toDocument)
          .toList(growable: false),
      'styles': styles.map(styleNormalizer.toDocument).toList(growable: false),
      'style_bindings': styleBindings
          .map(bindingNormalizer.toDocument)
          .toList(growable: false),
      'consumed_memory_section_ids': consumedMemorySectionIds,
      'source_paths': sourcePaths,
    };
  }

  static CreativeRuleStack fromJson(JsonMap document) {
    final constitutionNormalizer = ProjectConstitutionNormalizerService();
    final expressionConstraintNormalizer =
        ExpressionConstraintProfileNormalizerService();
    final expressionConstraintBindingNormalizer =
        ProjectExpressionConstraintBindingNormalizerService();
    final styleNormalizer = StyleProfileNormalizerService();
    final bindingNormalizer = ProjectStyleBindingNormalizerService();
    final rawGuidance = ValueReaders.mapValue(document['mode_guidance']);
    return CreativeRuleStack(
      constitution: ValueReaders.mapValue(document['constitution']).isEmpty
          ? null
          : constitutionNormalizer.normalize(
              ValueReaders.mapValue(document['constitution']),
            ),
      modeGuidance: rawGuidance.isEmpty
          ? null
          : ModeGuidance(
              modeId: ValueReaders.stringValue(rawGuidance['mode_id']),
              title: ValueReaders.stringValue(rawGuidance['title']),
              summary: ValueReaders.stringValue(rawGuidance['summary']),
              currentStageTitle: ValueReaders.stringValue(
                rawGuidance['current_stage_title'],
              ),
              confirmedFacts: ValueReaders.stringList(
                rawGuidance['confirmed_facts'],
              ),
              boundaries: ValueReaders.stringList(rawGuidance['boundaries']),
              sourcePath: ValueReaders.stringValue(rawGuidance['source_path']),
              metadata: ValueReaders.deepCopyMap(
                ValueReaders.mapValue(rawGuidance['metadata']),
              ),
            ),
      expressionConstraints: ValueReaders.mapList(
        document['expression_constraints'],
      ).map(expressionConstraintNormalizer.normalize).toList(growable: false),
      expressionConstraintBindings:
          ValueReaders.mapList(document['expression_constraint_bindings'])
              .map(expressionConstraintBindingNormalizer.normalize)
              .toList(growable: false),
      styles: ValueReaders.mapList(
        document['styles'],
      ).map(styleNormalizer.normalize).toList(growable: false),
      styleBindings: ValueReaders.mapList(
        document['style_bindings'],
      ).map(bindingNormalizer.normalize).toList(growable: false),
      consumedMemorySectionIds: ValueReaders.stringList(
        document['consumed_memory_section_ids'],
      ),
      sourcePaths: ValueReaders.stringList(document['source_paths']),
    );
  }
}
