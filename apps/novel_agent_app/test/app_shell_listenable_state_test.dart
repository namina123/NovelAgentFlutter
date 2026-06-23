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

  test('kb 等非 workbench 目的地也会实时同步会话面板，不冻结在"正在..."中间态', () {
    // 中文注释: kb 项目主落在 projectAssets，水合会写 generationStatus="正在恢复会话..."再清空。
    // 修复前：离开 workbench 后会话 notifier 不再同步，永久冻结在"正在恢复会话..."。
    // 修复后：会话面板无条件同步，状态能正常演进到空（就绪）。
    final state = AppShellListenableState(
      viewModel: AppShellViewModel.initial(),
      activeThemeId: 'theme',
      paneViewDataMapperService: WorkbenchPaneViewDataMapperService(),
    );

    final restoringViewModel = AppShellViewModel.initial().copyWith(
      destination: AppDestination.projectAssets,
      workbench: WorkbenchViewData.initial().copyWith(
        projectName: '知识库项目',
        projectPath: 'D:/Projects/kb',
        generationStatus: '正在恢复会话...',
      ),
    );
    state.syncFrom(viewModel: restoringViewModel, activeThemeId: 'theme');
    expect(
      state.workbenchConversationListenable.value.generationStatus,
      '正在恢复会话...',
    );

    // 水合完成，generationStatus 清空——即便仍停在 projectAssets，会话 notifier 也应跟上。
    final readyViewModel = AppShellViewModel.initial().copyWith(
      destination: AppDestination.projectAssets,
      workbench: WorkbenchViewData.initial().copyWith(
        projectName: '知识库项目',
        projectPath: 'D:/Projects/kb',
        generationStatus: '',
      ),
    );
    state.syncFrom(viewModel: readyViewModel, activeThemeId: 'theme');
    expect(
      state.workbenchConversationListenable.value.generationStatus,
      '',
    );

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
