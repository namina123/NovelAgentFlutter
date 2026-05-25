import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Inspiration shared capability', () {
    test('stage catalog exposes shared convergence stages', () {
      const catalog = InspirationConvergenceStageCatalogService();

      expect(
        catalog.stageIdForFieldKey(InspirationFieldKey.seedMaterial),
        InspirationConvergenceStageCatalogService.seedStageId,
      );
      expect(
        catalog.stageIdForFieldKey(InspirationFieldKey.worldAnchor),
        InspirationConvergenceStageCatalogService.worldStageId,
      );
      expect(
        catalog.stages().map((stage) => stage.id),
        containsAll(<String>[
          InspirationConvergenceStageCatalogService.premiseStageId,
          InspirationConvergenceStageCatalogService.styleStageId,
          InspirationConvergenceStageCatalogService.characterStageId,
        ]),
      );
    });

    test('maps mode guidance state into shared inspiration record', () {
      final transitionService = ModeGuidanceTransitionService();
      final mapper = ModeGuidanceInspirationRecordMapperService();
      var state = transitionService.initialize('full_outline_consensus');
      state = transitionService.answer(
        state,
        stageId: 'book_premise',
        fieldKey: 'book_premise',
        value: '一位失势公主在皇储争夺战中重新集结旧部。',
      );
      state = transitionService.answer(
        state,
        stageId: 'main_arc',
        fieldKey: 'main_arc',
        value: '她必须在朝堂与边军之间建立脆弱联盟。',
      );
      state = transitionService.answer(
        state,
        stageId: 'style_and_boundaries',
        fieldKey: 'style_and_boundaries',
        value: '文风克制、冷静、偏商业长篇。',
      );

      final record = mapper.map(state);
      final fieldKeys = record.fieldValues
          .map((value) => value.fieldKey)
          .toList(growable: false);

      expect(record.title, contains('全书共拟式长篇'));
      expect(fieldKeys, contains(InspirationFieldKey.premise));
      expect(fieldKeys, contains(InspirationFieldKey.mainArc));
      expect(fieldKeys, contains(InspirationFieldKey.styleTarget));
      expect(
        record.completedStageIds,
        contains(InspirationConvergenceStageCatalogService.premiseStageId),
      );
    });

    test('projects shared inspiration into premise style world and character assets', () {
      const service = InspirationProjectionService();
      final projection = service.build(
        const InspirationRecord(
          id: 'mode_seed_autopilot_novel',
          title: '灵感托管式长篇灵感记录',
          fieldValues: <InspirationFieldValue>[
            InspirationFieldValue(
              stageId: 'premise',
              fieldKey: InspirationFieldKey.corePromise,
              value: '高压权谋、持续逆转与身份翻盘。',
            ),
            InspirationFieldValue(
              stageId: 'world',
              fieldKey: InspirationFieldKey.worldAnchor,
              value: '帝国靠誓约维持秩序。高位者违约会遭受反噬。',
            ),
            InspirationFieldValue(
              stageId: 'characters',
              fieldKey: InspirationFieldKey.protagonistDrive,
              value: '主角必须翻案并找回家族名誉。',
            ),
            InspirationFieldValue(
              stageId: 'style',
              fieldKey: InspirationFieldKey.styleTarget,
              value: '文风干净利落，偏商业长篇。',
            ),
            InspirationFieldValue(
              stageId: 'autonomy',
              fieldKey: InspirationFieldKey.autonomyGuardrails,
              value: '跨卷重大转折必须先确认。',
            ),
          ],
        ),
      );

      expect(projection.premises, hasLength(1));
      expect(projection.styleProfiles, hasLength(1));
      expect(projection.worldRuleSets, hasLength(1));
      expect(projection.characterProfiles, hasLength(1));
      expect(
        projection.premises.single.corePromise,
        '高压权谋、持续逆转与身份翻盘。',
      );
      expect(
        projection.styleProfiles.single.guardrails,
        contains('跨卷重大转折必须先确认。'),
      );
      expect(projection.worldRuleSets.single.rules, hasLength(2));
      expect(projection.characterProfiles.single.storyRole, 'protagonist');
    });
  });
}
