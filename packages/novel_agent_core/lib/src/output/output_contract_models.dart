import '../common/json_types.dart';
import '../common/value_readers.dart';

abstract final class OutputDensityModes {
  static const String balanced = 'balanced';
  static const String coverageFirst = 'coverage_first';
  static const String detailFirst = 'detail_first';
}

abstract final class OutputCompressionFallbackModes {
  static const String preserveCoverage = 'preserve_coverage';
  static const String preserveDetail = 'preserve_detail';
  static const String preserveEvidence = 'preserve_evidence';
}

abstract final class OutputCoverageStatuses {
  static const String covered = 'covered';
  static const String partial = 'partial';
  static const String omitted = 'omitted';
  static const String uncovered = 'uncovered';
}

abstract final class OutputCompletionStatuses {
  static const String completed = 'completed';
  static const String compressed = 'compressed';
  static const String coverageInsufficient = 'coverage_insufficient';
  static const String continuationRecommended = 'continuation_recommended';
}

abstract final class ContinuationReasonCodes {
  static const String noContinuation = 'no_continuation';
}

abstract final class OmissionReasonCodes {
  static const String outputBudgetExhausted = 'output_budget_exhausted';
  static const String evidenceInsufficient = 'evidence_insufficient';
  static const String deferredToConsolidation = 'deferred_to_consolidation';
  static const String batchScopeLimited = 'batch_scope_limited';
  static const String noOmission = 'no_omission';
}

abstract final class OutputCompressionRiskLevels {
  static const String none = 'none';
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
}

abstract final class OutputCompressionSignalCodes {
  static const String belowMinOutputSlots = 'below_min_output_slots';
  static const String oversizedItemSummary = 'oversized_item_summary';
  static const String uncoveredRequiredDimension =
      'uncovered_required_dimension';
  static const String insufficientCoveredDimensions =
      'insufficient_covered_dimensions';
  static const String omissionReported = 'omission_reported';
  static const String continuationRequested = 'continuation_requested';
}

class OutputBudgetPolicy {
  const OutputBudgetPolicy({
    this.targetOutputDensity = OutputDensityModes.balanced,
    this.minOutputSlots = 4,
    this.maxOutputSlots = 6,
    this.maxSummaryCharsPerItem = 180,
    this.mustReportOmissions = true,
    this.continuationAllowed = true,
    this.preferredOutputLanguage = 'zh-CN',
    this.compressionFallbackMode =
        OutputCompressionFallbackModes.preserveCoverage,
    this.metadata = const <String, Object?>{},
  });

