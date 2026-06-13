import '../agents/agent_task_family.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../output/output_contract_models.dart';
import '../reference_substrate/reference_substrate_constants.dart';
import 'reference_extraction_execution_discipline.dart';
import 'reference_ingestion_budget_policy.dart';

class ReferenceExtractionProposalPolicy {
  const ReferenceExtractionProposalPolicy({
    this.seedEntryLimit = 10,
    this.minProposalCount = 4,
    this.maxProposalCount = 6,
    this.outputLanguage = 'zh-CN',
    this.allowedEntryKinds = const <String>[
      ReferenceEntryKinds.knowledgeFact,
      ReferenceEntryKinds.designElement,
      ReferenceEntryKinds.styleTechnique,
      ReferenceEntryKinds.referenceWorkBoundary,
    ],
  });

  final int seedEntryLimit;
  final int minProposalCount;
  final int maxProposalCount;
  final String outputLanguage;
  final List<String> allowedEntryKinds;

  JsonMap toJson() {
    return <String, Object?>{
      'seed_entry_limit': seedEntryLimit,
      'min_proposal_count': minProposalCount,
      'max_proposal_count': maxProposalCount,
      'output_language': outputLanguage,
      'allowed_entry_kinds': ValueReaders.deepCopyList(
        allowedEntryKinds.cast<Object?>(),
      ),
    };
  }

  static ReferenceExtractionProposalPolicy fromJson(JsonMap json) {
    final allowedEntryKinds = ValueReaders.stringList(
      json['allowed_entry_kinds'],
    );
    final outputLanguage = ValueReaders.stringValue(
      json['output_language'],
      'zh-CN',
    ).trim();
    final seedEntryLimit = ValueReaders.intValue(json['seed_entry_limit'], 10);
    final minProposalCount = ValueReaders.intValue(
      json['min_proposal_count'],
      4,
    );
    final maxProposalCount = ValueReaders.intValue(
      json['max_proposal_count'],
      6,
    );
    return ReferenceExtractionProposalPolicy(
      seedEntryLimit: seedEntryLimit > 0 ? seedEntryLimit : 10,
      minProposalCount: minProposalCount > 0 ? minProposalCount : 4,
      maxProposalCount: maxProposalCount > 0 ? maxProposalCount : 6,
      outputLanguage: outputLanguage.isEmpty ? 'zh-CN' : outputLanguage,
      allowedEntryKinds: allowedEntryKinds.isEmpty
          ? const <String>[
              ReferenceEntryKinds.knowledgeFact,
              ReferenceEntryKinds.designElement,
              ReferenceEntryKinds.styleTechnique,
              ReferenceEntryKinds.referenceWorkBoundary,
            ]
          : allowedEntryKinds,
    );
  }
}

class ReferenceExtractionGenerationPolicy {
  const ReferenceExtractionGenerationPolicy({
    this.temperature = 0.3,
    this.responseFormatType = 'json_object',
  });

  final double temperature;
  final String responseFormatType;

  JsonMap toJson() {
    return <String, Object?>{
      'temperature': temperature,
      'response_format_type': responseFormatType,
    };
  }

  static ReferenceExtractionGenerationPolicy fromJson(JsonMap json) {
    return ReferenceExtractionGenerationPolicy(
      temperature: ValueReaders.doubleValue(json['temperature'], 0.3),
      responseFormatType: ValueReaders.stringValue(
        json['response_format_type'],
        'json_object',
      ).trim(),
    );
  }
}

class ReferenceExtractionReviewPolicy {
  const ReferenceExtractionReviewPolicy({
    this.acceptanceThreshold = 0.78,
    this.candidateThreshold = 0.55,
    this.requireEvidence = true,
  });

  final double acceptanceThreshold;
  final double candidateThreshold;
  final bool requireEvidence;

  JsonMap toJson() {
    return <String, Object?>{
      'acceptance_threshold': acceptanceThreshold,
      'candidate_threshold': candidateThreshold,
      'require_evidence': requireEvidence,
    };
  }

  static ReferenceExtractionReviewPolicy fromJson(JsonMap json) {
    return ReferenceExtractionReviewPolicy(
      acceptanceThreshold: ValueReaders.doubleValue(
        json['acceptance_threshold'],
        0.78,
      ),
      candidateThreshold: ValueReaders.doubleValue(
        json['candidate_threshold'],
        0.55,
      ),
      requireEvidence: ValueReaders.boolValue(json['require_evidence'], true),
    );
  }
}

