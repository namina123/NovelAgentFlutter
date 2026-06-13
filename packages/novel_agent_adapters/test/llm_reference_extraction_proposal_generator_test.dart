import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LlmReferenceExtractionProposalGenerator', () {
    test(
      'applies strategy profile to prompt, request options and proposal filtering',
      () async {
        final gateway = _RecordingGateway(
          responseContent: '''
{
  "proposals": [
    {
      "proposal_id": "proposal_fact_a",
      "entry_id": "fact_a",
      "entry_namespace": "semantic_extraction",
      "entry_kind": "knowledge_fact",
      "title": "可接受事实 A",
      "summary": "摘要 A",
      "seed_entry_ids": ["seed_a"],
      "coverage_dimension_ids": ["character_fact"],
      "tags": ["fact"],
      "confidence": 0.91
    },
    {
      "proposal_id": "proposal_style_b",
      "entry_id": "style_b",
      "entry_namespace": "semantic_extraction",
      "entry_kind": "style_technique",
      "title": "应被策略过滤",
      "summary": "摘要 B",
      "seed_entry_ids": ["seed_b"],
      "coverage_dimension_ids": ["style_or_technique"],
      "tags": ["style"],
      "confidence": 0.88
    },
    {
      "proposal_id": "proposal_fact_c",
      "entry_id": "fact_c",
      "entry_namespace": "semantic_extraction",
      "entry_kind": "knowledge_fact",
      "title": "可接受事实 C",
      "summary": "摘要 C",
      "seed_entry_ids": ["seed_b"],
      "coverage_dimension_ids": ["plot_or_mechanism"],
      "tags": ["fact"],
      "confidence": 0.87
    }
  ]
}
''',
        );
        final generator = LlmReferenceExtractionProposalGenerator(
          llmGateway: gateway,
          modelId: 'deepseek-v4-flash',
        );

        final result = await generator.generateProposals(
          ReferenceExtractionProposalGeneratorRequest(
            runId: 'run_1',
            sourceDocumentTitle: 'Harry Potter Sample',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
            seedSnapshot: _seedSnapshot(),
            groupResolution: _groupResolution(
              const ReferenceExtractionStrategyProfile(
                profileId: 'reference_extraction.tight_fact_only',
                proposalPolicy: ReferenceExtractionProposalPolicy(
                  seedEntryLimit: 1,
                  minProposalCount: 1,
                  maxProposalCount: 1,
                  outputLanguage: 'zh-CN',
                  allowedEntryKinds: <String>[
                    ReferenceEntryKinds.knowledgeFact,
                  ],
                ),
                generationPolicy: ReferenceExtractionGenerationPolicy(
                  temperature: 0.15,
                  responseFormatType: 'json_object',
                ),
                outputBudgetPolicy: OutputBudgetPolicy(),
                outputCoverageContract:
                    ReferenceExtractionOutputContracts.standard,
              ),
            ),
            batchPlan: _batchPlan(),
            batchProgress: _batchProgress(),
            batch: _batchPlan().batches.first,
          ),
        );

        expect(result.proposals, hasLength(1));
        expect(
          result.proposals.single.entryKind,
          ReferenceEntryKinds.knowledgeFact,
        );
        expect(result.proposals.single.coverageDimensionIds, <String>[
          'character_fact',
        ]);
        expect(gateway.lastRequest, isNotNull);
        expect(gateway.lastRequest!.options['temperature'], 0.15);
        expect(
          ValueReaders.stringValue(
            gateway.lastRequest!.messages.single['content'],
          ),
          allOf(
            contains('生成 1 到 1 条'),
            contains('strategy_profile=reference_extraction.tight_fact_only'),
            contains('coverage_dimension_ids'),
            contains('output_min_slots=4'),
            contains('   - knowledge_fact'),
            isNot(contains('style_technique')),
          ),
        );
      },
    );

    test(
      'retries without structured response format after empty response',
      () async {
        final gateway = _RecordingGateway(
          responses: <String>[
            '',
            '''
{
  "proposals": [
    {
      "proposal_id": "proposal_fact_retry",
      "entry_id": "fact_retry",
      "entry_namespace": "semantic_extraction",
      "entry_kind": "knowledge_fact",
      "title": "重试后成功",
      "summary": "二次请求拿到有效 JSON。",
      "seed_entry_ids": ["seed_a"],
      "coverage_dimension_ids": ["character_fact"],
      "tags": ["retry"],
      "confidence": 0.7
    }
  ]
}
''',
          ],
        );
        final generator = LlmReferenceExtractionProposalGenerator(
          llmGateway: gateway,
          modelId: 'deepseek-v4-flash',
        );

        final result = await generator.generateProposals(
          ReferenceExtractionProposalGeneratorRequest(
            runId: 'run_retry',
            sourceDocumentTitle: 'Harry Potter Sample',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
            seedSnapshot: _seedSnapshot(),
            groupResolution: _groupResolution(
              ReferenceExtractionStrategyProfiles.standard,
            ),
            batchPlan: _batchPlan(),
            batchProgress: _batchProgress(),
            batch: _batchPlan().batches.first,
          ),
        );

        expect(result.proposals, hasLength(1));
        expect(gateway.requests, hasLength(2));
        expect(
          gateway.requests.first.options.containsKey('response_format'),
          isTrue,
        );
        expect(
          gateway.requests.last.options.containsKey('response_format'),
          isFalse,
        );
      },
    );

    test(
      'repairs bare quotes inside proposal strings before decoding',
      () async {
        final gateway = _RecordingGateway(
          responseContent: '''
{
  "proposals": [
    {
      "proposal_id": "proposal_fact_quote",
      "entry_id": "fact_quote",
      "entry_namespace": "semantic_extraction",
      "entry_kind": "knowledge_fact",
      "title": "开锁咒线索",
      "summary": "赫敏在逃离时使用咒语"Alohomora"打开门锁。",
      "seed_entry_ids": ["seed_a"],
      "coverage_dimension_ids": ["plot_or_mechanism"],
      "tags": ["spell"],
      "confidence": 0.78
    }
  ]
}
''',
        );
        final generator = LlmReferenceExtractionProposalGenerator(
          llmGateway: gateway,
          modelId: 'deepseek-v4-flash',
        );

        final result = await generator.generateProposals(
          ReferenceExtractionProposalGeneratorRequest(
            runId: 'run_bare_quotes',
            sourceDocumentTitle: 'Harry Potter Sample',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
            seedSnapshot: _seedSnapshot(),
            groupResolution: _groupResolution(
              ReferenceExtractionStrategyProfiles.standard,
            ),
            batchPlan: _batchPlan(),
            batchProgress: _batchProgress(),
            batch: _batchPlan().batches.first,
          ),
        );

        expect(result.proposals, hasLength(1));
        expect(result.proposals.single.summary, contains('"Alohomora"'));
        expect(gateway.requests, hasLength(1));
      },
    );

    test(
      'accepts omission report and continuation request without proposals',
      () async {
        final gateway = _RecordingGateway(
          responseContent: '''
{
  "proposals": [],
  "omission_report": {
    "report_id": "omission_1",
    "omitted_dimension_ids": ["plot_or_mechanism", "setting_or_object"],
    "reason_code": "output_budget_exhausted",
    "summary": "当前批次输出空间不足，未能展开关键机制与地点细节。",
    "recommended_next_focus": "补提命名地点与关键机制。"
  },
  "continuation_request": {
    "request_id": "continue_1",
    "continuation_reason": "仍有多个维度未覆盖",
    "missing_dimension_ids": ["plot_or_mechanism", "setting_or_object"],
    "recommended_next_focus": "优先补提关键机制与地点。",
    "suggested_slot_count": 2
  }
}
''',
        );
        final generator = LlmReferenceExtractionProposalGenerator(
          llmGateway: gateway,
          modelId: 'deepseek-v4-flash',
        );

        final result = await generator.generateProposals(
          ReferenceExtractionProposalGeneratorRequest(
            runId: 'run_contract_only',
            sourceDocumentTitle: 'Harry Potter Sample',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
            seedSnapshot: _seedSnapshot(),
            groupResolution: _groupResolution(
              ReferenceExtractionStrategyProfiles.standard,
            ),
            batchPlan: _batchPlan(),
            batchProgress: _batchProgress(),
            batch: _batchPlan().batches.first,
          ),
        );

        expect(result.proposals, isEmpty);
        expect(result.omissionReport, isNotNull);
        expect(result.omissionReport!.omittedDimensionIds, <String>[
          'plot_or_mechanism',
          'setting_or_object',
        ]);
        expect(result.continuationRequest, isNotNull);
        expect(result.continuationRequest!.missingDimensionIds, <String>[
          'plot_or_mechanism',
          'setting_or_object',
        ]);
      },
    );

    test(
      'treats explicit no-op omission and continuation placeholders as settled instead of technical failure',
      () async {
        final gateway = _RecordingGateway(
          responseContent: '''
{
  "proposals": [],
  "omission_report": {
    "report_id": "omit_none",
    "omitted_dimension_ids": [],
    "reason_code": "no_omission",
    "summary": "本批次没有新的遗漏项。",
    "recommended_next_focus": ""
  },
  "continuation_request": {
    "request_id": "continue_none",
    "continuation_reason": "no_continuation",
    "missing_dimension_ids": [],
    "recommended_next_focus": "",
    "suggested_slot_count": 0
  }
}
''',
        );
        final generator = LlmReferenceExtractionProposalGenerator(
          llmGateway: gateway,
          modelId: 'deepseek-v4-flash',
        );

        final result = await generator.generateProposals(
          ReferenceExtractionProposalGeneratorRequest(
            runId: 'run_noop_contract',
            sourceDocumentTitle: 'Harry Potter Sample',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
            seedSnapshot: _seedSnapshot(),
            groupResolution: _groupResolution(
              ReferenceExtractionStrategyProfiles.standard,
            ),
            batchPlan: _batchPlan(),
            batchProgress: _batchProgress(),
            batch: _batchPlan().batches.first,
          ),
        );

        expect(result.proposals, isEmpty);
        expect(result.omissionReport, isNull);
        expect(result.continuationRequest, isNull);
      },
    );

    test(
      'rejects proposal when filtered coverage dimensions become empty',
      () async {
        final gateway = _RecordingGateway(
          responseContent: '''
{
  "proposals": [
    {
      "proposal_id": "proposal_invalid_coverage",
      "entry_id": "fact_invalid_coverage",
      "entry_namespace": "semantic_extraction",
      "entry_kind": "knowledge_fact",
      "title": "看起来合法但 coverage 无效",
      "summary": "这条提案没有落在合同允许的 coverage 维度内。",
      "seed_entry_ids": ["seed_a"],
      "coverage_dimension_ids": ["unknown_dimension"],
      "tags": ["fact"],
      "confidence": 0.88
    }
  ]
}
''',
        );
        final generator = LlmReferenceExtractionProposalGenerator(
          llmGateway: gateway,
          modelId: 'deepseek-v4-flash',
        );

        await expectLater(
          generator.generateProposals(
            ReferenceExtractionProposalGeneratorRequest(
              runId: 'run_invalid_coverage',
              sourceDocumentTitle: 'Harry Potter Sample',
              sourceLanguage: 'en',
              targetLanguage: 'zh-CN',
              seedSnapshot: _seedSnapshot(),
              groupResolution: _groupResolution(
                ReferenceExtractionStrategyProfiles.standard,
              ),
              batchPlan: _batchPlan(),
              batchProgress: _batchProgress(),
              batch: _batchPlan().batches.first,
            ),
          ),
          throwsStateError,
        );
      },
    );
  });
}