  final String targetOutputDensity;
  final int minOutputSlots;
  final int maxOutputSlots;
  final int maxSummaryCharsPerItem;
  final bool mustReportOmissions;
  final bool continuationAllowed;
  final String preferredOutputLanguage;
  final String compressionFallbackMode;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'target_output_density': targetOutputDensity,
      'min_output_slots': minOutputSlots,
      'max_output_slots': maxOutputSlots,
      'max_summary_chars_per_item': maxSummaryCharsPerItem,
      'must_report_omissions': mustReportOmissions,
      'continuation_allowed': continuationAllowed,
      'preferred_output_language': preferredOutputLanguage,
      'compression_fallback_mode': compressionFallbackMode,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OutputBudgetPolicy fromJson(JsonMap json) {
    return OutputBudgetPolicy(
      targetOutputDensity: ValueReaders.stringValue(
        json['target_output_density'],
        OutputDensityModes.balanced,
      ).trim(),
      minOutputSlots: ValueReaders.intValue(json['min_output_slots'], 4),
      maxOutputSlots: ValueReaders.intValue(json['max_output_slots'], 6),
      maxSummaryCharsPerItem: ValueReaders.intValue(
        json['max_summary_chars_per_item'],
        180,
      ),
      mustReportOmissions: ValueReaders.boolValue(
        json['must_report_omissions'],
        true,
      ),
      continuationAllowed: ValueReaders.boolValue(
        json['continuation_allowed'],
        true,
      ),
      preferredOutputLanguage: ValueReaders.stringValue(
        json['preferred_output_language'],
        'zh-CN',
      ).trim(),
      compressionFallbackMode: ValueReaders.stringValue(
        json['compression_fallback_mode'],
        OutputCompressionFallbackModes.preserveCoverage,
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class OutputCoverageDimension {
  const OutputCoverageDimension({
    required this.dimensionId,
    required this.label,
    this.description = '',
    this.minItemCount = 1,
    this.required = false,
    this.metadata = const <String, Object?>{},
  });

  final String dimensionId;
  final String label;
  final String description;
  final int minItemCount;
  final bool required;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'dimension_id': dimensionId,
      'label': label,
      'description': description,
      'min_item_count': minItemCount,
      'required': required,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OutputCoverageDimension fromJson(JsonMap json) {
    return OutputCoverageDimension(
      dimensionId: ValueReaders.stringValue(json['dimension_id']).trim(),
      label: ValueReaders.stringValue(json['label']).trim(),
      description: ValueReaders.stringValue(json['description']).trim(),
      minItemCount: ValueReaders.intValue(json['min_item_count'], 1),
      required: ValueReaders.boolValue(json['required'], false),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class OutputCoverageContract {
  const OutputCoverageContract({
    this.contractId = '',
    this.taskFamilyId = '',
    this.dimensions = const <OutputCoverageDimension>[],
    this.minCoveredDimensions = 0,
    this.requireExplicitCoverageSignals = false,
    this.allowContinuationWhenIncomplete = true,
    this.metadata = const <String, Object?>{},
  });

  final String contractId;
  final String taskFamilyId;
  final List<OutputCoverageDimension> dimensions;
  final int minCoveredDimensions;
  final bool requireExplicitCoverageSignals;
  final bool allowContinuationWhenIncomplete;
  final JsonMap metadata;

  List<String> get dimensionIds => dimensions
      .map((dimension) => dimension.dimensionId)
      .where((dimensionId) => dimensionId.trim().isNotEmpty)
      .toList(growable: false);

  JsonMap toJson() {
    return <String, Object?>{
      'contract_id': contractId,
      'task_family_id': taskFamilyId,
      'dimensions': dimensions
          .map((item) => item.toJson())
          .toList(growable: false),
      'min_covered_dimensions': minCoveredDimensions,
      'require_explicit_coverage_signals': requireExplicitCoverageSignals,
      'allow_continuation_when_incomplete': allowContinuationWhenIncomplete,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OutputCoverageContract fromJson(JsonMap json) {
    return OutputCoverageContract(
      contractId: ValueReaders.stringValue(json['contract_id']).trim(),
      taskFamilyId: ValueReaders.stringValue(json['task_family_id']).trim(),
      dimensions: ValueReaders.mapList(
        json['dimensions'],
      ).map(OutputCoverageDimension.fromJson).toList(growable: false),
      minCoveredDimensions: ValueReaders.intValue(
        json['min_covered_dimensions'],
      ),
      requireExplicitCoverageSignals: ValueReaders.boolValue(
        json['require_explicit_coverage_signals'],
        false,
      ),
      allowContinuationWhenIncomplete: ValueReaders.boolValue(
        json['allow_continuation_when_incomplete'],
        true,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class OutputCoverageSignal {
  const OutputCoverageSignal({
    required this.dimensionId,
    this.slotId = '',
    this.summaryCharCount = 0,
    this.metadata = const <String, Object?>{},
  });

  final String dimensionId;
  final String slotId;
  final int summaryCharCount;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'dimension_id': dimensionId,
      'slot_id': slotId,
      'summary_char_count': summaryCharCount,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OutputCoverageSignal fromJson(JsonMap json) {
    return OutputCoverageSignal(
      dimensionId: ValueReaders.stringValue(json['dimension_id']).trim(),
      slotId: ValueReaders.stringValue(json['slot_id']).trim(),
      summaryCharCount: ValueReaders.intValue(json['summary_char_count']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class OutputCoverageLedgerDimension {
  const OutputCoverageLedgerDimension({
    required this.dimensionId,
    required this.label,
    required this.required,
    required this.minItemCount,
    required this.generatedSlotCount,
    required this.acceptedSlotCount,
    required this.omissionCount,
    required this.status,
    this.metadata = const <String, Object?>{},
  });

  final String dimensionId;
  final String label;
  final bool required;
  final int minItemCount;
  final int generatedSlotCount;
  final int acceptedSlotCount;
  final int omissionCount;
  final String status;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'dimension_id': dimensionId,
      'label': label,
      'required': required,
      'min_item_count': minItemCount,
      'generated_slot_count': generatedSlotCount,
      'accepted_slot_count': acceptedSlotCount,
      'omission_count': omissionCount,
      'status': status,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OutputCoverageLedgerDimension fromJson(JsonMap json) {
    return OutputCoverageLedgerDimension(
      dimensionId: ValueReaders.stringValue(json['dimension_id']).trim(),
      label: ValueReaders.stringValue(json['label']).trim(),
      required: ValueReaders.boolValue(json['required'], false),
      minItemCount: ValueReaders.intValue(json['min_item_count'], 1),
      generatedSlotCount: ValueReaders.intValue(json['generated_slot_count']),
      acceptedSlotCount: ValueReaders.intValue(json['accepted_slot_count']),
      omissionCount: ValueReaders.intValue(json['omission_count']),
      status: ValueReaders.stringValue(
        json['status'],
        OutputCoverageStatuses.uncovered,
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class OutputCoverageLedger {
  const OutputCoverageLedger({
    this.contractId = '',
    this.totalGeneratedSlots = 0,
    this.totalAcceptedSlots = 0,
    this.coveredDimensionCount = 0,
    this.acceptedCoveredDimensionCount = 0,
    this.completionStatus = OutputCompletionStatuses.completed,
    this.dimensions = const <OutputCoverageLedgerDimension>[],
    this.metadata = const <String, Object?>{},
  });

  final String contractId;
  final int totalGeneratedSlots;
  final int totalAcceptedSlots;
  final int coveredDimensionCount;
  final int acceptedCoveredDimensionCount;
  final String completionStatus;
  final List<OutputCoverageLedgerDimension> dimensions;
  final JsonMap metadata;

  List<String> get uncoveredDimensionIds => dimensions
      .where(
        (dimension) =>
            dimension.status != OutputCoverageStatuses.covered ||
            dimension.acceptedSlotCount < dimension.minItemCount,
      )
      .map((dimension) => dimension.dimensionId)
      .toList(growable: false);

  JsonMap toJson() {
    return <String, Object?>{
      'contract_id': contractId,
      'total_generated_slots': totalGeneratedSlots,
      'total_accepted_slots': totalAcceptedSlots,
      'covered_dimension_count': coveredDimensionCount,
      'accepted_covered_dimension_count': acceptedCoveredDimensionCount,
      'completion_status': completionStatus,
      'dimensions': dimensions
          .map((item) => item.toJson())
          .toList(growable: false),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OutputCoverageLedger fromJson(JsonMap json) {
    return OutputCoverageLedger(
      contractId: ValueReaders.stringValue(json['contract_id']).trim(),
      totalGeneratedSlots: ValueReaders.intValue(json['total_generated_slots']),
      totalAcceptedSlots: ValueReaders.intValue(json['total_accepted_slots']),
      coveredDimensionCount: ValueReaders.intValue(
        json['covered_dimension_count'],
      ),
      acceptedCoveredDimensionCount: ValueReaders.intValue(
        json['accepted_covered_dimension_count'],
      ),
      completionStatus: ValueReaders.stringValue(
        json['completion_status'],
        OutputCompletionStatuses.completed,
      ).trim(),
      dimensions: ValueReaders.mapList(
        json['dimensions'],
      ).map(OutputCoverageLedgerDimension.fromJson).toList(growable: false),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class OmissionReport {
  const OmissionReport({
    required this.reportId,
    this.contractId = '',
    this.omittedDimensionIds = const <String>[],
    this.reasonCode = '',
    this.summary = '',
    this.recommendedNextFocus = '',
    this.metadata = const <String, Object?>{},
  });

  final String reportId;
  final String contractId;
  final List<String> omittedDimensionIds;
  final String reasonCode;
  final String summary;
  final String recommendedNextFocus;
  final JsonMap metadata;

  bool get isActionable {
    if (omittedDimensionIds.any((dimensionId) => dimensionId.trim().isNotEmpty)) {
      return true;
    }
    if (reasonCode.trim().toLowerCase() == OmissionReasonCodes.noOmission) {
      return false;
    }
    return reasonCode.trim().isNotEmpty ||
        summary.trim().isNotEmpty ||
        recommendedNextFocus.trim().isNotEmpty;
  }

  JsonMap toJson() {
    return <String, Object?>{
      'report_id': reportId,
      'contract_id': contractId,
      'omitted_dimension_ids': ValueReaders.deepCopyList(
        omittedDimensionIds.cast<Object?>(),
      ),
      'reason_code': reasonCode,
      'summary': summary,
      'recommended_next_focus': recommendedNextFocus,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OmissionReport fromJson(JsonMap json) {
    return OmissionReport(
      reportId: ValueReaders.stringValue(json['report_id']).trim(),
      contractId: ValueReaders.stringValue(json['contract_id']).trim(),
      omittedDimensionIds: ValueReaders.stringList(
        json['omitted_dimension_ids'],
      ),
      reasonCode: ValueReaders.stringValue(json['reason_code']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      recommendedNextFocus: ValueReaders.stringValue(
        json['recommended_next_focus'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class ContinuationRequest {
  const ContinuationRequest({
    required this.requestId,
    this.contractId = '',
    this.continuationReason = '',
    this.missingDimensionIds = const <String>[],
    this.recommendedNextFocus = '',
    this.suggestedSlotCount = 0,
    this.metadata = const <String, Object?>{},
  });

  final String requestId;
  final String contractId;
  final String continuationReason;
  final List<String> missingDimensionIds;
  final String recommendedNextFocus;
  final int suggestedSlotCount;
  final JsonMap metadata;

  bool get isActionable {
    final hasMissingDimensions = missingDimensionIds.any(
      (dimensionId) => dimensionId.trim().isNotEmpty,
    );
    if (hasMissingDimensions ||
        recommendedNextFocus.trim().isNotEmpty ||
        suggestedSlotCount > 0) {
      return true;
    }
    return continuationReason.trim().toLowerCase() !=
            ContinuationReasonCodes.noContinuation &&
        continuationReason.trim().isNotEmpty;
  }

  JsonMap toJson() {
    return <String, Object?>{
      'request_id': requestId,
      'contract_id': contractId,
      'continuation_reason': continuationReason,
      'missing_dimension_ids': ValueReaders.deepCopyList(
        missingDimensionIds.cast<Object?>(),
      ),
      'recommended_next_focus': recommendedNextFocus,
      'suggested_slot_count': suggestedSlotCount,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ContinuationRequest fromJson(JsonMap json) {
    return ContinuationRequest(
      requestId: ValueReaders.stringValue(json['request_id']).trim(),
      contractId: ValueReaders.stringValue(json['contract_id']).trim(),
      continuationReason: ValueReaders.stringValue(
        json['continuation_reason'],
      ).trim(),
      missingDimensionIds: ValueReaders.stringList(
        json['missing_dimension_ids'],
      ),
      recommendedNextFocus: ValueReaders.stringValue(
        json['recommended_next_focus'],
      ).trim(),
      suggestedSlotCount: ValueReaders.intValue(json['suggested_slot_count']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class OutputCompressionRisk {
  const OutputCompressionRisk({
    this.level = OutputCompressionRiskLevels.none,
    this.signalCodes = const <String>[],
    this.summary = '',
    this.metadata = const <String, Object?>{},
  });

  final String level;
  final List<String> signalCodes;
  final String summary;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'level': level,
      'signal_codes': ValueReaders.deepCopyList(signalCodes.cast<Object?>()),
      'summary': summary,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OutputCompressionRisk fromJson(JsonMap json) {
    return OutputCompressionRisk(
      level: ValueReaders.stringValue(
        json['level'],
        OutputCompressionRiskLevels.none,
      ).trim(),
      signalCodes: ValueReaders.stringList(json['signal_codes']),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}
