import '../common/json_types.dart';
import '../common/value_readers.dart';

abstract final class ReferenceSourceBatchPlanningModes {
  static const String structureFirst = 'structure_first';
  static const String chapterFirst = 'chapter_first';

  static const List<String> knownValues = <String>[
    structureFirst,
    chapterFirst,
  ];
}

abstract final class ReferenceOversizeSectionSplitPolicies {
  static const String paragraphClusterPreferred = 'paragraph_cluster_preferred';
  static const String windowFallback = 'window_fallback';

  static const List<String> knownValues = <String>[
    paragraphClusterPreferred,
    windowFallback,
  ];
}

abstract final class ReferenceBatchGoalKinds {
  static const String semanticExtraction = 'semantic_extraction';
  static const String styleSweep = 'style_sweep';
  static const String timelineSweep = 'timeline_sweep';
  static const String boundarySweep = 'boundary_sweep';
  static const String consolidation = 'consolidation';

  static const List<String> knownValues = <String>[
    semanticExtraction,
    styleSweep,
    timelineSweep,
    boundarySweep,
    consolidation,
  ];
}

class ReferenceIngestionBudgetPolicy {
  const ReferenceIngestionBudgetPolicy({
    this.defaultAvailableContextChars = 12000,
    this.sourceWindowRatio = 0.4,
    this.minSourceChars = 1600,
    this.maxSourceChars = 5200,
    this.minSectionsPerBatch = 1,
    this.maxSectionsPerBatch = 4,
    this.instructionReserveRatio = 0.18,
    this.carryForwardReserveRatio = 0.08,
    this.responseReserveRatio = 0.18,
    this.safetyReserveRatio = 0.06,
    this.oversizeSectionMinChars = 1200,
    this.planningMode = ReferenceSourceBatchPlanningModes.structureFirst,
    this.oversizeSectionSplitPolicy =
        ReferenceOversizeSectionSplitPolicies.paragraphClusterPreferred,
    this.batchGoalKind = ReferenceBatchGoalKinds.semanticExtraction,
    this.allowStructureFallback = true,
  });

  final int defaultAvailableContextChars;
  final double sourceWindowRatio;
  final int minSourceChars;
  final int maxSourceChars;
  final int minSectionsPerBatch;
  final int maxSectionsPerBatch;
  final double instructionReserveRatio;
  final double carryForwardReserveRatio;
  final double responseReserveRatio;
  final double safetyReserveRatio;
  final int oversizeSectionMinChars;
  final String planningMode;
  final String oversizeSectionSplitPolicy;
  final String batchGoalKind;
  final bool allowStructureFallback;

