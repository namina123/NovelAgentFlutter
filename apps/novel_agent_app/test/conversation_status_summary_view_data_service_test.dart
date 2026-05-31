import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/services/conversation_status_summary_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/tool_preview_mode.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';

void main() {
  const service = ConversationStatusSummaryViewDataService();
  const mapper = WorkbenchPaneViewDataMapperService();

  test('build returns no resident status items for main conversation UI', () {
    final conversationViewData = mapper.toConversationViewData(
      WorkbenchViewData.initial().copyWith(
        groupSelector: const ConversationGroupSelectorViewData(
          currentGroupLabel: '默认组',
          groupOptions: [],
          primaryAgentLabel: '综合创作智能体',
          primaryAgentDescription: '',
          canSwitchGroup: false,
        ),
        contextSummary: '已载入角色、世界观与章节约束，并补齐当前大纲摘要。',
        toolCoreStatus: '正在整理上下文与工具可见性',
        generationStatus: '正在请求模型生成内容...',
        isGenerating: true,
      ),
    );

    final viewData = service.build(viewData: conversationViewData);

    expect(viewData.items, isEmpty);
  });

  test('showToolDetails returns false for compact mode', () {
    final conversationViewData = mapper.toConversationViewData(
      WorkbenchViewData.initial().copyWith(
        toolPreviewMode: ToolPreviewMode.compact,
      ),
    );

    expect(service.showToolDetails(conversationViewData), isFalse);
  });

  test('showToolDetails returns true for detail mode', () {
    final conversationViewData = mapper.toConversationViewData(
      WorkbenchViewData.initial().copyWith(
        toolPreviewMode: ToolPreviewMode.detail,
      ),
    );

    expect(service.showToolDetails(conversationViewData), isTrue);
  });
}
