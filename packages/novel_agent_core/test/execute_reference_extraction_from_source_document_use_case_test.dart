import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExecuteReferenceExtractionFromSourceDocumentUseCase', () {
    test(
      'runs deterministic seed proposal review finalize chain without polluting final snapshot',
      () async {
        final substrate = _MemoryReferenceEvidenceSubstrate();
        final stagingWorkspace = _MemoryReferenceExtractionStagingWorkspace();
        final proposalGenerator = _FakeProposalGenerator();
        final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
          substrate: substrate,
          stagingWorkspace: stagingWorkspace,
          proposalGenerator: proposalGenerator,
        );
        final extractionGroup = ResolvedAgentGroupProfile(
          id: 'extraction-room',
          name: '提取组',
          description: '参考资产提取职责组',
          orchestration: 'supervised',
          metadata: const <String, Object?>{
            'task_family_ids': <String>[AgentTaskFamilies.referenceExtraction],
          },
          members: const <ResolvedAgentGroupMemberProfile>[
            ResolvedAgentGroupMemberProfile(
              profile: AgentProfile(
                id: 'extractor',
                name: '提取主智能体',
                description: '负责语义提取',
              ),
              isPrimary: true,
              isRequired: true,
            ),
          ],
        );

        final result = await useCase.execute(
          ReferenceExtractionRunRequest(
            runId: 'run-hp-1',
            finalizedAt: '2026-06-07T16:00:00Z',
            finalizedBy: 'tester',
            finalizedPackageVersionId: 'v1.final',
            finalizedVersionLabel: '1.0 final',
            sourceDocumentRequest: const ReferenceSourceDocumentIngestionRequest(
              sourceText:
                  'Chapter One\nHarry Potter met Hagrid at Hogwarts. Harry saw the castle lights.\n\nChapter Two\nHagrid explained the wizard world to Harry Potter.',
              sourceTitle: 'Harry Potter Sample',
              packageId: 'pkg.hp',
              packageKind: ReferencePackageKinds.referenceWorkPackage,
              displayName: '哈利波特参考包',
              packageVersionId: 'v1.seed',
              versionLabel: '1.0 seed',
              createdAt: '2026-06-07T15:00:00Z',
              sourceLanguage: 'en',
              targetLanguage: 'zh-CN',
            ),
            groupSelections: const <ProjectAgentGroupSelection>[
              ProjectAgentGroupSelection(
                groupId: 'writing-room',
                selectedByDefault: true,
              ),
              ProjectAgentGroupSelection(
                groupId: 'extraction-room',
                taskFamilyIds: <String>[AgentTaskFamilies.referenceExtraction],
              ),
            ],
            groupAssessments: <AgentGroupAvailabilityAssessment>[
              AgentGroupAvailabilityAssessment(
                group: extractionGroup,
                isSupported: true,
                isDegraded: false,
                supportedMembers: extractionGroup.members,
              ),
            ],
            strategyProfileId: 'reference_extraction.custom_dense',
            additionalStrategyProfiles:
                const <ReferenceExtractionStrategyProfile>[
                  ReferenceExtractionStrategyProfile(
                    profileId: 'reference_extraction.custom_dense',
                    proposalPolicy: ReferenceExtractionProposalPolicy(
                      minProposalCount: 6,
                      maxProposalCount: 9,
                    ),
                    reviewPolicy: ReferenceExtractionReviewPolicy(
                      acceptanceThreshold: 0.8,
                      candidateThreshold: 0.6,
                    ),
                    executionDiscipline: ReferenceExtractionExecutionDiscipline(
                      concurrencyMode:
                          ReferenceExtractionConcurrencyModes.reservedParallel,
                      maxConcurrentBatches: 3,
                      allowParallelHeavyTextConsumption: true,
                    ),
                  ),
                ],
          ),
        );

        expect(
          result.stagingRun.phaseRecords.map((entry) => entry.phaseId),
          <String>[
            ReferenceExtractionWorkflowPhases.seedExtraction,
            ReferenceExtractionWorkflowPhases.groupResolution,
            ReferenceExtractionWorkflowPhases.batchPlanning,
            ReferenceExtractionWorkflowPhases.batchExecution,
            ReferenceExtractionWorkflowPhases.proposalGeneration,
            ReferenceExtractionWorkflowPhases.reviewGate,
            ReferenceExtractionWorkflowPhases.packageFinalize,
          ],
        );
        expect(proposalGenerator.callCount, 1);
        expect(result.stagingRun.batchPlan, isNotNull);
        expect(result.stagingRun.batchProgress, isNotNull);
        expect(result.stagingRun.batchPlan!.batches, hasLength(1));
        expect(result.stagingRun.batchProgress!.completedBatchCount, 1);
        expect(result.stagingRun.batchProgress!.coverageRatio, 1);
        expect(
          result.stagingRun.executionDiscipline.concurrencyMode,
          ReferenceExtractionConcurrencyModes.single,
        );
        expect(result.groupResolution.selectedGroup.id, 'extraction-room');
        expect(
          result.groupResolution.executionProfile.strategyProfile.profileId,
          'reference_extraction.custom_dense',
        );
        expect(result.reviewOutcome.acceptedProposalIds, <String>[
          'proposal-fact',
        ]);
        expect(
          result.reviewOutcome.outputCompletionStatus,
          OutputCompletionStatuses.continuationRecommended,
        );
        expect(result.reviewOutcome.needsContinuation, isTrue);
        expect(result.reviewOutcome.omissionReports, hasLength(1));
        expect(result.reviewOutcome.continuationRequests, hasLength(1));
        expect(
          result.reviewOutcome.outputCompressionRisk.level,
          OutputCompressionRiskLevels.high,
        );
        expect(
          result.deliveryDecision.deliveryStatus,
          ReferenceExtractionDeliveryStatuses.stagingOnly,
        );
        expect(result.finalizedSnapshot, isNull);

        final stagedRun = await stagingWorkspace.readRun('run-hp-1');
        expect(stagedRun, isNotNull);
        expect(stagedRun!.proposals, hasLength(3));
        expect(stagedRun.reviewOutcome, isNotNull);
        expect(stagedRun.deliveryDecision.requiresStagingOnly, isTrue);
        expect(stagedRun.finalizedSnapshot, isNull);
        expect(
          stagedRun.outputCompletionStatus,
          OutputCompletionStatuses.continuationRecommended,
        );
        expect(stagedRun.omissionReports, hasLength(1));
        expect(stagedRun.continuationRequests, hasLength(1));
        expect(substrate.savedSnapshots, isEmpty);
        final batchState = await substrate.readBatchExecutionState(
          packageId: 'pkg.hp',
          packageVersionId: 'v1.seed',
        );
        expect(batchState, isNotNull);
        expect(batchState!.coverageState, isNotNull);
        expect(
          batchState.coverageState!.uncoveredDimensionIds,
          contains('character_fact'),
        );
        expect(
          batchState.metadata['run_status'],
          ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
        );
      },
    );

    test(
      'resumes incomplete batch execution from staging without rerunning completed batches',
      () async {
        final substrate = _MemoryReferenceEvidenceSubstrate();
        final stagingWorkspace = _MemoryReferenceExtractionStagingWorkspace();
        final proposalGenerator = _ResumeAwareProposalGenerator();
        final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
          substrate: substrate,
          stagingWorkspace: stagingWorkspace,
          proposalGenerator: proposalGenerator,
        );

        final longChapterA = List<String>.filled(320, 'A').join(' ');
        final longChapterB = List<String>.filled(320, 'B').join(' ');
        final request = ReferenceExtractionRunRequest(
          runId: 'resume-run',
          finalizedAt: '2026-06-08T10:00:00Z',
          finalizedBy: 'tester',
          finalizedPackageVersionId: 'v.resume',
          finalizedVersionLabel: 'resume-final',
          sourceDocumentRequest: ReferenceSourceDocumentIngestionRequest(
            sourceText:
                '''
CHAPTER ONE
$longChapterA

CHAPTER TWO
$longChapterB
''',
            sourceTitle: 'Resume Sample',
            packageId: 'pkg.resume',
            packageKind: ReferencePackageKinds.referenceWorkPackage,
            displayName: '断点续跑测试包',
            packageVersionId: 'v.seed',
            versionLabel: 'seed',
            createdAt: '2026-06-08T09:00:00Z',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
          ),
          strategyProfileId: 'reference_extraction.resume_dense',
          additionalStrategyProfiles:
              const <ReferenceExtractionStrategyProfile>[
                ReferenceExtractionStrategyProfile(
                  profileId: 'reference_extraction.resume_dense',
                  ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy(
                    defaultAvailableContextChars: 10000,
                    sourceWindowRatio: 0.32,
                    minSourceChars: 500,
                    maxSourceChars: 900,
                    maxSectionsPerBatch: 1,
                    oversizeSectionMinChars: 400,
                  ),
                ),
              ],
          agentAssessments: const <AgentAvailabilityAssessment>[
            AgentAvailabilityAssessment(
              profile: AgentProfile(
                id: 'resume-agent',
                name: 'Resume Agent',
                description: '用于验证 reference extraction 断点续跑。',
              ),
              isSupported: true,
            ),
          ],
        );

        await expectLater(useCase.execute(request), throwsStateError);
        final partialRun = await stagingWorkspace.readRun('resume-run');
        expect(partialRun, isNotNull);
        expect(partialRun!.batchProgress, isNotNull);
        expect(partialRun.batchProgress!.completedBatchCount, 1);
        expect(
          partialRun.batchProgress!.items.where(
            (item) => item.status == ReferenceSourceBatchStatuses.failed,
          ),
          hasLength(1),
        );
        expect(proposalGenerator.seenBatchIds, <String>[
          'batch_001',
          'batch_002',
        ]);

        final result = await useCase.execute(request);

        expect(result.stagingRun.batchProgress!.completedBatchCount, 2);
        expect(result.stagingRun.batchProgress!.failedBatchCount, 0);
        expect(result.stagingRun.batchProgress!.coverageRatio, 1);
        expect(
          result.stagingRun.phaseRecords.any(
            (record) => record.detail.contains('resume:1/2'),
          ),
          isTrue,
        );
        expect(proposalGenerator.seenBatchIds, <String>[
          'batch_001',
          'batch_002',
          'batch_002',
        ]);
        expect(
          proposalGenerator.seenBatchIds.where((entry) => entry == 'batch_001'),
          hasLength(1),
        );
        expect(result.deliveryDecision.requiresStagingOnly, isTrue);
        expect(result.finalizedSnapshot, isNull);
        expect(substrate.savedSnapshots, isEmpty);
      },
    );

    test(
      'marks compressed single-summary output as incomplete instead of completed',
      () async {
        final substrate = _MemoryReferenceEvidenceSubstrate();
        final stagingWorkspace = _MemoryReferenceExtractionStagingWorkspace();
        final proposalGenerator = _CompressedOutputProposalGenerator();
        final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
          substrate: substrate,
          stagingWorkspace: stagingWorkspace,
          proposalGenerator: proposalGenerator,
        );

        final result = await useCase.execute(
          ReferenceExtractionRunRequest(
            runId: 'run-compressed',
            finalizedAt: '2026-06-08T12:00:00Z',
            finalizedBy: 'tester',
            finalizedPackageVersionId: 'v.compressed',
            finalizedVersionLabel: 'compressed-final',
            sourceDocumentRequest: const ReferenceSourceDocumentIngestionRequest(
              sourceText:
                  'Chapter One\nHarry at Privet Drive.\n\nChapter Two\nLetters arrive.\n\nChapter Three\nHagrid enters.',
              sourceTitle: 'Compressed Sample',
              packageId: 'pkg.compressed',
              packageKind: ReferencePackageKinds.referenceWorkPackage,
              displayName: '压缩输出测试包',
              packageVersionId: 'v.seed',
              versionLabel: 'seed',
              createdAt: '2026-06-08T11:00:00Z',
              sourceLanguage: 'en',
              targetLanguage: 'zh-CN',
            ),
            agentAssessments: const <AgentAvailabilityAssessment>[
              AgentAvailabilityAssessment(
                profile: AgentProfile(
                  id: 'compressed-agent',
                  name: 'Compressed Agent',
                  description: '用于压缩输出合同测试。',
                ),
                isSupported: true,
              ),
            ],
          ),
        );

        expect(
          result.reviewOutcome.outputCompletionStatus,
          OutputCompletionStatuses.coverageInsufficient,
        );
        expect(
          result.reviewOutcome.outputCompressionRisk.signalCodes,
          containsAll(<String>[
            OutputCompressionSignalCodes.belowMinOutputSlots,
            OutputCompressionSignalCodes.oversizedItemSummary,
            OutputCompressionSignalCodes.insufficientCoveredDimensions,
          ]),
        );
        expect(
          result.deliveryDecision.deliveryStatus,
          ReferenceExtractionDeliveryStatuses.stagingOnly,
        );
        expect(result.finalizedSnapshot, isNull);
        expect(substrate.savedSnapshots, isEmpty);
      },
    );

    test(
      're-enters semantic continuation with same runId instead of short-circuiting old incomplete result',
      () async {
        final substrate = _MemoryReferenceEvidenceSubstrate();
        final stagingWorkspace = _MemoryReferenceExtractionStagingWorkspace();
        final proposalGenerator = _SemanticContinuationProposalGenerator();
        final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
          substrate: substrate,
          stagingWorkspace: stagingWorkspace,
          proposalGenerator: proposalGenerator,
        );

        final request = ReferenceExtractionRunRequest(
          runId: 'semantic-continue-run',
          finalizedAt: '2026-06-08T13:00:00Z',
          finalizedBy: 'tester',
          finalizedPackageVersionId: 'v.semantic',
          finalizedVersionLabel: 'semantic-final',
          sourceDocumentRequest: const ReferenceSourceDocumentIngestionRequest(
            sourceText:
                'Chapter One\nHarry lives at Privet Drive.\n\nChapter Two\nLetters arrive.\n\nChapter Three\nHagrid explains the world.',
            sourceTitle: 'Semantic Continuation Sample',
            packageId: 'pkg.semantic',
            packageKind: ReferencePackageKinds.referenceWorkPackage,
            displayName: '语义续提测试包',
            packageVersionId: 'v.seed',
            versionLabel: 'seed',
            createdAt: '2026-06-08T12:30:00Z',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
          ),
          agentAssessments: const <AgentAvailabilityAssessment>[
            AgentAvailabilityAssessment(
              profile: AgentProfile(
                id: 'semantic-agent',
                name: 'Semantic Agent',
                description: '用于验证 semantic continuation reentry。',
              ),
              isSupported: true,
            ),
          ],
        );

        final firstResult = await useCase.execute(request);

        expect(
          firstResult.reviewOutcome.outputCompletionStatus,
          OutputCompletionStatuses.continuationRecommended,
        );
        expect(firstResult.deliveryDecision.requiresStagingOnly, isTrue);
        expect(firstResult.finalizedSnapshot, isNull);
        expect(proposalGenerator.callCount, 1);

        final secondResult = await useCase.execute(request);

        expect(proposalGenerator.callCount, 2);
        expect(secondResult.stagingRun.continuationContexts, hasLength(1));
        expect(
          secondResult.stagingRun.continuationContexts.single.roundIndex,
          1,
        );
        expect(
          secondResult.stagingRun.runStatus,
          ReferenceExtractionRunStatuses.completedPublishable,
        );
        expect(
          secondResult.reviewOutcome.outputCompletionStatus,
          OutputCompletionStatuses.completed,
        );
        expect(
          secondResult.deliveryDecision.deliveryStatus,
          ReferenceExtractionDeliveryStatuses.publishable,
        );
        expect(secondResult.finalizedSnapshot, isNotNull);
        expect(substrate.savedSnapshots, hasLength(1));
        final batchState = await substrate.readBatchExecutionState(
          packageId: 'pkg.semantic',
          packageVersionId: 'v.seed',
        );
        expect(batchState, isNotNull);
        expect(batchState!.coverageState, isNotNull);
        expect(
          batchState.coverageState!.completedSegmentCount,
          batchState.coverageState!.totalSegmentCount,
        );
        expect(batchState.coverageLedger, isNotNull);
        expect(
          secondResult.stagingRun.proposals.map((item) => item.proposalId),
          containsAll(<String>[
            'proposal_semantic_initial',
            'proposal_semantic_continued',
          ]),
        );
      },
    );

    test(
      'treats explicit no-op omission and continuation placeholders as settled publishable output',
      () async {
        final substrate = _MemoryReferenceEvidenceSubstrate();
        final stagingWorkspace = _MemoryReferenceExtractionStagingWorkspace();
        final proposalGenerator = _NoOpContractProposalGenerator();
        final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
          substrate: substrate,
          stagingWorkspace: stagingWorkspace,
          proposalGenerator: proposalGenerator,
        );

        final result = await useCase.execute(
          ReferenceExtractionRunRequest(
            runId: 'noop-contract-run',
            finalizedAt: '2026-06-10T12:00:00Z',
            finalizedBy: 'tester',
            finalizedPackageVersionId: 'v.noop',
            finalizedVersionLabel: 'noop-final',
            sourceDocumentRequest: const ReferenceSourceDocumentIngestionRequest(
              sourceText:
                  'Chapter One\nHarry reaches Hogwarts.\n\nChapter Two\nHagrid explains key wizarding rules.',
              sourceTitle: 'No-op Contract Sample',
              packageId: 'pkg.noop',
              packageKind: ReferencePackageKinds.referenceWorkPackage,
              displayName: '占位合同信号测试包',
              packageVersionId: 'v.seed',
              versionLabel: 'seed',
              createdAt: '2026-06-10T11:30:00Z',
              sourceLanguage: 'en',
              targetLanguage: 'zh-CN',
            ),
            agentAssessments: const <AgentAvailabilityAssessment>[
              AgentAvailabilityAssessment(
                profile: AgentProfile(
                  id: 'noop-agent',
                  name: 'No-op Agent',
                  description: '用于验证 no-op contract signal 不会误判失败。',
                ),
                isSupported: true,
              ),
            ],
          ),
        );

        expect(proposalGenerator.callCount, 1);
        expect(
          result.reviewOutcome.outputCompletionStatus,
          OutputCompletionStatuses.completed,
        );
        expect(
          result.deliveryDecision.deliveryStatus,
          ReferenceExtractionDeliveryStatuses.publishable,
        );
        expect(result.stagingRun.runStatus, ReferenceExtractionRunStatuses.completedPublishable);
        expect(result.stagingRun.omissionReports, isEmpty);
        expect(result.stagingRun.continuationRequests, isEmpty);
        expect(result.finalizedSnapshot, isNotNull);
        expect(substrate.savedSnapshots, hasLength(1));
      },
    );

    test(
      'short-circuits safely for completed publishable run with same runId',
      () async {
        final substrate = _MemoryReferenceEvidenceSubstrate();
        final stagingWorkspace = _MemoryReferenceExtractionStagingWorkspace();
        final proposalGenerator = _CompletedPublishableProposalGenerator();
        final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
          substrate: substrate,
          stagingWorkspace: stagingWorkspace,
          proposalGenerator: proposalGenerator,
        );

        final request = ReferenceExtractionRunRequest(
          runId: 'publishable-run',
          finalizedAt: '2026-06-08T14:00:00Z',
          finalizedBy: 'tester',
          finalizedPackageVersionId: 'v.publishable',
          finalizedVersionLabel: 'publishable-final',
          sourceDocumentRequest: const ReferenceSourceDocumentIngestionRequest(
            sourceText:
                'Chapter One\nHarry lives at Privet Drive.\n\nChapter Two\nLetters arrive.\n\nChapter Three\nHagrid explains the world.',
            sourceTitle: 'Publishable Short Circuit Sample',
            packageId: 'pkg.publishable',
            packageKind: ReferencePackageKinds.referenceWorkPackage,
            displayName: '已完成短路测试包',
            packageVersionId: 'v.seed',
            versionLabel: 'seed',
            createdAt: '2026-06-08T13:30:00Z',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
          ),
          agentAssessments: const <AgentAvailabilityAssessment>[
            AgentAvailabilityAssessment(
              profile: AgentProfile(
                id: 'publishable-agent',
                name: 'Publishable Agent',
                description: '用于验证 completed 短路。',
              ),
              isSupported: true,
            ),
          ],
        );

        final firstResult = await useCase.execute(request);
        final secondResult = await useCase.execute(request);

        expect(proposalGenerator.callCount, 1);
        expect(firstResult.finalizedSnapshot, isNotNull);
        expect(secondResult.finalizedSnapshot, isNotNull);
        expect(
          secondResult.deliveryDecision.deliveryStatus,
          ReferenceExtractionDeliveryStatuses.publishable,
        );
        expect(
          secondResult.stagingRun.runStatus,
          ReferenceExtractionRunStatuses.completedPublishable,
        );
        expect(substrate.savedSnapshots, hasLength(1));
        final batchState = await substrate.readBatchExecutionState(
          packageId: 'pkg.publishable',
          packageVersionId: 'v.seed',
        );
        expect(batchState, isNotNull);
        expect(batchState!.coverageState, isNotNull);
        expect(
          batchState.coverageState!.completedSegmentCount,
          batchState.coverageState!.totalSegmentCount,
        );
      },
    );
  });
}

