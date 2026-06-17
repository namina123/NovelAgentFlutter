import 'package:flutter_test/flutter_test.dart';

import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_app/app/state/app_shell_listenable_state.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/shared/view_models/app_shell_view_model.dart';

void main() {
  test('conversation pane falls back safely when mapper overflows', () {
    final state = AppShellListenableState(
      viewModel: AppShellViewModel.initial(),
      activeThemeId: 'theme',
      paneViewDataMapperService: _OverflowConversationMapper(),
    );

    final updatedViewModel = AppShellViewModel.initial().copyWith(
      destination: AppDestination.workbench,
      workbench: WorkbenchViewData.initial().copyWith(
        projectName: '测试项目',
        projectPath: 'D:/Projects/demo',
        generationStatus: '已打开项目',
      ),
    );

    expect(
      () => state.syncFrom(viewModel: updatedViewModel, activeThemeId: 'theme'),
      returnsNormally,
    );

    final conversation = state.workbenchConversationListenable.value;
    expect(conversation, isA<WorkbenchConversationViewData>());
    expect(conversation.contextSummary, '会话面板初始化失败，已切换为安全视图。');
    expect(conversation.generationStatus, contains('会话面板初始化失败'));
    expect(conversation.hasActiveProject, isTrue);

    state.dispose();
  });
}

class _OverflowConversationMapper extends WorkbenchPaneViewDataMapperService {
  @override
  WorkbenchConversationViewData toConversationViewData(
    WorkbenchViewData source,
  ) {
    throw StackOverflowError();
  }
}