  ReferenceIngestionBudgetPolicy copyWith({
    int? defaultAvailableContextChars,
    double? sourceWindowRatio,
    int? minSourceChars,
    int? maxSourceChars,
    int? minSectionsPerBatch,
    int? maxSectionsPerBatch,
    double? instructionReserveRatio,
    double? carryForwardReserveRatio,
    double? responseReserveRatio,
    double? safetyReserveRatio,
    int? oversizeSectionMinChars,
    String? planningMode,
    String? oversizeSectionSplitPolicy,
    String? batchGoalKind,
    bool? allowStructureFallback,
  }) {
    return ReferenceIngestionBudgetPolicy(
      defaultAvailableContextChars:
          defaultAvailableContextChars ?? this.defaultAvailableContextChars,
      sourceWindowRatio: sourceWindowRatio ?? this.sourceWindowRatio,
      minSourceChars: minSourceChars ?? this.minSourceChars,
      maxSourceChars: maxSourceChars ?? this.maxSourceChars,
      minSectionsPerBatch: minSectionsPerBatch ?? this.minSectionsPerBatch,
      maxSectionsPerBatch: maxSectionsPerBatch ?? this.maxSectionsPerBatch,
      instructionReserveRatio:
          instructionReserveRatio ?? this.instructionReserveRatio,
      carryForwardReserveRatio:
          carryForwardReserveRatio ?? this.carryForwardReserveRatio,
      responseReserveRatio: responseReserveRatio ?? this.responseReserveRatio,
      safetyReserveRatio: safetyReserveRatio ?? this.safetyReserveRatio,
      oversizeSectionMinChars:
          oversizeSectionMinChars ?? this.oversizeSectionMinChars,
      planningMode: planningMode ?? this.planningMode,
      oversizeSectionSplitPolicy:
          oversizeSectionSplitPolicy ?? this.oversizeSectionSplitPolicy,
      batchGoalKind: batchGoalKind ?? this.batchGoalKind,
      allowStructureFallback:
          allowStructureFallback ?? this.allowStructureFallback,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'default_available_context_chars': defaultAvailableContextChars,
      'source_window_ratio': sourceWindowRatio,
      'min_source_chars': minSourceChars,
      'max_source_chars': maxSourceChars,
      'min_sections_per_batch': minSectionsPerBatch,
      'max_sections_per_batch': maxSectionsPerBatch,
      'instruction_reserve_ratio': instructionReserveRatio,
      'carry_forward_reserve_ratio': carryForwardReserveRatio,
      'response_reserve_ratio': responseReserveRatio,
      'safety_reserve_ratio': safetyReserveRatio,
      'oversize_section_min_chars': oversizeSectionMinChars,
      'planning_mode': planningMode,
      'oversize_section_split_policy': oversizeSectionSplitPolicy,
      'batch_goal_kind': batchGoalKind,
      'allow_structure_fallback': allowStructureFallback,
    };
  }

  static ReferenceIngestionBudgetPolicy fromJson(JsonMap json) {
    return ReferenceIngestionBudgetPolicy(
      defaultAvailableContextChars: ValueReaders.intValue(
        json['default_available_context_chars'],
        12000,
      ),
      sourceWindowRatio: ValueReaders.doubleValue(
        json['source_window_ratio'],
        0.4,
      ),
      minSourceChars: ValueReaders.intValue(json['min_source_chars'], 1600),
      maxSourceChars: ValueReaders.intValue(json['max_source_chars'], 5200),
      minSectionsPerBatch: ValueReaders.intValue(
        json['min_sections_per_batch'],
        1,
      ),
      maxSectionsPerBatch: ValueReaders.intValue(
        json['max_sections_per_batch'],
        4,
      ),
      instructionReserveRatio: ValueReaders.doubleValue(
        json['instruction_reserve_ratio'],
        0.18,
      ),
      carryForwardReserveRatio: ValueReaders.doubleValue(
        json['carry_forward_reserve_ratio'],
        0.08,
      ),
      responseReserveRatio: ValueReaders.doubleValue(
        json['response_reserve_ratio'],
        0.18,
      ),
      safetyReserveRatio: ValueReaders.doubleValue(
        json['safety_reserve_ratio'],
        0.06,
      ),
      oversizeSectionMinChars: ValueReaders.intValue(
        json['oversize_section_min_chars'],
        1200,
      ),
      planningMode: ValueReaders.stringValue(
        json['planning_mode'],
        ReferenceSourceBatchPlanningModes.structureFirst,
      ).trim(),
      oversizeSectionSplitPolicy: ValueReaders.stringValue(
        json['oversize_section_split_policy'],
        ReferenceOversizeSectionSplitPolicies.paragraphClusterPreferred,
      ).trim(),
      batchGoalKind: ValueReaders.stringValue(
        json['batch_goal_kind'],
        ReferenceBatchGoalKinds.semanticExtraction,
      ).trim(),
      allowStructureFallback: ValueReaders.boolValue(
        json['allow_structure_fallback'],
        true,
      ),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (defaultAvailableContextChars < 4000) {
      result.add('invalid_reference_default_available_context_chars');
    }
    if (sourceWindowRatio <= 0 || sourceWindowRatio >= 1) {
      result.add('invalid_reference_source_window_ratio');
    }
    if (minSourceChars <= 0 || maxSourceChars < minSourceChars) {
      result.add('invalid_reference_source_char_bounds');
    }
    if (minSectionsPerBatch <= 0 || maxSectionsPerBatch < minSectionsPerBatch) {
      result.add('invalid_reference_section_batch_bounds');
    }
    final reserveRatioSum =
        instructionReserveRatio +
        carryForwardReserveRatio +
        responseReserveRatio +
        safetyReserveRatio;
    if (reserveRatioSum <= 0 || reserveRatioSum >= 0.9) {
      result.add('invalid_reference_reserve_ratio_sum');
    }
    if (!ReferenceSourceBatchPlanningModes.knownValues.contains(planningMode)) {
      result.add('invalid_reference_batch_planning_mode');
    }
    if (!ReferenceOversizeSectionSplitPolicies.knownValues.contains(
      oversizeSectionSplitPolicy,
    )) {
      result.add('invalid_reference_oversize_section_split_policy');
    }
    if (!ReferenceBatchGoalKinds.knownValues.contains(batchGoalKind)) {
      result.add('invalid_reference_batch_goal_kind');
    }
    return result;
  }
}

class ReferenceIngestionBudgetResolution {
  const ReferenceIngestionBudgetResolution({
    required this.availableContextChars,
    required this.targetSourceChars,
    required this.minSourceChars,
    required this.maxSourceChars,
    required this.minSectionsPerBatch,
    required this.maxSectionsPerBatch,
    required this.instructionReserveChars,
    required this.carryForwardReserveChars,
    required this.responseReserveChars,
    required this.safetyReserveChars,
    this.planningMode = ReferenceSourceBatchPlanningModes.structureFirst,
    this.oversizeSectionSplitPolicy =
        ReferenceOversizeSectionSplitPolicies.paragraphClusterPreferred,
    this.batchGoalKind = ReferenceBatchGoalKinds.semanticExtraction,
    this.allowStructureFallback = true,
  });

