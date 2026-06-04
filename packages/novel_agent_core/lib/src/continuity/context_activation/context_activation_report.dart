import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'context_activation_contract_typedefs.dart';
import 'context_activation_item.dart';
import 'context_activation_validation_codes.dart';

const _contextActivationReportCodecService = OpenJsonContractCodecService();
const _contextActivationReportValidatorService =
    OpenJsonStructureValidatorService();

class ContextActivationReport {
  const ContextActivationReport({
    required this.reportId,
    required this.planId,
    this.source = '',
    this.budgetChars = 0,
    this.usedChars = 0,
    this.omittedChars = 0,
    this.items = const <ContextActivationItem>[],
    this.selectedItemIds = const <ContextActivationId>[],
    this.omittedItemIds = const <ContextActivationId>[],
    this.truncatedItemIds = const <ContextActivationId>[],
    this.summary = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final ContextActivationId reportId;
  final ContextActivationId planId;
  final ContextActivationSource source;
  final int budgetChars;
  final int usedChars;
  final int omittedChars;
  final List<ContextActivationItem> items;
  final List<ContextActivationId> selectedItemIds;
  final List<ContextActivationId> omittedItemIds;
  final List<ContextActivationId> truncatedItemIds;
  final String summary;
  final String schemaVersion;
  final JsonMap metadata;

  ContextActivationReport copyWith({
    ContextActivationId? reportId,
    ContextActivationId? planId,
    ContextActivationSource? source,
    int? budgetChars,
    int? usedChars,
    int? omittedChars,
    List<ContextActivationItem>? items,
    List<ContextActivationId>? selectedItemIds,
    List<ContextActivationId>? omittedItemIds,
    List<ContextActivationId>? truncatedItemIds,
    String? summary,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: report 负责解释“最终发给模型的上下文是什么”，让省略与截断结果可追溯。
    return ContextActivationReport(
      reportId: reportId ?? this.reportId,
      planId: planId ?? this.planId,
      source: source ?? this.source,
      budgetChars: budgetChars ?? this.budgetChars,
      usedChars: usedChars ?? this.usedChars,
      omittedChars: omittedChars ?? this.omittedChars,
      items: items ?? this.items,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      omittedItemIds: omittedItemIds ?? this.omittedItemIds,
      truncatedItemIds: truncatedItemIds ?? this.truncatedItemIds,
      summary: summary ?? this.summary,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContextActivationReport.fromJson(JsonMap json) {
    return ContextActivationReport(
      reportId: ValueReaders.stringValue(json['report_id']).trim(),
      planId: ValueReaders.stringValue(json['plan_id']).trim(),
      source: ValueReaders.stringValue(json['source']).trim(),
      budgetChars: ValueReaders.intValue(json['budget_chars']),
      usedChars: ValueReaders.intValue(json['used_chars']),
      omittedChars: ValueReaders.intValue(json['omitted_chars']),
      items: ValueReaders.mapList(
        json['items'],
      ).map(ContextActivationItem.fromJson).toList(growable: false),
      selectedItemIds: ValueReaders.stringList(json['selected_item_ids']),
      omittedItemIds: ValueReaders.stringList(json['omitted_item_ids']),
      truncatedItemIds: ValueReaders.stringList(json['truncated_item_ids']),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      schemaVersion: _contextActivationReportCodecService.readSchemaVersion(
        json,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'report_id': reportId,
      'plan_id': planId,
      'source': source,
      'budget_chars': budgetChars,
      'used_chars': usedChars,
      'omitted_chars': omittedChars,
      'items': items.map((entry) => entry.toJson()).toList(growable: false),
      'selected_item_ids': selectedItemIds,
      'omitted_item_ids': omittedItemIds,
      'truncated_item_ids': truncatedItemIds,
      'summary': summary,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _contextActivationReportValidatorService.requireNonBlankString(
        reportId,
        ContextActivationValidationCodes.missingReportId,
      ),
    );
    result.addAll(
      _contextActivationReportValidatorService.requireNonBlankString(
        planId,
        ContextActivationValidationCodes.missingPlanId,
      ),
    );
    result.addAll(
      _contextActivationReportValidatorService.requireNonBlankString(
        source,
        ContextActivationValidationCodes.missingSource,
      ),
    );
    result.addAll(
      _contextActivationReportValidatorService.requireCondition(
        budgetChars >= 0 && omittedChars >= 0,
        ContextActivationValidationCodes.invalidBudgetChars,
      ),
    );
    result.addAll(
      _contextActivationReportValidatorService.validateNonNegativeInt(
        usedChars,
        ContextActivationValidationCodes.invalidUsedChars,
      ),
    );
    result.addAll(items.expand((item) => item.validateBasics()));
    return result;
  }
}
