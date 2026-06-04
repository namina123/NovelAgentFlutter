import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'context_activation_contract_typedefs.dart';
import 'context_activation_item.dart';
import 'context_activation_validation_codes.dart';

const _contextActivationPlanCodecService = OpenJsonContractCodecService();
const _contextActivationPlanValidatorService =
    OpenJsonStructureValidatorService();

class ContextActivationPlan {
  const ContextActivationPlan({
    required this.planId,
    this.source = '',
    this.taskType = '',
    this.budgetChars = 0,
    this.reservedOutputChars = 0,
    this.items = const <ContextActivationItem>[],
    this.summary = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final ContextActivationId planId;
  final ContextActivationSource source;
  final String taskType;
  final int budgetChars;
  final int reservedOutputChars;
  final List<ContextActivationItem> items;
  final String summary;
  final String schemaVersion;
  final JsonMap metadata;

  ContextActivationPlan copyWith({
    ContextActivationId? planId,
    ContextActivationSource? source,
    String? taskType,
    int? budgetChars,
    int? reservedOutputChars,
    List<ContextActivationItem>? items,
    String? summary,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: plan 只描述本轮上下文激活意图与预算，不表达最终是否真的发给模型。
    return ContextActivationPlan(
      planId: planId ?? this.planId,
      source: source ?? this.source,
      taskType: taskType ?? this.taskType,
      budgetChars: budgetChars ?? this.budgetChars,
      reservedOutputChars: reservedOutputChars ?? this.reservedOutputChars,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContextActivationPlan.fromJson(JsonMap json) {
    return ContextActivationPlan(
      planId: ValueReaders.stringValue(json['plan_id']).trim(),
      source: ValueReaders.stringValue(json['source']).trim(),
      taskType: ValueReaders.stringValue(json['task_type']).trim(),
      budgetChars: ValueReaders.intValue(json['budget_chars']),
      reservedOutputChars: ValueReaders.intValue(json['reserved_output_chars']),
      items: ValueReaders.mapList(
        json['items'],
      ).map(ContextActivationItem.fromJson).toList(growable: false),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      schemaVersion: _contextActivationPlanCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'plan_id': planId,
      'source': source,
      'task_type': taskType,
      'budget_chars': budgetChars,
      'reserved_output_chars': reservedOutputChars,
      'items': items.map((entry) => entry.toJson()).toList(growable: false),
      'summary': summary,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _contextActivationPlanValidatorService.requireNonBlankString(
        planId,
        ContextActivationValidationCodes.missingPlanId,
      ),
    );
    result.addAll(
      _contextActivationPlanValidatorService.requireNonBlankString(
        source,
        ContextActivationValidationCodes.missingSource,
      ),
    );
    result.addAll(
      _contextActivationPlanValidatorService.requireCondition(
        budgetChars >= 0 && reservedOutputChars >= 0,
        ContextActivationValidationCodes.invalidBudgetChars,
      ),
    );
    result.addAll(items.expand((item) => item.validateBasics()));
    return result;
  }
}