class ReferenceExtractionStrategyProfile {
  const ReferenceExtractionStrategyProfile({
    this.profileId = 'reference_extraction.standard',
    this.proposalPolicy = const ReferenceExtractionProposalPolicy(),
    this.generationPolicy = const ReferenceExtractionGenerationPolicy(),
    this.reviewPolicy = const ReferenceExtractionReviewPolicy(),
    this.ingestionBudgetPolicy = const ReferenceIngestionBudgetPolicy(),
    this.outputBudgetPolicy = const OutputBudgetPolicy(),
    this.outputCoverageContract = const OutputCoverageContract(),
    this.executionDiscipline = const ReferenceExtractionExecutionDiscipline(),
    this.metadata = const <String, Object?>{},
  });

  final String profileId;
  final ReferenceExtractionProposalPolicy proposalPolicy;
  final ReferenceExtractionGenerationPolicy generationPolicy;
  final ReferenceExtractionReviewPolicy reviewPolicy;
  final ReferenceIngestionBudgetPolicy ingestionBudgetPolicy;
  final OutputBudgetPolicy outputBudgetPolicy;
  final OutputCoverageContract outputCoverageContract;
  final ReferenceExtractionExecutionDiscipline executionDiscipline;
  final JsonMap metadata;

  ReferenceExtractionStrategyProfile copyWith({
    String? profileId,
    ReferenceExtractionProposalPolicy? proposalPolicy,
    ReferenceExtractionGenerationPolicy? generationPolicy,
    ReferenceExtractionReviewPolicy? reviewPolicy,
    ReferenceIngestionBudgetPolicy? ingestionBudgetPolicy,
    OutputBudgetPolicy? outputBudgetPolicy,
    OutputCoverageContract? outputCoverageContract,
    ReferenceExtractionExecutionDiscipline? executionDiscipline,
    JsonMap? metadata,
  }) {
    return ReferenceExtractionStrategyProfile(
      profileId: profileId ?? this.profileId,
      proposalPolicy: proposalPolicy ?? this.proposalPolicy,
      generationPolicy: generationPolicy ?? this.generationPolicy,
      reviewPolicy: reviewPolicy ?? this.reviewPolicy,
      ingestionBudgetPolicy:
          ingestionBudgetPolicy ?? this.ingestionBudgetPolicy,
      outputBudgetPolicy: outputBudgetPolicy ?? this.outputBudgetPolicy,
      outputCoverageContract:
          outputCoverageContract ?? this.outputCoverageContract,
      executionDiscipline: executionDiscipline ?? this.executionDiscipline,
      metadata: metadata ?? this.metadata,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'profile_id': profileId,
      'proposal_policy': proposalPolicy.toJson(),
      'generation_policy': generationPolicy.toJson(),
      'review_policy': reviewPolicy.toJson(),
      'ingestion_budget_policy': ingestionBudgetPolicy.toJson(),
      'output_budget_policy': outputBudgetPolicy.toJson(),
      'output_coverage_contract': outputCoverageContract.toJson(),
      'execution_discipline': executionDiscipline.toJson(),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceExtractionStrategyProfile fromJson(JsonMap json) {
    return ReferenceExtractionStrategyProfile(
      profileId: ValueReaders.stringValue(
        json['profile_id'],
        ReferenceExtractionStrategyProfiles.standard.profileId,
      ).trim(),
      proposalPolicy: ReferenceExtractionProposalPolicy.fromJson(
        ValueReaders.mapValue(json['proposal_policy']),
      ),
      generationPolicy: ReferenceExtractionGenerationPolicy.fromJson(
        ValueReaders.mapValue(json['generation_policy']),
      ),
      reviewPolicy: ReferenceExtractionReviewPolicy.fromJson(
        ValueReaders.mapValue(json['review_policy']),
      ),
      ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy.fromJson(
        ValueReaders.mapValue(json['ingestion_budget_policy']),
      ),
      outputBudgetPolicy: OutputBudgetPolicy.fromJson(
        ValueReaders.mapValue(json['output_budget_policy']),
      ),
      outputCoverageContract: OutputCoverageContract.fromJson(
        ValueReaders.mapValue(json['output_coverage_contract']),
      ),
      executionDiscipline: ReferenceExtractionExecutionDiscipline.fromJson(
        ValueReaders.mapValue(json['execution_discipline']),
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

abstract final class ReferenceExtractionCoverageDimensions {
  static const OutputCoverageDimension characterFact = OutputCoverageDimension(
    dimensionId: 'character_fact',
    label: '角色事实',
    description: '角色身份、关系、动机或稳定行为事实。',
    minItemCount: 1,
    required: true,
  );

  static const OutputCoverageDimension settingOrObject =
      OutputCoverageDimension(
        dimensionId: 'setting_or_object',
        label: '地点组织物件',
        description: '地点、组织、关键物件或命名实体。',
        minItemCount: 1,
        required: true,
      );

  static const OutputCoverageDimension plotOrMechanism =
      OutputCoverageDimension(
        dimensionId: 'plot_or_mechanism',
        label: '剧情机关与世界机制',
        description: '剧情推进机关、规则、设定机制或因果线索。',
        minItemCount: 1,
        required: true,
      );

  static const OutputCoverageDimension styleOrTechnique =
      OutputCoverageDimension(
        dimensionId: 'style_or_technique',
        label: '风格手法',
        description: '叙事视角、修辞、节奏或风格手法。',
        minItemCount: 1,
      );

  static const OutputCoverageDimension timelineOrBoundary =
      OutputCoverageDimension(
        dimensionId: 'timeline_or_boundary',
        label: '阶段边界与使用边界',
        description: '阶段边界、时间线节点或引用边界提示。',
        minItemCount: 1,
      );
}

abstract final class ReferenceExtractionOutputContracts {
  static const OutputCoverageContract standard = OutputCoverageContract(
    contractId: 'reference_extraction.standard',
    taskFamilyId: AgentTaskFamilies.referenceExtraction,
    dimensions: <OutputCoverageDimension>[
      ReferenceExtractionCoverageDimensions.characterFact,
      ReferenceExtractionCoverageDimensions.settingOrObject,
      ReferenceExtractionCoverageDimensions.plotOrMechanism,
      ReferenceExtractionCoverageDimensions.styleOrTechnique,
      ReferenceExtractionCoverageDimensions.timelineOrBoundary,
    ],
    minCoveredDimensions: 3,
    requireExplicitCoverageSignals: true,
    allowContinuationWhenIncomplete: true,
  );
}

abstract final class ReferenceExtractionStrategyProfiles {
  static const ReferenceExtractionStrategyProfile standard =
      ReferenceExtractionStrategyProfile(
        outputBudgetPolicy: OutputBudgetPolicy(
          minOutputSlots: 4,
          maxOutputSlots: 6,
          maxSummaryCharsPerItem: 160,
          mustReportOmissions: true,
          continuationAllowed: true,
        ),
        outputCoverageContract: ReferenceExtractionOutputContracts.standard,
        ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy(
          defaultAvailableContextChars: 32000,
          sourceWindowRatio: 0.4,
          minSourceChars: 2200,
          maxSourceChars: 52000,
          maxSectionsPerBatch: 3,
          oversizeSectionMinChars: 2600,
        ),
        metadata: <String, Object?>{
          'display_name': '标准提取',
          'summary': '兼顾知识、设计和引用边界，适合作为默认提取策略。',
        },
      );

  static const ReferenceExtractionStrategyProfile bulkLongContext =
      ReferenceExtractionStrategyProfile(
        profileId: ReferenceExtractionBuiltinStrategyProfileIds.bulkLongContext,
        proposalPolicy: ReferenceExtractionProposalPolicy(
          seedEntryLimit: 16,
          minProposalCount: 5,
          maxProposalCount: 8,
        ),
        outputBudgetPolicy: OutputBudgetPolicy(
          minOutputSlots: 5,
          maxOutputSlots: 8,
          maxSummaryCharsPerItem: 180,
          mustReportOmissions: true,
          continuationAllowed: true,
        ),
        outputCoverageContract: ReferenceExtractionOutputContracts.standard,
        generationPolicy: ReferenceExtractionGenerationPolicy(
          temperature: 0.28,
        ),
        reviewPolicy: ReferenceExtractionReviewPolicy(
          acceptanceThreshold: 0.76,
          candidateThreshold: 0.54,
        ),
        ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy(
          defaultAvailableContextChars: 131072,
          sourceWindowRatio: 0.54,
          minSourceChars: 2800,
          maxSourceChars: 82000,
          maxSectionsPerBatch: 4,
          instructionReserveRatio: 0.13,
          carryForwardReserveRatio: 0.05,
          responseReserveRatio: 0.08,
          safetyReserveRatio: 0.04,
          oversizeSectionMinChars: 3200,
        ),
        metadata: <String, Object?>{
          'display_name': '长上下文整书',
          'summary': '面向高上下文模型的长文档提取，尽量减少整书级批次数，同时保持结构优先与单路执行。',
        },
      );

  static const ReferenceExtractionStrategyProfile factFocused =
      ReferenceExtractionStrategyProfile(
        profileId: ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
        proposalPolicy: ReferenceExtractionProposalPolicy(
          seedEntryLimit: 8,
          minProposalCount: 3,
          maxProposalCount: 4,
          allowedEntryKinds: <String>[
            ReferenceEntryKinds.knowledgeFact,
            ReferenceEntryKinds.referenceWorkBoundary,
          ],
        ),
        outputBudgetPolicy: OutputBudgetPolicy(
          minOutputSlots: 3,
          maxOutputSlots: 4,
          maxSummaryCharsPerItem: 140,
          mustReportOmissions: true,
          continuationAllowed: true,
        ),
        outputCoverageContract: OutputCoverageContract(
          contractId: 'reference_extraction.fact_focused',
          dimensions: <OutputCoverageDimension>[
            ReferenceExtractionCoverageDimensions.characterFact,
            ReferenceExtractionCoverageDimensions.plotOrMechanism,
            ReferenceExtractionCoverageDimensions.timelineOrBoundary,
          ],
          minCoveredDimensions: 2,
          requireExplicitCoverageSignals: true,
          allowContinuationWhenIncomplete: true,
        ),
        generationPolicy: ReferenceExtractionGenerationPolicy(temperature: 0.2),
        reviewPolicy: ReferenceExtractionReviewPolicy(
          acceptanceThreshold: 0.82,
          candidateThreshold: 0.62,
        ),
        ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy(
          defaultAvailableContextChars: 28000,
          sourceWindowRatio: 0.34,
          minSourceChars: 1800,
          maxSourceChars: 36000,
          maxSectionsPerBatch: 3,
          oversizeSectionMinChars: 2200,
        ),
        metadata: <String, Object?>{
          'display_name': '事实优先',
          'summary': '收紧候选范围，优先沉淀可核对的事实和引用边界。',
        },
      );

  static const ReferenceExtractionStrategyProfile exploratory =
      ReferenceExtractionStrategyProfile(
        profileId: ReferenceExtractionBuiltinStrategyProfileIds.exploratory,
        proposalPolicy: ReferenceExtractionProposalPolicy(
          seedEntryLimit: 14,
          minProposalCount: 5,
          maxProposalCount: 8,
        ),
        outputBudgetPolicy: OutputBudgetPolicy(
          minOutputSlots: 5,
          maxOutputSlots: 8,
          maxSummaryCharsPerItem: 190,
          mustReportOmissions: true,
          continuationAllowed: true,
          targetOutputDensity: OutputDensityModes.detailFirst,
        ),
        outputCoverageContract: ReferenceExtractionOutputContracts.standard,
        generationPolicy: ReferenceExtractionGenerationPolicy(
          temperature: 0.45,
        ),
        reviewPolicy: ReferenceExtractionReviewPolicy(
          acceptanceThreshold: 0.72,
          candidateThreshold: 0.5,
        ),
        ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy(
          defaultAvailableContextChars: 36000,
          sourceWindowRatio: 0.44,
          minSourceChars: 2400,
          maxSourceChars: 62000,
          maxSectionsPerBatch: 4,
          oversizeSectionMinChars: 2800,
        ),
        metadata: <String, Object?>{
          'display_name': '探索扩展',
          'summary': '放宽候选范围，鼓励挖掘结构、笔法和更多潜在线索。',
        },
      );
}

abstract final class ReferenceExtractionBuiltinStrategyProfileIds {
  static const String standard = 'reference_extraction.standard';
  static const String bulkLongContext =
      'reference_extraction.bulk_long_context';
  static const String factFocused = 'reference_extraction.fact_focused';
  static const String exploratory = 'reference_extraction.exploratory';
}
