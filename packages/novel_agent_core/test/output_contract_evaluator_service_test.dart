import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OutputContractEvaluatorService', () {
    const service = OutputContractEvaluatorService();
    const coverageContract = OutputCoverageContract(
      contractId: 'reference_extraction.standard',
      dimensions: <OutputCoverageDimension>[
        ReferenceExtractionCoverageDimensions.characterFact,
        ReferenceExtractionCoverageDimensions.settingOrObject,
        ReferenceExtractionCoverageDimensions.plotOrMechanism,
      ],
      minCoveredDimensions: 2,
      allowContinuationWhenIncomplete: true,
    );

    test('marks explicit continuation as normal continuation status', () {
      final evaluation = service.evaluate(
        budgetPolicy: const OutputBudgetPolicy(minOutputSlots: 3),
        coverageContract: coverageContract,
        generatedSignals: const <OutputCoverageSignal>[
          OutputCoverageSignal(
            dimensionId: 'character_fact',
            slotId: 'proposal_1',
            summaryCharCount: 60,
          ),
        ],
        acceptedSignals: const <OutputCoverageSignal>[
          OutputCoverageSignal(
            dimensionId: 'character_fact',
            slotId: 'proposal_1',
            summaryCharCount: 60,
          ),
        ],
        omissionReports: const <OmissionReport>[
          OmissionReport(
            reportId: 'omission_1',
            omittedDimensionIds: <String>['plot_or_mechanism'],
            reasonCode: OmissionReasonCodes.outputBudgetExhausted,
            summary: '未覆盖关键机制。',
          ),
        ],
        continuationRequests: const <ContinuationRequest>[
          ContinuationRequest(
            requestId: 'continue_1',
            continuationReason: '还有维度未覆盖',
            missingDimensionIds: <String>['plot_or_mechanism'],
            suggestedSlotCount: 1,
          ),
        ],
      );

      expect(
        evaluation.completionStatus,
        OutputCompletionStatuses.continuationRecommended,
      );
      expect(
        evaluation.compressionRisk.signalCodes,
        contains(OutputCompressionSignalCodes.continuationRequested),
      );
    });

    test('flags few oversized summaries as compression risk', () {
      final evaluation = service.evaluate(
        budgetPolicy: const OutputBudgetPolicy(
          minOutputSlots: 4,
          maxSummaryCharsPerItem: 100,
        ),
        coverageContract: coverageContract,
        generatedSignals: const <OutputCoverageSignal>[
          OutputCoverageSignal(
            dimensionId: 'character_fact',
            slotId: 'proposal_1',
            summaryCharCount: 180,
          ),
        ],
        acceptedSignals: const <OutputCoverageSignal>[
          OutputCoverageSignal(
            dimensionId: 'character_fact',
            slotId: 'proposal_1',
            summaryCharCount: 180,
          ),
        ],
      );

      expect(
        evaluation.completionStatus,
        OutputCompletionStatuses.coverageInsufficient,
      );
      expect(
        evaluation.compressionRisk.signalCodes,
        containsAll(<String>[
          OutputCompressionSignalCodes.belowMinOutputSlots,
          OutputCompressionSignalCodes.oversizedItemSummary,
          OutputCompressionSignalCodes.uncoveredRequiredDimension,
        ]),
      );
    });

    test(
      'ignores resolved continuation requests once referenced dimensions are covered',
      () {
        final expandedCoverageContract = OutputCoverageContract(
          contractId: 'reference_extraction.standard',
          dimensions: const <OutputCoverageDimension>[
            ReferenceExtractionCoverageDimensions.characterFact,
            ReferenceExtractionCoverageDimensions.settingOrObject,
            ReferenceExtractionCoverageDimensions.plotOrMechanism,
            ReferenceExtractionCoverageDimensions.styleOrTechnique,
            ReferenceExtractionCoverageDimensions.timelineOrBoundary,
          ],
          minCoveredDimensions: 3,
          allowContinuationWhenIncomplete: true,
        );

        final evaluation = service.evaluate(
          budgetPolicy: const OutputBudgetPolicy(minOutputSlots: 4),
          coverageContract: expandedCoverageContract,
          generatedSignals: const <OutputCoverageSignal>[
            OutputCoverageSignal(
              dimensionId: 'character_fact',
              slotId: 'proposal_1',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'setting_or_object',
              slotId: 'proposal_2',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'plot_or_mechanism',
              slotId: 'proposal_3',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'style_or_technique',
              slotId: 'proposal_4',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'timeline_or_boundary',
              slotId: 'proposal_5',
              summaryCharCount: 60,
            ),
          ],
          acceptedSignals: const <OutputCoverageSignal>[
            OutputCoverageSignal(
              dimensionId: 'character_fact',
              slotId: 'proposal_1',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'setting_or_object',
              slotId: 'proposal_2',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'plot_or_mechanism',
              slotId: 'proposal_3',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'style_or_technique',
              slotId: 'proposal_4',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'timeline_or_boundary',
              slotId: 'proposal_5',
              summaryCharCount: 60,
            ),
          ],
          continuationRequests: const <ContinuationRequest>[
            ContinuationRequest(
              requestId: 'continue_1',
              continuationReason: '补充风格和时间线细节',
              missingDimensionIds: <String>[
                'style_or_technique',
                'timeline_or_boundary',
              ],
              suggestedSlotCount: 2,
            ),
          ],
        );

        expect(evaluation.completionStatus, OutputCompletionStatuses.completed);
        expect(
          evaluation.compressionRisk.signalCodes,
          isNot(contains(OutputCompressionSignalCodes.continuationRequested)),
        );
      },
    );

    test(
      'does not block completion when only optional dimensions remain omitted',
      () {
        final expandedCoverageContract = OutputCoverageContract(
          contractId: 'reference_extraction.standard',
          dimensions: const <OutputCoverageDimension>[
            ReferenceExtractionCoverageDimensions.characterFact,
            ReferenceExtractionCoverageDimensions.settingOrObject,
            ReferenceExtractionCoverageDimensions.plotOrMechanism,
            ReferenceExtractionCoverageDimensions.styleOrTechnique,
            ReferenceExtractionCoverageDimensions.timelineOrBoundary,
          ],
          minCoveredDimensions: 3,
          allowContinuationWhenIncomplete: true,
        );

        final evaluation = service.evaluate(
          budgetPolicy: const OutputBudgetPolicy(minOutputSlots: 3),
          coverageContract: expandedCoverageContract,
          generatedSignals: const <OutputCoverageSignal>[
            OutputCoverageSignal(
              dimensionId: 'character_fact',
              slotId: 'proposal_1',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'setting_or_object',
              slotId: 'proposal_2',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'plot_or_mechanism',
              slotId: 'proposal_3',
              summaryCharCount: 60,
            ),
          ],
          acceptedSignals: const <OutputCoverageSignal>[
            OutputCoverageSignal(
              dimensionId: 'character_fact',
              slotId: 'proposal_1',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'setting_or_object',
              slotId: 'proposal_2',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'plot_or_mechanism',
              slotId: 'proposal_3',
              summaryCharCount: 60,
            ),
          ],
          omissionReports: const <OmissionReport>[
            OmissionReport(
              reportId: 'omission_optional',
              omittedDimensionIds: <String>[
                'style_or_technique',
                'timeline_or_boundary',
              ],
              reasonCode: OmissionReasonCodes.outputBudgetExhausted,
              summary: '当前材料没有稳定风格或时间线边界。',
            ),
          ],
          continuationRequests: const <ContinuationRequest>[
            ContinuationRequest(
              requestId: 'continue_optional',
              continuationReason: '如有必要可继续补充风格与边界。',
              missingDimensionIds: <String>[
                'style_or_technique',
                'timeline_or_boundary',
              ],
              suggestedSlotCount: 2,
            ),
          ],
        );

        expect(evaluation.completionStatus, OutputCompletionStatuses.completed);
        expect(
          evaluation.compressionRisk.signalCodes,
          isNot(contains(OutputCompressionSignalCodes.omissionReported)),
        );
        expect(
          evaluation.compressionRisk.signalCodes,
          isNot(contains(OutputCompressionSignalCodes.continuationRequested)),
        );
      },
    );

    test(
      'ignores explicit no-op omission and continuation placeholders',
      () {
        final expandedCoverageContract = OutputCoverageContract(
          contractId: 'reference_extraction.standard',
          dimensions: const <OutputCoverageDimension>[
            ReferenceExtractionCoverageDimensions.characterFact,
            ReferenceExtractionCoverageDimensions.settingOrObject,
            ReferenceExtractionCoverageDimensions.plotOrMechanism,
            ReferenceExtractionCoverageDimensions.styleOrTechnique,
            ReferenceExtractionCoverageDimensions.timelineOrBoundary,
          ],
          minCoveredDimensions: 3,
          allowContinuationWhenIncomplete: true,
        );

        final evaluation = service.evaluate(
          budgetPolicy: const OutputBudgetPolicy(minOutputSlots: 3),
          coverageContract: expandedCoverageContract,
          generatedSignals: const <OutputCoverageSignal>[
            OutputCoverageSignal(
              dimensionId: 'character_fact',
              slotId: 'proposal_1',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'setting_or_object',
              slotId: 'proposal_2',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'plot_or_mechanism',
              slotId: 'proposal_3',
              summaryCharCount: 60,
            ),
          ],
          acceptedSignals: const <OutputCoverageSignal>[
            OutputCoverageSignal(
              dimensionId: 'character_fact',
              slotId: 'proposal_1',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'setting_or_object',
              slotId: 'proposal_2',
              summaryCharCount: 60,
            ),
            OutputCoverageSignal(
              dimensionId: 'plot_or_mechanism',
              slotId: 'proposal_3',
              summaryCharCount: 60,
            ),
          ],
          omissionReports: const <OmissionReport>[
            OmissionReport(
              reportId: 'omit_none',
              omittedDimensionIds: <String>[],
              reasonCode: OmissionReasonCodes.noOmission,
              summary: '本轮没有遗漏。',
            ),
          ],
          continuationRequests: const <ContinuationRequest>[
            ContinuationRequest(
              requestId: 'continue_none',
              continuationReason: ContinuationReasonCodes.noContinuation,
              missingDimensionIds: <String>[],
              suggestedSlotCount: 0,
            ),
          ],
        );

        expect(evaluation.completionStatus, OutputCompletionStatuses.completed);
        expect(
          evaluation.compressionRisk.signalCodes,
          isNot(contains(OutputCompressionSignalCodes.omissionReported)),
        );
        expect(
          evaluation.compressionRisk.signalCodes,
          isNot(contains(OutputCompressionSignalCodes.continuationRequested)),
        );
      },
    );
  });
}
