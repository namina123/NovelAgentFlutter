import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_operation_kind.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_snapshot.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('拆书 view data 会投影 continuity 默认导向与后续菜单', () async {
    final draftBuilder = BookDeconstructionDraftBuilderService();
    final viewDataService = BookDeconstructionViewDataService();
    final buildResult = await draftBuilder.build(
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
      containsAll(<String>['continuation', 'fanfic']),
    );
    expect(viewData.informationBridge, isNotNull);
    expect(
      viewData.informationBridge!.followupRoutes.map((item) => item.title),
      containsAll(<String>['continuation', 'fanfic', '共享资料沉淀', '解说与分析']),
    );
    expect(
      viewData.informationBridge!.summary,
      isNot(contains('information GUI')),
    );
    expect(
      viewData.informationBridge!.assetStatuses.map((item) => item.title),
      containsAll(<String>['设定与章纲', '角色与组织', 'information 资料', 'design 巧思']),
    );
    final informationStatus = viewData.informationBridge!.assetStatuses
        .firstWhere((item) => item.id == 'information_assets');
    expect(informationStatus.count, 5);
    expect(informationStatus.statusLabel, '确认后出现在知识 / 研究 / 引用边界');
    final designStatus = viewData.informationBridge!.assetStatuses.firstWhere(
      (item) => item.id == 'design_assets',
    );
    expect(designStatus.count, 2);
    expect(designStatus.statusLabel, '确认后出现在巧思与设计');
    expect(designStatus.summary, isNot(contains('information GUI')));
    expect(viewData.informationBridge!.reuseSummary, contains('continuation'));
  });

  test('拆书 view data 会按运行阶段切换按钮文案', () {
    final viewDataService = BookDeconstructionViewDataService();

    final importingViewData = viewDataService.build(
      projectTitle: '拆书测试项目',
      snapshot: BookDeconstructionSnapshot.initial().copyWith(
        isLoading: true,
        operationKind: BookDeconstructionOperationKind.importingSource,
      ),
      status: '正在读取拆书源文件...',
    );
    final buildingViewData = viewDataService.build(
      projectTitle: '拆书测试项目',
      snapshot: BookDeconstructionSnapshot.initial().copyWith(
        isLoading: true,
        sourceContent: '第一章 港口风暴',
        operationKind: BookDeconstructionOperationKind.buildingPreview,
      ),
      status: '正在生成结构化预览...',
    );

    expect(importingViewData.importActionLabel, '正在导入');
    expect(importingViewData.canBuildPreview, isFalse);
    expect(buildingViewData.buildPreviewActionLabel, '正在拆书');
    expect(buildingViewData.canBuildPreview, isFalse);
  });
}
