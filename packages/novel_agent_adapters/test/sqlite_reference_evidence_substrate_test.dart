import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteReferenceEvidenceSubstrate', () {
    late Directory tempDirectory;
    late Directory substrateDirectory;
    late SqliteReferenceEvidenceSubstrate substrate;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'sqlite_reference_evidence_substrate_test_',
      );
      substrateDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}substrate',
      )..createSync(recursive: true);
      substrate = SqliteReferenceEvidenceSubstrate(
        substrateRootPath: substrateDirectory.path,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'persists source asset identities from snapshot without leaking absolute paths into local hint path',
      () async {
        final extraction = const ReferenceSourceDocumentExtractionService().extract(
          const ReferenceSourceDocumentIngestionRequest(
            sourceText:
                'Chapter One\nHarry met Hagrid.\n\nChapter Two\nHagrid explained the wizard world.',
            sourceTitle: 'Harry Potter Raw',
            sourceRef: 'C:\\imports\\Harry Potter - Volume 1 Raw.txt',
            packageId: 'pkg.hp.identity',
            packageKind: ReferencePackageKinds.referenceWorkPackage,
            displayName: '哈利波特来源身份测试包',
            packageNamespace: 'hp.identity',
            packageVersionId: 'v1',
            versionLabel: '1.0',
            createdAt: '2026-06-08T10:00:00Z',
            sourceLanguage: 'en',
            targetLanguage: 'zh-CN',
          ),
        );
        await substrate.upsertPackageSnapshot(extraction.snapshot);

        final reopened = SqliteReferenceEvidenceSubstrate(
          substrateRootPath: substrateDirectory.path,
        );
        final links = await reopened.listSourceAssetLinks(
          packageId: 'pkg.hp.identity',
          packageVersionId: 'v1',
        );

        expect(links, isNotEmpty);
        final firstLink = links.first;
        expect(firstLink.sourceAsset.sourceAssetId, isNotEmpty);
        expect(
          firstLink.sourceAsset.localHintPath,
          'Harry Potter - Volume 1 Raw.txt',
        );
        expect(firstLink.sourceAsset.localHintPath.contains(':\\'), isFalse);
        expect(
          firstLink.sourceAsset.resolverUri,
          'workspace-file://Harry%20Potter%20-%20Volume%201%20Raw.txt',
        );
        expect(firstLink.sourceAsset.metadata['debug_local_absolute_path'], isNull);
      },
    );

    test(
      'round-trips batch execution state and semantic coverage ledger',
      () async {
        await substrate.upsertPackageSnapshot(_referenceSnapshot());
        final batchPlan = ReferenceSourceBatchPlan(
          planId: 'plan-hp-1',
          structureMode: 'chapter_headings',
          totalSourceChars: 1200,
          totalSectionCount: 3,
          budgetResolution: const ReferenceIngestionBudgetResolution(
            availableContextChars: 8000,
            targetSourceChars: 1200,
            minSourceChars: 500,
            maxSourceChars: 1400,
            minSectionsPerBatch: 1,
            maxSectionsPerBatch: 2,
            instructionReserveChars: 800,
            carryForwardReserveChars: 300,
            responseReserveChars: 600,
            safetyReserveChars: 200,
            planningMode: ReferenceSourceBatchPlanningModes.structureFirst,
            batchGoalKind: ReferenceBatchGoalKinds.semanticExtraction,
          ),
          batches: const <ReferenceSourceBatch>[
            ReferenceSourceBatch(
              batchId: 'batch-1',
              batchIndex: 0,
              structureMode: 'chapter_headings',
              splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
              sourceText: 'Chapter one',
              sectionIds: <String>['section-1'],
              sectionIndexes: <int>[1],
              headings: <String>['Chapter One'],
            ),
            ReferenceSourceBatch(
              batchId: 'batch-2',
              batchIndex: 1,
              structureMode: 'chapter_headings',
              splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
              sourceText: 'Chapter two',
              sectionIds: <String>['section-2'],
              sectionIndexes: <int>[2],
              headings: <String>['Chapter Two'],
            ),
          ],
        );
        final batchProgress = ReferenceSourceBatchProgress(
          planId: 'plan-hp-1',
          totalBatches: 2,
          totalSourceChars: 1200,
          items: const <ReferenceSourceBatchProgressItem>[
            ReferenceSourceBatchProgressItem(
              batchId: 'batch-1',
              status: ReferenceSourceBatchStatuses.completed,
              sectionIds: <String>['section-1'],
              charCount: 600,
              proposalCount: 3,
              completedAt: '2026-06-08T10:10:00Z',
            ),
            ReferenceSourceBatchProgressItem(
              batchId: 'batch-2',
              status: ReferenceSourceBatchStatuses.pending,
              sectionIds: <String>['section-2'],
              charCount: 600,
            ),
          ],
        );
        final coverageState = const ReferenceExtractionCoverageState(
          planId: 'plan-hp-1',
          totalSegmentCount: 2,
          completedSegmentCount: 1,
          failedSegmentCount: 0,
          pendingSegmentCount: 1,
          coveredSectionRanges: <ReferenceExtractionCoveredRange>[
            ReferenceExtractionCoveredRange(
              startSectionIndex: 1,
              endSectionIndex: 1,
              sectionIds: <String>['section-1'],
            ),
          ],
          requiresFollowupSegmentIds: <String>['section-2'],
          coveredDimensionIds: <String>['character_cards'],
          uncoveredDimensionIds: <String>['world_rules'],
          consolidationReady: false,
        );
        final coverageLedger = const OutputCoverageLedger(
          contractId: 'reference_extraction.standard',
          totalGeneratedSlots: 3,
          totalAcceptedSlots: 2,
          coveredDimensionCount: 1,
          acceptedCoveredDimensionCount: 1,
          completionStatus: OutputCompletionStatuses.continuationRecommended,
          dimensions: <OutputCoverageLedgerDimension>[
            OutputCoverageLedgerDimension(
              dimensionId: 'character_cards',
              label: '角色卡',
              required: true,
              minItemCount: 1,
              generatedSlotCount: 2,
              acceptedSlotCount: 2,
              omissionCount: 0,
              status: OutputCoverageStatuses.covered,
            ),
            OutputCoverageLedgerDimension(
              dimensionId: 'world_rules',
              label: '世界规则',
              required: true,
              minItemCount: 1,
              generatedSlotCount: 1,
              acceptedSlotCount: 0,
              omissionCount: 1,
              status: OutputCoverageStatuses.uncovered,
            ),
          ],
        );

        await substrate.upsertBatchExecutionState(
          ReferenceEvidenceBatchExecutionState(
            packageId: 'pkg_reference',
            packageVersionId: 'v1',
            batchPlan: batchPlan,
            batchProgress: batchProgress,
            coverageState: coverageState,
            coverageLedger: coverageLedger,
            updatedAt: '2026-06-08T10:20:00Z',
            metadata: const <String, Object?>{'run_id': 'run-1'},
          ),
        );

        final reopened = SqliteReferenceEvidenceSubstrate(
          substrateRootPath: substrateDirectory.path,
        );
        final restored = await reopened.readBatchExecutionState(
          packageId: 'pkg_reference',
          packageVersionId: 'v1',
        );

        expect(restored, isNotNull);
        expect(restored!.validateBasics(), isEmpty);
        expect(restored.batchPlan.planId, 'plan-hp-1');
        expect(restored.batchProgress.pendingBatchCount, 1);
        expect(restored.coverageState, isNotNull);
        expect(restored.coverageState!.requiresFollowupSegmentIds, <String>[
          'section-2',
        ]);
        expect(restored.coverageLedger, isNotNull);
        expect(restored.coverageLedger!.uncoveredDimensionIds, <String>[
          'world_rules',
        ]);
        expect(restored.metadata['run_id'], 'run-1');
      },
    );

    test(
      'round-trips continuity conflict, canon decision, and review alert ledgers',
      () async {
        await substrate.upsertPackageSnapshot(_referenceSnapshot());
        final cluster = NarrativeConflictCluster.fromJson(<String, Object?>{
          'cluster_id': 'cluster-1',
          'subject_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.asset,
            'ref_id': 'harry',
          },
          'attribute_key': 'wand_owner',
          'classification':
              NarrativeConflictClassifications.unexplainedConflict,
          'cluster_status': NarrativeConflictClusterStatuses.needsDecision,
          'fact_evidences': <Object?>[
            <String, Object?>{
              'fact_evidence_id': 'fact-1',
              'subject_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.asset,
                'ref_id': 'harry',
              },
              'attribute_key': 'wand_owner',
              'value_payload': <String, Object?>{'owner': 'harry'},
              'claim_snapshot': <String, Object?>{
                'claim_id': 'claim-1',
                'claim_namespace': 'continuity.character',
                'claim_payload': <String, Object?>{'owner': 'harry'},
                'source': <String, Object?>{
                  'source_type': 'reference_package',
                  'source_id': 'pkg_reference',
                },
              },
              'source': <String, Object?>{
                'source_type': 'reference_package',
                'source_id': 'pkg_reference',
              },
              'confidence': 0.9,
            },
          ],
        });
        final decision = ProjectCanonDecision.fromJson(<String, Object?>{
          'decision_id': 'decision-1',
          'cluster_id': 'cluster-1',
          'decision_kind': ProjectCanonDecisionKinds.adoptPrimaryFact,
          'selected_fact_evidence_ids': <Object?>['fact-1'],
          'decided_at': '2026-06-08T11:00:00Z',
        });
        final alert = ContinuityReviewAlert.fromJson(<String, Object?>{
          'alert_id': 'alert-1',
          'cluster_id': 'cluster-1',
          'alert_kind': ContinuityReviewAlertKinds.unresolvedConflict,
          'severity': ContinuityReviewAlertSeverities.high,
          'summary': '需要确认魔杖归属。',
          'requires_manual_review': true,
          'source': <String, Object?>{
            'source_type': 'reference_package',
            'source_id': 'pkg_reference',
          },
        });

        await substrate.upsertContinuityLedger(
          ReferenceEvidenceContinuityLedger(
            packageId: 'pkg_reference',
            packageVersionId: 'v1',
            conflictClusters: <NarrativeConflictCluster>[cluster],
            canonDecisions: <ProjectCanonDecision>[decision],
            reviewAlerts: <ContinuityReviewAlert>[alert],
            updatedAt: '2026-06-08T11:10:00Z',
          ),
        );

        final reopened = SqliteReferenceEvidenceSubstrate(
          substrateRootPath: substrateDirectory.path,
        );
        final restored = await reopened.readContinuityLedger(
          packageId: 'pkg_reference',
          packageVersionId: 'v1',
        );

        expect(restored, isNotNull);
        expect(restored!.validateBasics(), isEmpty);
        expect(restored.conflictClusters, hasLength(1));
        expect(restored.canonDecisions, hasLength(1));
        expect(restored.reviewAlerts, hasLength(1));
        expect(
          restored.conflictClusters.single.clusterStatus,
          NarrativeConflictClusterStatuses.needsDecision,
        );
        expect(restored.canonDecisions.single.selectedFactEvidenceIds, <String>[
          'fact-1',
        ]);
        expect(
          restored.reviewAlerts.single.severity,
          ContinuityReviewAlertSeverities.high,
        );
      },
    );

    test(
      'persists empty continuity ledger header so initialized packages keep review state contracts',
      () async {
        await substrate.upsertPackageSnapshot(_referenceSnapshot());
        await substrate.upsertContinuityLedger(
          const ReferenceEvidenceContinuityLedger(
            packageId: 'pkg_reference',
            packageVersionId: 'v1',
            updatedAt: '2026-06-08T11:30:00Z',
            metadata: <String, Object?>{
              'source': 'project_reference_extraction_runtime',
              'run_id': 'run-empty-ledger',
            },
          ),
        );

        final reopened = SqliteReferenceEvidenceSubstrate(
          substrateRootPath: substrateDirectory.path,
        );
        final restored = await reopened.readContinuityLedger(
          packageId: 'pkg_reference',
          packageVersionId: 'v1',
        );

        expect(restored, isNotNull);
        expect(restored!.validateBasics(), isEmpty);
        expect(restored.conflictClusters, isEmpty);
        expect(restored.canonDecisions, isEmpty);
        expect(restored.reviewAlerts, isEmpty);
        expect(restored.updatedAt, '2026-06-08T11:30:00Z');
        expect(
          ValueReaders.stringValue(restored.metadata['source']),
          'project_reference_extraction_runtime',
        );
        expect(
          ValueReaders.stringValue(restored.metadata['run_id']),
          'run-empty-ledger',
        );
      },
    );
  });
}

