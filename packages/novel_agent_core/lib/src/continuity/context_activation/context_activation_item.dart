import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import '../narrative_state/narrative_ref.dart';
import 'context_activation_contract_typedefs.dart';
import 'context_activation_validation_codes.dart';

const _contextActivationItemValidatorService =
    OpenJsonStructureValidatorService();

class ContextActivationItem {
  const ContextActivationItem({
    required this.itemId,
    this.source = '',
    this.title = '',
    this.targetPath = '',
    this.refs = const <NarrativeRef>[],
    this.activationReasons = const <ContextActivationReasonCode>[],
    this.reasonDetails = const <String, Object?>{},
    this.requestedChars = 0,
    this.includedChars = 0,
    this.selected = false,
    this.omitted = false,
    this.truncated = false,
    this.omissionReason = '',
    this.truncationReason = '',
    this.metadata = const <String, Object?>{},
  });

  final ContextActivationId itemId;
  final ContextActivationSource source;
  final String title;
  final String targetPath;
  final List<NarrativeRef> refs;
  final List<ContextActivationReasonCode> activationReasons;
  final JsonMap reasonDetails;
  final int requestedChars;
  final int includedChars;
  final bool selected;
  final bool omitted;
  final bool truncated;
  final String omissionReason;
  final String truncationReason;
  final JsonMap metadata;

  ContextActivationItem copyWith({
    ContextActivationId? itemId,
    ContextActivationSource? source,
    String? title,
    String? targetPath,
    List<NarrativeRef>? refs,
    List<ContextActivationReasonCode>? activationReasons,
    JsonMap? reasonDetails,
    int? requestedChars,
    int? includedChars,
    bool? selected,
    bool? omitted,
    bool? truncated,
    String? omissionReason,
    String? truncationReason,
    JsonMap? metadata,
  }) {
    // 中文注释: item 合同只承载单条上下文候选的入选/裁剪结果，不承担检索或排序算法。
    return ContextActivationItem(
      itemId: itemId ?? this.itemId,
      source: source ?? this.source,
      title: title ?? this.title,
      targetPath: targetPath ?? this.targetPath,
      refs: refs ?? this.refs,
      activationReasons: activationReasons ?? this.activationReasons,
      reasonDetails: reasonDetails ?? this.reasonDetails,
      requestedChars: requestedChars ?? this.requestedChars,
      includedChars: includedChars ?? this.includedChars,
      selected: selected ?? this.selected,
      omitted: omitted ?? this.omitted,
      truncated: truncated ?? this.truncated,
      omissionReason: omissionReason ?? this.omissionReason,
      truncationReason: truncationReason ?? this.truncationReason,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContextActivationItem.fromJson(JsonMap json) {
    return ContextActivationItem(
      itemId: ValueReaders.stringValue(json['item_id']).trim(),
      source: ValueReaders.stringValue(json['source']).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      targetPath: ValueReaders.stringValue(json['target_path']).trim(),
      refs: ValueReaders.mapList(
        json['refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      activationReasons: ValueReaders.stringList(json['activation_reasons']),
      reasonDetails: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['reason_details']),
      ),
      requestedChars: ValueReaders.intValue(json['requested_chars']),
      includedChars: ValueReaders.intValue(json['included_chars']),
      selected: ValueReaders.boolValue(json['selected']),
      omitted: ValueReaders.boolValue(json['omitted']),
      truncated: ValueReaders.boolValue(json['truncated']),
      omissionReason: ValueReaders.stringValue(json['omission_reason']).trim(),
      truncationReason: ValueReaders.stringValue(
        json['truncation_reason'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'item_id': itemId,
      'source': source,
      'title': title,
      'target_path': targetPath,
      'refs': refs.map((entry) => entry.toJson()).toList(growable: false),
      'activation_reasons': activationReasons,
      'reason_details': ValueReaders.deepCopyMap(reasonDetails),
      'requested_chars': requestedChars,
      'included_chars': includedChars,
      'selected': selected,
      'omitted': omitted,
      'truncated': truncated,
      'omission_reason': omissionReason,
      'truncation_reason': truncationReason,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _contextActivationItemValidatorService.requireNonBlankString(
        itemId,
        ContextActivationValidationCodes.missingItemId,
      ),
    );
    result.addAll(
      _contextActivationItemValidatorService.requireNonBlankString(
        source,
        ContextActivationValidationCodes.missingSource,
      ),
    );
    result.addAll(
      _contextActivationItemValidatorService.requireNonEmptyCollection(
        activationReasons,
        ContextActivationValidationCodes.missingActivationReason,
      ),
    );
    result.addAll(
      _contextActivationItemValidatorService.validateNonNegativeInt(
        requestedChars,
        ContextActivationValidationCodes.invalidRequestedChars,
      ),
    );
    result.addAll(
      _contextActivationItemValidatorService.validateNonNegativeInt(
        includedChars,
        ContextActivationValidationCodes.invalidIncludedChars,
      ),
    );
    result.addAll(
      _contextActivationItemValidatorService.requireCondition(
        !(selected && omitted),
        ContextActivationValidationCodes.conflictingSelectionState,
      ),
    );
    result.addAll(
      _contextActivationItemValidatorService.requireCondition(
        !truncated || selected,
        ContextActivationValidationCodes.truncatedItemMustBeSelected,
      ),
    );
    return result;
  }
}