class _FakeProposalGenerator implements ReferenceExtractionProposalGenerator {
  int callCount = 0;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    callCount += 1;
    final sourceRef = request.seedSnapshot.entries.first.sourceRefs.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal-fact',
          entryId: 'fact_hogwarts',
          entryNamespace: 'world_facts',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '霍格沃茨作为核心奇幻空间',
          summary: '文本把霍格沃茨呈现为主角进入魔法世界后的核心场域。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: const <String>['hogwarts', 'world'],
          coverageDimensionIds: const <String>[
            'setting_or_object',
            'plot_or_mechanism',
          ],
          confidence: 0.92,
        ),
        ReferenceExtractionProposal(
          proposalId: 'proposal-style',
          entryId: 'style_whimsy',
          entryNamespace: 'style_profile',
          entryKind: ReferenceEntryKinds.styleTechnique,
          title: '轻奇观风格递进',
          summary: '奇观以渐进揭示的方式带动儿童视角。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          tags: const <String>['style'],
          coverageDimensionIds: const <String>['style_or_technique'],
          confidence: 0.63,
        ),
        const ReferenceExtractionProposal(
          proposalId: 'proposal-speculative',
          entryId: 'speculative_motif',
          entryNamespace: 'motif',
          entryKind: ReferenceEntryKinds.designElement,
          title: '未经证据支撑的母题猜测',
          summary: '缺少证据的猜测应被挡在正式包外。',
          coverageDimensionIds: <String>['character_fact'],
          confidence: 0.88,
        ),
      ],
      omissionReport: const OmissionReport(
        reportId: 'omission_missing_mechanism',
        contractId: 'reference_extraction.standard',
        omittedDimensionIds: <String>['character_fact', 'timeline_or_boundary'],
        reasonCode: OmissionReasonCodes.outputBudgetExhausted,
        summary: '当前批次输出没有覆盖角色事实和边界维度。',
        recommendedNextFocus: '补提角色关系和边界提醒。',
      ),
      continuationRequest: const ContinuationRequest(
        requestId: 'continue_missing_character',
        contractId: 'reference_extraction.standard',
        continuationReason: '仍有关键维度缺口',
        missingDimensionIds: <String>['character_fact', 'timeline_or_boundary'],
        recommendedNextFocus: '优先补提角色事实与引用边界。',
        suggestedSlotCount: 2,
      ),
    );
  }
}

