import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionCoverageMergeService', () {
    const service = ReferenceExtractionCoverageMergeService();

    test('merges split-batch progress into pending segment coverage state', () {
      const plan = ReferenceSourceBatchPlan(
        planId: 'plan_split',
        structureMode: ReferenceSourceDocumentStructureKinds.explicitChapter,
        totalSourceChars: 2400,
        totalSectionCount: 1,
        budgetResolution: ReferenceIngestionBudgetResolution(
          availableContextChars: 12000,
          targetSourceChars: 800,
          minSourceChars: 500,
          maxSourceChars: 900,
          minSectionsPerBatch: 1,
          maxSectionsPerBatch: 1,
          instructionReserveChars: 1200,
          carryForwardReserveChars: 500,
          responseReserveChars: 900,
          safetyReserveChars: 300,
        ),
        planningMode: ReferenceSourceBatchPlanningModes.chapterFirst,
        oversizeSplitApplied: true,
        batches: <ReferenceSourceBatch>[
          ReferenceSourceBatch(
            batchId: 'batch_001',
            batchIndex: 1,
            structureMode:
                ReferenceSourceDocumentStructureKinds.explicitChapter,
            splitMode: ReferenceSourceBatchSplitModes.oversizedSectionSplit,
            sourceText: 'chunk a',
            sectionIds: <String>['section_001_chunk_1'],
            sectionIndexes: <int>[1],
            syntheticSplit: true,
            parentSectionIds: <String>['section_001'],
          ),
          ReferenceSourceBatch(
            batchId: 'batch_002',
            batchIndex: 2,
            structureMode:
                ReferenceSourceDocumentStructureKinds.explicitChapter,
            splitMode: ReferenceSourceBatchSplitModes.oversizedSectionSplit,
            sourceText: 'chunk b',
            sectionIds: <String>['section_001_chunk_2'],
            sectionIndexes: <int>[1],
            syntheticSplit: true,
            parentSectionIds: <String>['section_001'],
          ),
        ],
      );
      const progress = ReferenceSourceBatchProgress(
        planId: 'plan_split',
        totalBatches: 2,
        totalSourceChars: 14,
        items: <ReferenceSourceBatchProgressItem>[
          ReferenceSourceBatchProgressItem(
            batchId: 'batch_001',
            status: ReferenceSourceBatchStatuses.completed,
            sectionIds: <String>['section_001_chunk_1'],
            charCount: 7,
          ),
          ReferenceSourceBatchProgressItem(
            batchId: 'batch_002',
            status: ReferenceSourceBatchStatuses.pending,
            sectionIds: <String>['section_001_chunk_2'],
            charCount: 7,
          ),
        ],
      );

      final state = service.merge(batchPlan: plan, batchProgress: progress);

      expect(state.validateBasics(), isEmpty);
      expect(state.totalSegmentCount, 1);
      expect(state.completedSegmentCount, 0);
      expect(state.pendingSegmentCount, 1);
      expect(state.requiresFollowupSegmentIds, <String>['section_001']);
      expect(state.consolidationReady, isFalse);
    });

    test(
      'condenses covered ranges and followup dimensions into stable state',
      () {
        const plan = ReferenceSourceBatchPlan(
          planId: 'plan_coverage',
          structureMode: ReferenceSourceDocumentStructureKinds.explicitChapter,
          totalSourceChars: 3600,
          totalSectionCount: 3,
          budgetResolution: ReferenceIngestionBudgetResolution(
            availableContextChars: 16000,
            targetSourceChars: 1400,
            minSourceChars: 600,
            maxSourceChars: 1600,
            minSectionsPerBatch: 1,
            maxSectionsPerBatch: 2,
            instructionReserveChars: 1800,
            carryForwardReserveChars: 800,
            responseReserveChars: 1600,
            safetyReserveChars: 500,
          ),
          batches: <ReferenceSourceBatch>[
            ReferenceSourceBatch(
              batchId: 'batch_001',
              batchIndex: 1,
              structureMode:
                  ReferenceSourceDocumentStructureKinds.explicitChapter,
              splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
              sourceText: 'chapter one',
              sectionIds: <String>['section_001'],
              sectionIndexes: <int>[1],
            ),
            ReferenceSourceBatch(
              batchId: 'batch_002',
              batchIndex: 2,
              structureMode:
                  ReferenceSourceDocumentStructureKinds.explicitChapter,
              splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
              sourceText: 'chapter two',
              sectionIds: <String>['section_002'],
              sectionIndexes: <int>[2],
            ),
            ReferenceSourceBatch(
              batchId: 'batch_003',
              batchIndex: 3,
              structureMode:
                  ReferenceSourceDocumentStructureKinds.explicitChapter,
              splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
              sourceText: 'chapter three',
              sectionIds: <String>['section_003'],
              sectionIndexes: <int>[3],
            ),
          ],
        );
        const progress = ReferenceSourceBatchProgress(
          planId: 'plan_coverage',
          totalBatches: 3,
          totalSourceChars: 34,
          items: <ReferenceSourceBatchProgressItem>[
            ReferenceSourceBatchProgressItem(
              batchId: 'batch_001',
              status: ReferenceSourceBatchStatuses.completed,
              sectionIds: <String>['section_001'],
              charCount: 11,
            ),
            ReferenceSourceBatchProgressItem(
              batchId: 'batch_002',
              status: ReferenceSourceBatchStatuses.completed,
              sectionIds: <String>['section_002'],
              charCount: 11,
            ),
            ReferenceSourceBatchProgressItem(
              batchId: 'batch_003',
              status: ReferenceSourceBatchStatuses.failed,
              sectionIds: <String>['section_003'],
              charCount: 12,
              failureReason: 'provider_failed',
            ),
          ],
        );
        final state = service.merge(
          batchPlan: plan,
          batchProgress: progress,
          proposals: const <ReferenceExtractionProposal>[
            ReferenceExtractionProposal(
              proposalId: 'proposal_001',
              entryId: 'entry_001',
              entryNamespace: 'facts',
              entryKind: ReferenceEntryKinds.knowledgeFact,
              title: '角色事实',
              summary: 'summary',
              coverageDimensionIds: <String>['character_fact'],
            ),
            ReferenceExtractionProposal(
              proposalId: 'proposal_002',
              entryId: 'entry_002',
              entryNamespace: 'setting',
              entryKind: ReferenceEntryKinds.knowledgeFact,
              title: '地点事实',
              summary: 'summary',
              coverageDimensionIds: <String>['setting_or_object'],
            ),
          ],
          coverageLedger: const OutputCoverageLedger(
            contractId: 'reference_extraction.standard',
            completionStatus: OutputCompletionStatuses.coverageInsufficient,
            dimensions: <OutputCoverageLedgerDimension>[
              OutputCoverageLedgerDimension(
                dimensionId: 'character_fact',
                label: '角色事实',
                required: true,
                minItemCount: 1,
                generatedSlotCount: 1,
                acceptedSlotCount: 1,
                omissionCount: 0,
                status: OutputCoverageStatuses.covered,
              ),
              OutputCoverageLedgerDimension(
                dimensionId: 'plot_or_mechanism',
                label: '剧情机关',
                required: true,
                minItemCount: 1,
                generatedSlotCount: 0,
                acceptedSlotCount: 0,
                omissionCount: 1,
                status: OutputCoverageStatuses.uncovered,
              ),
            ],
          ),
          omissionReports: const <OmissionReport>[
            OmissionReport(
              reportId: 'omit_001',
              omittedDimensionIds: <String>['timeline_or_boundary'],
            ),
          ],
        );

        expect(state.validateBasics(), isEmpty);
        expect(state.completedSegmentCount, 2);
        expect(state.failedSegmentCount, 1);
        expect(state.pendingSegmentCount, 0);
        expect(state.coveredSectionRanges, hasLength(1));
        expect(state.coveredSectionRanges.first.startSectionIndex, 1);
        expect(state.coveredSectionRanges.first.endSectionIndex, 2);
        expect(state.coveredDimensionIds, contains('character_fact'));
        expect(state.uncoveredDimensionIds, contains('plot_or_mechanism'));
        expect(state.uncoveredDimensionIds, contains('timeline_or_boundary'));
        expect(state.requiresFollowupSegmentIds, contains('section_003'));
        expect(state.consolidationReady, isFalse);
      },
    );
  });
}