ReferencePackageSnapshot _seedSnapshot() {
  final sourceRef = InformationSourceRef(
    sourceRef: const NarrativeSourceRef(
      sourceType: 'source_document',
      sourceId: 'hp_sample',
      label: 'Harry Potter Sample',
    ),
    sourceAuthority: InformationSourceAuthorities.sourceDocument,
    roleAuthority: InformationRoleAuthorities.deconstructor,
    researchDepth: InformationResearchDepths.deep,
  );
  return ReferencePackageSnapshot(
    packageRecord: const ReferencePackageRecord(
      packageId: 'pkg_hp',
      packageKind: ReferencePackageKinds.referenceWorkPackage,
      displayName: '样本文稿',
      latestVersionId: 'v1',
      lifecycleStatus: 'active',
      createdAt: '2026-06-08T02:00:00Z',
      updatedAt: '2026-06-08T02:00:00Z',
    ),
    packageVersionRecord: const ReferencePackageVersionRecord(
      packageVersionId: 'v1',
      packageId: 'pkg_hp',
      versionLabel: 'seed',
      createdAt: '2026-06-08T02:00:00Z',
      createdBy: 'test',
    ),
    entries: <ReferenceEntryRecord>[
      ReferenceEntryRecord(
        entryId: 'seed_a',
        packageId: 'pkg_hp',
        packageVersionId: 'v1',
        entryNamespace: 'seed',
        entryKind: ReferenceEntryKinds.knowledgeFact,
        title: 'Seed A',
        summary: 'Seed A summary',
        payload: const <String, Object?>{'section_index': 1},
        sourceRefs: <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(),
        usagePolicy: const InformationUsagePolicy(),
        confidence: 0.8,
        lifecycleStatus: 'active',
      ),
      ReferenceEntryRecord(
        entryId: 'seed_b',
        packageId: 'pkg_hp',
        packageVersionId: 'v1',
        entryNamespace: 'seed',
        entryKind: ReferenceEntryKinds.knowledgeFact,
        title: 'Seed B',
        summary: 'Seed B summary',
        payload: const <String, Object?>{'section_index': 2},
        sourceRefs: <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(),
        usagePolicy: const InformationUsagePolicy(),
        confidence: 0.8,
        lifecycleStatus: 'active',
      ),
    ],
  );
}