class _ResumeAwareProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  final List<String> seenBatchIds = <String>[];
  bool _thrown = false;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    seenBatchIds.add(request.batch.batchId);
    if (!_thrown && request.batch.batchId == 'batch_002') {
      _thrown = true;
      throw StateError('simulated batch failure');
    }
    final sourceRef = request.seedSnapshot.entries.first.sourceRefs.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_${request.batch.batchId}',
          entryId: 'fact_${request.batch.batchId}',
          entryNamespace: 'resume',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '批次 ${request.batch.batchId}',
          summary: '用于验证断点续跑时不重复执行已完成批次。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['character_fact'],
          confidence: 0.9,
        ),
      ],
    );
  }
}

class _CompressedOutputProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    final sourceRef = request.seedSnapshot.entries.first.sourceRefs.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_compressed',
          entryId: 'compressed_entry',
          entryNamespace: 'compressed',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '大而泛的概括条目',
          summary: List<String>.filled(220, '这一条把多个地点、人物和机制都压进同一段概括里。').join(),
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['character_fact'],
          confidence: 0.91,
        ),
      ],
    );
  }
}

class _SemanticContinuationProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  int callCount = 0;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    callCount += 1;
    final sourceRef = request.seedSnapshot.entries.first.sourceRefs.first;
    if (request.continuationContext == null) {
      return ReferenceExtractionProposalGenerationResult(
        proposals: <ReferenceExtractionProposal>[
          ReferenceExtractionProposal(
            proposalId: 'proposal_semantic_initial',
            entryId: 'entry_semantic_initial',
            entryNamespace: 'semantic',
            entryKind: ReferenceEntryKinds.knowledgeFact,
            title: '起始角色事实',
            summary: '先覆盖角色事实，留出后续机制与地点维度。',
            sourceRefs: <InformationSourceRef>[sourceRef],
            coverageDimensionIds: const <String>['character_fact'],
            confidence: 0.91,
          ),
        ],
        omissionReport: const OmissionReport(
          reportId: 'semantic_omission_1',
          contractId: 'reference_extraction.standard',
          omittedDimensionIds: <String>[
            'setting_or_object',
            'plot_or_mechanism',
          ],
          reasonCode: OmissionReasonCodes.outputBudgetExhausted,
          summary: '首轮只覆盖了角色事实。',
          recommendedNextFocus: '补提地点与世界机制。',
          metadata: <String, Object?>{'batch_id': 'batch_001'},
        ),
        continuationRequest: const ContinuationRequest(
          requestId: 'semantic_continue_1',
          contractId: 'reference_extraction.standard',
          continuationReason: '仍缺地点与机制维度',
          missingDimensionIds: <String>[
            'setting_or_object',
            'plot_or_mechanism',
          ],
          recommendedNextFocus: '优先补提地点与世界机制。',
          suggestedSlotCount: 2,
          metadata: <String, Object?>{'batch_id': 'batch_001'},
        ),
      );
    }
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_semantic_continued',
          entryId: 'entry_semantic_continued',
          entryNamespace: 'semantic',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '续提补齐地点与机制',
          summary: '第二轮根据 continuation focus 补齐地点与世界机制。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>[
            'setting_or_object',
            'plot_or_mechanism',
          ],
          confidence: 0.93,
        ),
      ],
    );
  }
}

