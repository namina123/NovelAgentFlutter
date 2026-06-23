import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BuildBookDeconstructionDraftUseCase', () {
    final useCase = BuildBookDeconstructionDraftUseCase();

    test('会把输入、抽取、应用计划、followup 和 narrative 桥串成正式预演结果', () {
      final result = useCase.execute(
        sourceTitle: '海上城邦',
        sourceContent:
            '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
        sourceAbsolutePath: 'D:/books/harbor_story.txt',
        operatorNotes: '先保留章纲和角色。',
        styleSummary: '节奏偏商业，冲突推进快。',
        worldRulesText: '城邦权力依靠航线垄断。\n超常能力必须通过印记媒介释放。',
        characterLinesText: '林砚：被迫卷入城邦风暴的主角\n议长：操控议会的核心人物',
        organizationLinesText: '黑潮议会：掌控港口秩序的势力',
        preferredContinuationDirection:
            BookDeconstructionContinuationDirection.longTaskPreferred,
      );

      expect(result.input.title, '海上城邦');
      expect(result.extractionResult.chapterOutlines, hasLength(2));
      expect(result.extractionResult.characterProfiles, hasLength(2));
      expect(result.extractionResult.organizationProfiles, hasLength(1));
      expect(result.applicationPlan.items, isNotEmpty);
      expect(result.followupMenu.highlightedGroupId, 'fanfic');
      expect(result.narrativeArtifacts.claims, isNotEmpty);
      expect(
        result.narrativeArtifacts.profileProposals.single.source.sourceType,
        NarrativeSourceTypes.explainerInterpreted,
      );
    });

    test('extractKnowledge=false 时只做纯拆书（分章），不产出任何知识抽取资产', () {
      // 中文注释: 规格要求"拆书就是拆书，不涉及其他"：extractKnowledge=false 时只分章 + 章节骨架，
      // 不派生故事总纲/前提/角色/世界/时间线/伏笔/关系，也不产出叙事桥的 claims/proposals。
      final result = useCase.execute(
        sourceTitle: '海上城邦',
        sourceContent:
            '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
        sourceAbsolutePath: 'D:/books/harbor_story.txt',
        operatorNotes: '',
        styleSummary: '节奏偏商业，冲突推进快。',
        worldRulesText: '城邦权力依靠航线垄断。',
        characterLinesText: '林砚：主角',
        organizationLinesText: '黑潮议会：势力',
        preferredContinuationDirection:
            BookDeconstructionContinuationDirection.longTaskPreferred,
        extractKnowledge: false,
      );

      // 分章仍然产出（这是拆书的本职）。
      expect(result.extractionResult.chapterOutlines, hasLength(2));
      // 知识抽取资产必须为空——拆书不做这些。
      expect(result.extractionResult.premises, isEmpty);
      expect(result.extractionResult.storyOutlineSummary, isEmpty);
      expect(result.extractionResult.characterProfiles, isEmpty);
      expect(result.extractionResult.organizationProfiles, isEmpty);
      expect(result.extractionResult.worldRuleSets, isEmpty);
      expect(result.extractionResult.styleProfiles, isEmpty);
      expect(result.extractionResult.timelineRecords, isEmpty);
      expect(result.extractionResult.foreshadowRecords, isEmpty);
      expect(result.extractionResult.relationshipRecords, isEmpty);
      // 应用计划只含章纲类条目，不含前提/角色/世界等资产条目。
      final sourceKinds = result.applicationPlan.items
          .map((item) => item.sourceKind)
          .toSet();
      expect(sourceKinds, contains(BookDeconstructionArtifactKind.chapterOutline));
      expect(sourceKinds, isNot(contains(BookDeconstructionArtifactKind.premise)));
      expect(
        sourceKinds,
        isNot(contains(BookDeconstructionArtifactKind.characterProfile)),
      );
      // 纯拆书不产出叙事桥的分析 claims。
      expect(result.narrativeArtifacts.claims, isEmpty);
      // 后续菜单照常可用（路线选择是进入创作的必要环节，与知识抽取无关）。
      expect(result.followupMenu.groups, isNotEmpty);
    });
  });
}
