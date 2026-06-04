import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_constraint_binding_validation_codes.dart';
import 'narrative_ref.dart';

const _constraintBindingScopeValidatorService =
    OpenJsonStructureValidatorService();

class ConstraintBindingScope {
  const ConstraintBindingScope({
    this.appliesTo = const <String>[],
    this.projectTypeIds = const <String>[],
    this.agentIds = const <String>[],
    this.modeIds = const <String>[],
    this.stageIds = const <String>[],
    this.targetRefs = const <NarrativeRef>[],
    this.metadata = const <String, Object?>{},
  });

  final List<String> appliesTo;
  final List<String> projectTypeIds;
  final List<String> agentIds;
  final List<String> modeIds;
  final List<String> stageIds;
  final List<NarrativeRef> targetRefs;
  final JsonMap metadata;

  bool get isGlobal =>
      projectTypeIds.isEmpty &&
      agentIds.isEmpty &&
      modeIds.isEmpty &&
      stageIds.isEmpty &&
      targetRefs.isEmpty;

  ConstraintBindingScope copyWith({
    List<String>? appliesTo,
    List<String>? projectTypeIds,
    List<String>? agentIds,
    List<String>? modeIds,
    List<String>? stageIds,
    List<NarrativeRef>? targetRefs,
    JsonMap? metadata,
  }) {
    // 中文注释: scope 只描述“约束绑定到哪些执行面与目标”，不承担具体约束规则内容。
    return ConstraintBindingScope(
      appliesTo: appliesTo ?? this.appliesTo,
      projectTypeIds: projectTypeIds ?? this.projectTypeIds,
      agentIds: agentIds ?? this.agentIds,
      modeIds: modeIds ?? this.modeIds,
      stageIds: stageIds ?? this.stageIds,
      targetRefs: targetRefs ?? this.targetRefs,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ConstraintBindingScope.fromJson(JsonMap json) {
    return ConstraintBindingScope(
      appliesTo: ValueReaders.stringList(json['applies_to']),
      projectTypeIds: ValueReaders.stringList(json['project_type_ids']),
      agentIds: ValueReaders.stringList(json['agent_ids']),
      modeIds: ValueReaders.stringList(json['mode_ids']),
      stageIds: ValueReaders.stringList(json['stage_ids']),
      targetRefs: ValueReaders.mapList(
        json['target_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'applies_to': appliesTo,
      'project_type_ids': projectTypeIds,
      'agent_ids': agentIds,
      'mode_ids': modeIds,
      'stage_ids': stageIds,
      'target_refs': targetRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _constraintBindingScopeValidatorService.requireNonEmptyCollection(
        appliesTo,
        NarrativeConstraintBindingValidationCodes.missingAppliesTo,
      ),
    );
    return result;
  }
}
