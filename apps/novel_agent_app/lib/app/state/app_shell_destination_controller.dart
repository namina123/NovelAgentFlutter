import '../../features/long_task_station/application/controllers/long_task_station_controller.dart';
import '../routing/app_destination.dart';

class AppShellDestinationController {
  AppShellDestinationController({
    required void Function(AppDestination destination) changeDestination,
    required Future<void> Function() refreshAgentEcosystem,
    required Future<void> Function() refreshTaskCenter,
    required Future<void> Function() refreshReviewCenter,
    required Future<void> Function() refreshPromptTemplates,
    required Future<void> Function() refreshProjectAssets,
    required LongTaskStationController longTaskStationController,
  }) : _changeDestination = changeDestination,
       _refreshAgentEcosystem = refreshAgentEcosystem,
       _refreshTaskCenter = refreshTaskCenter,
       _refreshReviewCenter = refreshReviewCenter,
       _refreshPromptTemplates = refreshPromptTemplates,
       _refreshProjectAssets = refreshProjectAssets,
       _longTaskStationController = longTaskStationController;

  final void Function(AppDestination destination) _changeDestination;
  final Future<void> Function() _refreshAgentEcosystem;
  final Future<void> Function() _refreshTaskCenter;
  final Future<void> Function() _refreshReviewCenter;
  final Future<void> Function() _refreshPromptTemplates;
  final Future<void> Function() _refreshProjectAssets;
  final LongTaskStationController _longTaskStationController;

  void showWorkbench() {
    // 中文注释: 壳层导航只负责切换全局目的地，不直接持有任何页面业务状态。
    _changeDestination(AppDestination.workbench);
  }

  void showSettings() {
    // 中文注释: 设置页导航统一从壳层发起，避免各 feature 自己改全局路由。
    _changeDestination(AppDestination.settings);
  }

  Future<void> showAgentEcosystem() async {
    // 中文注释: 导航切换与页面数据刷新在壳层并排组织，子域不反向操作全局路由。
    _changeDestination(AppDestination.agentEcosystem);
    await _refreshAgentEcosystem();
  }

  Future<void> showTaskCenter() async {
    // 中文注释: 任务中心属于壳层全局入口，切页后立即刷新当前项目上下文。
    _changeDestination(AppDestination.taskCenter);
    await _refreshTaskCenter();
  }

  Future<void> showLongTaskStation() async {
    // 中文注释: 长任务总站是全局运行入口，路由切换后由独立控制器决定初始化还是刷新。
    _changeDestination(AppDestination.longTaskStation);
    if (_longTaskStationController.isInitialized) {
      await _longTaskStationController.refresh();
      return;
    }
    await _longTaskStationController.initialize();
  }

  Future<void> showReviewCenter() async {
    // 中文注释: 审稿中心切换后立刻同步当前项目的审稿列表，避免展示旧上下文。
    _changeDestination(AppDestination.reviewCenter);
    await _refreshReviewCenter();
  }

  Future<void> showPromptTemplates() async {
    // 中文注释: 模板中心导航只留在壳层，模板具体数据刷新仍由对应 feature 完成。
    _changeDestination(AppDestination.promptTemplates);
    await _refreshPromptTemplates();
  }

  Future<void> showProjectAssets() async {
    // 中文注释: 项目资产中心也是全局页签入口，刷新逻辑不再散落在工作台按钮里。
    _changeDestination(AppDestination.projectAssets);
    await _refreshProjectAssets();
  }
}