ReferencePackageSnapshot _referenceSnapshot() {
  final sourceRef = InformationSourceRef(
    sourceRef: const NarrativeSourceRef(
      sourceType: 'reference_package',
      sourceId: 'pkg_reference_asset',
      sourceAssetId: 'asset:pkg_reference_asset',
      label: '参考包来源',
      displayName: '参考包来源',
      sourceKind: 'reference_package',
      resolverUri: 'reference-package://pkg_reference_asset',
      localHintPath: 'references/pkg_reference_asset.json',
    ),
    sourceAuthority: InformationSourceAuthorities.sourceDocument,
    roleAuthority: InformationRoleAuthorities.deconstructor,
    researchDepth: InformationResearchDepths.deep,
  );
  return ReferencePackageSnapshot(
    packageRecord: const ReferencePackageRecord(
      packageId: 'pkg_reference',
      packageKind: ReferencePackageKinds.referenceWorkPackage,
      displayName: '参考包',
      packageNamespace: 'reference',
      description: '持久化测试参考包',
      latestVersionId: 'v1',
      lifecycleStatus: 'active',
      createdAt: '2026-06-08T09:00:00Z',
      updatedAt: '2026-06-08T09:00:00Z',
    ),
    packageVersionRecord: const ReferencePackageVersionRecord(
      packageVersionId: 'v1',
      packageId: 'pkg_reference',
      versionLabel: '1.0',
      createdAt: '2026-06-08T09:00:00Z',
      createdBy: 'tester',
    ),
    entries: <ReferenceEntryRecord>[
      ReferenceEntryRecord(
        entryId: 'entry_fact',
        packageId: 'pkg_reference',
        packageVersionId: 'v1',
        entryNamespace: 'wizarding_world',
        entryKind: ReferenceEntryKinds.knowledgeFact,
        title: '魔杖选择巫师',
        summary: '原作中明确由魔杖选择巫师。',
        payload: const <String, Object?>{'fact': 'wand chooses wizard'},
        sourceRefs: <InformationSourceRef>[sourceRef],
        evidenceRefs: <NarrativeEvidenceRef>[
          NarrativeEvidenceRef(
            evidenceType: 'reference_source_section',
            evidenceId: 'evidence-1',
            sourceRef: const NarrativeSourceRef(
              sourceType: 'reference_package',
              sourceId: 'pkg_reference_asset',
              sourceAssetId: 'asset:pkg_reference_asset',
              label: '参考包来源',
              displayName: '参考包来源',
              sourceKind: 'reference_package',
              resolverUri: 'reference-package://pkg_reference_asset',
              localHintPath: 'references/pkg_reference_asset.json',
            ),
            targetRef: const NarrativeRef(
              refType: NarrativeRefTypes.chapter,
              refId: 'chapter-1',
            ),
            summary: '章节证据',
          ),
        ],
        activationPolicy: const InformationActivationPolicy(
          activationPriority: InformationActivationPriorities.required,
        ),
        usagePolicy: const InformationUsagePolicy(
          usageMode: InformationUsageModes.referenceOnly,
          citationRiskLevel: InformationCitationRiskLevels.normal,
        ),
        confidence: 0.96,
        lifecycleStatus: 'active',
      ),
    ],
  );
}
