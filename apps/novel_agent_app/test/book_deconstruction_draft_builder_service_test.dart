import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('拆书草稿构建服务会把源文稿收束成结构化预览与应用计划', () async {
    final service = BookDeconstructionDraftBuilderService();

    final result = await service.build(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
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
    expect(
      result.input.preferredContinuationDirection,
      BookDeconstructionContinuationDirection.longTaskPreferred,
    );
    expect(result.extractionResult.chapterOutlines, hasLength(2));
    expect(result.extractionResult.characterProfiles, hasLength(2));
    expect(result.extractionResult.organizationProfiles, hasLength(1));
    expect(result.narrativeArtifacts.claims, isNotEmpty);
    expect(result.narrativeArtifacts.profileProposals, hasLength(1));
    expect(result.narrativeArtifacts.semanticReviews, hasLength(1));
    expect(
      result.narrativeArtifacts.claims.map((claim) => claim.claimNamespace),
      containsAll(<String>[
        'analysis.deconstruction.story_outline',
        'analysis.deconstruction.character_profile',
      ]),
    );
    expect(
      result.narrativeArtifacts.profileProposals.single.source.sourceType,
      NarrativeSourceTypes.explainerInterpreted,
    );
    expect(result.followupMenu.highlightedGroupId, 'fanfic');
    expect(
      result.followupMenu.highlightedOptionId,
      'fanfic_seed_autopilot_novel',
    );
    expect(
      result.followupMenu.highlightedBuildTier,
      ContinuityBuildTier.standardFoundation,
    );
    expect(
      result.followupMenu.groups[1].options.map((item) => item.id),
      contains('fanfic_salvage_restructure_existing'),
    );
    expect(
      result.applicationPlan.items.map((item) => item.relativePathHint),
      containsAll(<String>[
        'outlines/chapters/book_deconstruction_chapter_1.md',
        'assets/styles/deconstruction_style.md',
        'assets/world/world_rules.md',
        'assets/characters/林砚.md',
        'assets/organizations/黑潮议会.md',
      ]),
    );
  });
}