class _CompletedPublishableProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  int callCount = 0;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    callCount += 1;
    final sourceRef = request.seedSnapshot.entries.first.sourceRefs.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_publishable_character',
          entryId: 'entry_publishable_character',
          entryNamespace: 'publishable',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '角色事实',
          summary: '覆盖角色事实。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['character_fact'],
          confidence: 0.9,
        ),
        ReferenceExtractionProposal(
          proposalId: 'proposal_publishable_setting',
          entryId: 'entry_publishable_setting',
          entryNamespace: 'publishable',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '地点事实',
          summary: '覆盖地点维度。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['setting_or_object'],
          confidence: 0.9,
        ),
        ReferenceExtractionProposal(
          proposalId: 'proposal_publishable_plot',
          entryId: 'entry_publishable_plot',
          entryNamespace: 'publishable',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '机制事实',
          summary: '覆盖剧情机关与世界机制。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['plot_or_mechanism'],
          confidence: 0.9,
        ),
      ],
    );
  }
}

class _NoOpContractProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  int callCount = 0;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    callCount += 1;
    final sourceRef = request.seedSnapshot.entries.first.sourceRefs.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_noop_character',
          entryId: 'entry_noop_character',
          entryNamespace: 'noop',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '角色事实',
          summary: '覆盖角色事实维度。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['character_fact'],
          confidence: 0.9,
        ),
        ReferenceExtractionProposal(
          proposalId: 'proposal_noop_setting',
          entryId: 'entry_noop_setting',
          entryNamespace: 'noop',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '地点物件事实',
          summary: '覆盖地点与关键物件维度。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['setting_or_object'],
          confidence: 0.9,
        ),
        ReferenceExtractionProposal(
          proposalId: 'proposal_noop_plot',
          entryId: 'entry_noop_plot',
          entryNamespace: 'noop',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '机制事实',
          summary: '覆盖剧情机制维度。',
          sourceRefs: <InformationSourceRef>[sourceRef],
          coverageDimensionIds: const <String>['plot_or_mechanism'],
          confidence: 0.9,
        ),
      ],
      omissionReport: const OmissionReport(
        reportId: 'omit_none',
        contractId: 'reference_extraction.standard',
        omittedDimensionIds: <String>[],
        reasonCode: OmissionReasonCodes.noOmission,
        summary: '本轮没有新的遗漏。',
      ),
      continuationRequest: const ContinuationRequest(
        requestId: 'continue_none',
        contractId: 'reference_extraction.standard',
        continuationReason: ContinuationReasonCodes.noContinuation,
        missingDimensionIds: <String>[],
        suggestedSlotCount: 0,
      ),
    );
  }
}