  final int availableContextChars;
  final int targetSourceChars;
  final int minSourceChars;
  final int maxSourceChars;
  final int minSectionsPerBatch;
  final int maxSectionsPerBatch;
  final int instructionReserveChars;
  final int carryForwardReserveChars;
  final int responseReserveChars;
  final int safetyReserveChars;
  final String planningMode;
  final String oversizeSectionSplitPolicy;
  final String batchGoalKind;
  final bool allowStructureFallback;

  ReferenceIngestionBudgetResolution copyWith({
    int? availableContextChars,
    int? targetSourceChars,
    int? minSourceChars,
    int? maxSourceChars,
    int? minSectionsPerBatch,
    int? maxSectionsPerBatch,
    int? instructionReserveChars,
    int? carryForwardReserveChars,
    int? responseReserveChars,
    int? safetyReserveChars,
    String? planningMode,
    String? oversizeSectionSplitPolicy,
    String? batchGoalKind,
    bool? allowStructureFallback,
  }) {
    return ReferenceIngestionBudgetResolution(
      availableContextChars:
          availableContextChars ?? this.availableContextChars,
      targetSourceChars: targetSourceChars ?? this.targetSourceChars,
      minSourceChars: minSourceChars ?? this.minSourceChars,
      maxSourceChars: maxSourceChars ?? this.maxSourceChars,
      minSectionsPerBatch: minSectionsPerBatch ?? this.minSectionsPerBatch,
      maxSectionsPerBatch: maxSectionsPerBatch ?? this.maxSectionsPerBatch,
      instructionReserveChars:
          instructionReserveChars ?? this.instructionReserveChars,
      carryForwardReserveChars:
          carryForwardReserveChars ?? this.carryForwardReserveChars,
      responseReserveChars: responseReserveChars ?? this.responseReserveChars,
      safetyReserveChars: safetyReserveChars ?? this.safetyReserveChars,
      planningMode: planningMode ?? this.planningMode,
      oversizeSectionSplitPolicy:
          oversizeSectionSplitPolicy ?? this.oversizeSectionSplitPolicy,
      batchGoalKind: batchGoalKind ?? this.batchGoalKind,
      allowStructureFallback:
          allowStructureFallback ?? this.allowStructureFallback,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'available_context_chars': availableContextChars,
      'target_source_chars': targetSourceChars,
      'min_source_chars': minSourceChars,
      'max_source_chars': maxSourceChars,
      'min_sections_per_batch': minSectionsPerBatch,
      'max_sections_per_batch': maxSectionsPerBatch,
      'instruction_reserve_chars': instructionReserveChars,
      'carry_forward_reserve_chars': carryForwardReserveChars,
      'response_reserve_chars': responseReserveChars,
      'safety_reserve_chars': safetyReserveChars,
      'planning_mode': planningMode,
      'oversize_section_split_policy': oversizeSectionSplitPolicy,
      'batch_goal_kind': batchGoalKind,
      'allow_structure_fallback': allowStructureFallback,
    };
  }