ReferenceSourceBatchPlan _batchPlan() {
  return const ReferenceSourceBatchPlan(
    planId: 'plan_1',
    structureMode: ReferenceSourceDocumentStructureKinds.explicitChapter,
    totalSourceChars: 120,
    totalSectionCount: 2,
    budgetResolution: ReferenceIngestionBudgetResolution(
      availableContextChars: 8000,
      targetSourceChars: 600,
      minSourceChars: 300,
      maxSourceChars: 900,
      minSectionsPerBatch: 1,
      maxSectionsPerBatch: 2,
      instructionReserveChars: 1000,
      carryForwardReserveChars: 500,
      responseReserveChars: 1000,
      safetyReserveChars: 300,
    ),
    batches: <ReferenceSourceBatch>[
      ReferenceSourceBatch(
        batchId: 'batch_001',
        batchIndex: 1,
        structureMode: ReferenceSourceDocumentStructureKinds.explicitChapter,
        splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
        sourceText: 'CHAPTER ONE\nHarry met Hagrid.',
        sectionIds: <String>['section_001'],
        sectionIndexes: <int>[1],
        headings: <String>['CHAPTER ONE'],
      ),
    ],
  );
}

ReferenceSourceBatchProgress _batchProgress() {
  return const ReferenceSourceBatchProgress(
    planId: 'plan_1',
    totalBatches: 1,
    totalSourceChars: 120,
    items: <ReferenceSourceBatchProgressItem>[
      ReferenceSourceBatchProgressItem(
        batchId: 'batch_001',
        status: ReferenceSourceBatchStatuses.pending,
        sectionIds: <String>['section_001'],
        charCount: 30,
      ),
    ],
  );
}

