import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_snapshot.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('拆书 view data 会投影 continuity 默认导向与后续菜单', () {
    final draftBuilder = BookDeconstructionDraftBuilderService();
    final viewDataService = BookDeconstructionViewDataService();
    final buildResult = draftBuilder.build(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: 'D:/books/harbor_story.txt',
      operatorNotes: '先保留章纲和角色。',
      styleSummary: '节奏偏商业，冲突推进快。',
      worldRulesText: '城邦权力依靠航线垄断。',
      characterLinesText: '林砚：主角',
      organizationLinesText: '黑潮议会：港口势力',
      preferredContinuationDirection:
          BookDeconstructionContinuationDirection.longTaskPreferred,
    );

    final viewData = viewDataService.build(
      projectTitle: '拆书测试项目',
      snapshot: BookDeconstructionSnapshot.initial().copyWith(
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
      ),
      status: '已生成结构化预览。',
    );

    expect(viewData.continuity, isNotNull);
    expect(viewData.continuity!.preferredDirectionLabel, '长任务续写优先');
    expect(viewData.continuity!.highlightedBuildTierLabel, '标准基座');
    expect(viewData.continuity!.highlightedRouteTitle, '灵感托管式长篇');
    expect(
      viewData.continuity!.followupGroups.map((item) => item.id),
      containsAll(<String>['general_writing', 'long_task_writing']),
    );
  });
}