  static ReferenceIngestionBudgetResolution fromJson(JsonMap json) {
    return ReferenceIngestionBudgetResolution(
      availableContextChars: ValueReaders.intValue(
        json['available_context_chars'],
      ),
      targetSourceChars: ValueReaders.intValue(json['target_source_chars']),
      minSourceChars: ValueReaders.intValue(json['min_source_chars']),
      maxSourceChars: ValueReaders.intValue(json['max_source_chars']),
      minSectionsPerBatch: ValueReaders.intValue(
        json['min_sections_per_batch'],
      ),
      maxSectionsPerBatch: ValueReaders.intValue(
        json['max_sections_per_batch'],
      ),
      instructionReserveChars: ValueReaders.intValue(
        json['instruction_reserve_chars'],
      ),
      carryForwardReserveChars: ValueReaders.intValue(
        json['carry_forward_reserve_chars'],
      ),
      responseReserveChars: ValueReaders.intValue(
        json['response_reserve_chars'],
      ),
      safetyReserveChars: ValueReaders.intValue(json['safety_reserve_chars']),
      planningMode: ValueReaders.stringValue(
        json['planning_mode'],
        ReferenceSourceBatchPlanningModes.structureFirst,
      ).trim(),
      oversizeSectionSplitPolicy: ValueReaders.stringValue(
        json['oversize_section_split_policy'],
        ReferenceOversizeSectionSplitPolicies.paragraphClusterPreferred,
      ).trim(),
      batchGoalKind: ValueReaders.stringValue(
        json['batch_goal_kind'],
        ReferenceBatchGoalKinds.semanticExtraction,
      ).trim(),
      allowStructureFallback: ValueReaders.boolValue(
        json['allow_structure_fallback'],
        true,
      ),
    );
  }

  List<String> validateBasics() {
    return ReferenceIngestionBudgetPolicy(
      defaultAvailableContextChars: availableContextChars,
      sourceWindowRatio: availableContextChars <= 0
          ? 0
          : targetSourceChars / availableContextChars,
      minSourceChars: minSourceChars,
      maxSourceChars: maxSourceChars,
      minSectionsPerBatch: minSectionsPerBatch,
      maxSectionsPerBatch: maxSectionsPerBatch,
      instructionReserveRatio: availableContextChars <= 0
          ? 0
          : instructionReserveChars / availableContextChars,
      carryForwardReserveRatio: availableContextChars <= 0
          ? 0
          : carryForwardReserveChars / availableContextChars,
      responseReserveRatio: availableContextChars <= 0
          ? 0
          : responseReserveChars / availableContextChars,
      safetyReserveRatio: availableContextChars <= 0
          ? 0
          : safetyReserveChars / availableContextChars,
      oversizeSectionMinChars: minSourceChars,
      planningMode: planningMode,
      oversizeSectionSplitPolicy: oversizeSectionSplitPolicy,
      batchGoalKind: batchGoalKind,
      allowStructureFallback: allowStructureFallback,
    ).validateBasics();
  }
}