class _MemoryReferenceExtractionStagingWorkspace
    implements ReferenceExtractionStagingWorkspace {
  final Map<String, ReferenceExtractionStagingRun> _runs =
      <String, ReferenceExtractionStagingRun>{};

  @override
  Future<ReferenceExtractionStagingRun?> readRun(String runId) async {
    return _runs[runId];
  }

  @override
  Future<void> upsertRun(ReferenceExtractionStagingRun run) async {
    _runs[run.runId] = run;
  }
}

class _MemoryReferenceEvidenceSubstrate implements ReferenceEvidenceSubstrate {
  final List<ReferencePackageSnapshot> savedSnapshots =
      <ReferencePackageSnapshot>[];
  final Map<String, ReferenceEvidenceBatchExecutionState> batchStates =
      <String, ReferenceEvidenceBatchExecutionState>{};
  final Map<String, ReferenceEvidenceContinuityLedger> continuityLedgers =
      <String, ReferenceEvidenceContinuityLedger>{};

  @override
  Future<List<ReferenceEntryRecord>> listEntries({
    String? packageId,
    String? packageVersionId,
    String? entryKind,
  }) async {
    return const <ReferenceEntryRecord>[];
  }

  @override
  Future<List<ReferencePackageRecord>> listPackages({
    String? packageKind,
  }) async {
    return const <ReferencePackageRecord>[];
  }