ReferenceExtractionGroupResolution _groupResolution(
  ReferenceExtractionStrategyProfile strategyProfile,
) {
  return ReferenceExtractionGroupResolution(
    selectedGroup: const ResolvedAgentGroupProfile(
      id: 'reference_extraction_group',
      name: '参考提取组',
      description: '测试组',
      orchestration: 'supervised',
      members: <ResolvedAgentGroupMemberProfile>[
        ResolvedAgentGroupMemberProfile(
          profile: AgentProfile(
            id: 'extractor',
            name: 'Extractor',
            description: '提取智能体',
          ),
          isPrimary: true,
          isRequired: true,
        ),
      ],
    ),
    resolutionKind: ReferenceExtractionResolutionKinds.capableGroup,
    executionProfile: ReferenceExtractionExecutionProfile(
      taskFamilyId: AgentTaskFamilies.referenceExtraction,
      executionMode: ReferenceExtractionExecutionModes.group,
      instructionProfileId: ReferenceExtractionPromptProfiles.group,
      toolPermissionProfileId:
          ReferenceExtractionToolPermissionProfiles.standard,
      strategyProfile: strategyProfile,
    ),
  );
}

class _RecordingGateway implements LlmGateway {
  _RecordingGateway({String responseContent = '', List<String>? responses})
    : _responses = responses ?? <String>[responseContent];

  final List<String> _responses;
  ChatRequest? lastRequest;
  final List<ChatRequest> requests = <ChatRequest>[];

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    lastRequest = request;
    requests.add(request);
    final next = _responses.length > requests.length - 1
        ? _responses[requests.length - 1]
        : _responses.last;
    return <String, Object?>{'content': next};
  }

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) {
    throw UnimplementedError();
  }
}
