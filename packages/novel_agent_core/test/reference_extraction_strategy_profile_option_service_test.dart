import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionStrategyProfileOptionService', () {
    const service = ReferenceExtractionStrategyProfileOptionService();

    test('builds readable builtin options', () {
      final options = service.listOptions();

      expect(options, hasLength(4));
      expect(
        options.map((item) => item.displayName),
        containsAll(<String>['标准提取', '长上下文整书', '事实优先', '探索扩展']),
      );
      expect(
        options
            .firstWhere(
              (item) =>
                  item.profileId ==
                  ReferenceExtractionBuiltinStrategyProfileIds.standard,
            )
            .summary,
        contains('默认提取策略'),
      );
    });

    test('prefers metadata from additional custom profiles', () {
      const custom = ReferenceExtractionStrategyProfile(
        profileId: 'reference_extraction.custom_dense',
        proposalPolicy: ReferenceExtractionProposalPolicy(
          minProposalCount: 6,
          maxProposalCount: 9,
          allowedEntryKinds: <String>[
            ReferenceEntryKinds.knowledgeFact,
            ReferenceEntryKinds.designElement,
          ],
        ),
        reviewPolicy: ReferenceExtractionReviewPolicy(
          acceptanceThreshold: 0.88,
          candidateThreshold: 0.66,
          requireEvidence: false,
        ),
        metadata: <String, Object?>{
          'display_name': '高密度提取',
          'summary': '适合先把候选铺开，再人工二筛。',
        },
      );

      final option = service.optionById(
        custom.profileId,
        additionalProfiles: const <ReferenceExtractionStrategyProfile>[custom],
      );

      expect(option, isNotNull);
      expect(option!.displayName, '高密度提取');
      expect(option.summary, '适合先把候选铺开，再人工二筛。');
      expect(option.proposalCountLabel, '6-9 条候选');
      expect(option.entryKindsLabel, '知识事实、设计元素');
      expect(option.reviewPolicyLabel, contains('证据可放宽'));
      expect(option.isBuiltin, isFalse);
    });
  });
}