  @override
  Future<List<ReferenceSourceAssetLinkRecord>> listSourceAssetLinks({
    String? packageId,
    String? packageVersionId,
    String? entryId,
    String? sourceAssetId,
  }) async {
    return const <ReferenceSourceAssetLinkRecord>[];
  }

  @override
  Future<ReferenceQueryResult> queryEntries(ReferenceQuery query) async {
    return const ReferenceQueryResult(
      entries: <ReferenceEntryRecord>[],
      totalCount: 0,
    );
  }

  @override
  Future<ReferencePackageRecord?> readPackage(String packageId) async {
    return null;
  }

  @override
  Future<ReferencePackageSnapshot?> readPackageSnapshot({
    required String packageId,
    required String packageVersionId,
  }) async {
    return null;
  }

  @override
  Future<ReferenceEvidenceBatchExecutionState?> readBatchExecutionState({
    required String packageId,
    required String packageVersionId,
  }) async {
    return batchStates['$packageId::$packageVersionId'];
  }

  @override
  Future<ReferenceEvidenceContinuityLedger?> readContinuityLedger({
    required String packageId,
    required String packageVersionId,
  }) async {
    return continuityLedgers['$packageId::$packageVersionId'];
  }

  @override
  Future<void> upsertBatchExecutionState(
    ReferenceEvidenceBatchExecutionState state,
  ) async {
    batchStates['${state.packageId}::${state.packageVersionId}'] = state;
  }

  @override
  Future<void> upsertContinuityLedger(
    ReferenceEvidenceContinuityLedger ledger,
  ) async {
    continuityLedgers['${ledger.packageId}::${ledger.packageVersionId}'] =
        ledger;
  }

  @override
  Future<void> upsertPackageSnapshot(ReferencePackageSnapshot snapshot) async {
    savedSnapshots.add(snapshot);
  }
}
