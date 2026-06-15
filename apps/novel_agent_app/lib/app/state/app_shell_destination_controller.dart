import '../../features/long_task_station/application/controllers/long_task_station_controller.dart';
import '../routing/app_destination.dart';

class AppShellDestinationController {
  AppShellDestinationController({
    required void Function(AppDestination destination) changeDestination,
    required Future<void> Function() refreshProjectOpen,
    required Future<void> Function() refreshTaskCenter,
    required LongTaskStationController longTaskStationController,
  }) : _changeDestination = changeDestination,
       _refreshProjectOpen = refreshProjectOpen,
       _refreshTaskCenter = refreshTaskCenter,
       _longTaskStationController = longTaskStationController;

  final void Function(AppDestination destination) _changeDestination;
  final Future<void> Function() _refreshProjectOpen;
  final Future<void> Function() _refreshTaskCenter;
  final LongTaskStationController _longTaskStationController;

  Future<void> showProjectOpen() async {
    // 中文注释: 打开项目页是唯一项目入口，壳层切页后只刷新项目浏览读态。
    _changeDestination(AppDestination.projectOpen);
    await _refreshProjectOpen();
  }

  void showWorkbench() {
    // 中文注释: 壳层导航只负责切换全局目的地，不直接持有任何页面业务状态。
    _changeDestination(AppDestination.workbench);
  }

  void showSettings() {
    // 中文注释: 设置页导航统一从壳层发起，避免各 feature 自己改全局路由。
    _changeDestination(AppDestination.settings);
  }

  Future<void> showBookDeconstructionWorkbench() async {
    // 中文注释: 拆书不再作为独立全局目的地，旧入口暂时收束回工作台。
    showWorkbench();
  }

  Future<void> showInspirationWorkbench() async {
    // 中文注释: 灵感不再作为独立全局目的地，旧入口暂时收束回工作台。
    showWorkbench();
  }

  Future<void> showAgentEcosystem() async {
    // 中文注释: 智能体生态页现在纳入主导航“工作”分组，切页仍只由壳层统一分发。
    _changeDestination(AppDestination.agentEcosystem);
  }

  Future<void> showProjectCollection() async {
    // 中文注释: 历史项目库入口统一并入“打开项目”。
    await showProjectOpen();
  }

  Future<void> showTaskCenter() async {
    // 中文注释: 任务中心作为长任务参数与队列控制面保留可直达入口，但仍不占主导航常驻位。
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
    // 中文注释: 审稿中心已从主导航退役，旧入口先统一折返到长任务总站。
    await showLongTaskStation();
  }

  Future<void> showPromptTemplates() async {
    // 中文注释: 模板能力后续并回项目面板，旧入口先统一回到工作台。
    showWorkbench();
  }

  Future<void> showProjectAssets() async {
    // 中文注释: 项目资产页不在主导航常驻，但仍保留为可直达的次级能力页。
    _changeDestination(AppDestination.projectAssets);
  }

  Future<void> showDestination(AppDestination destination) async {
    // 中文注释: 全局活动栏统一从这里分发目标页，避免根壳层直接拼子域刷新逻辑。
    switch (destination) {
      case AppDestination.projectOpen:
        await showProjectOpen();
        return;
      case AppDestination.workbench:
        showWorkbench();
        return;
      case AppDestination.agentEcosystem:
        await showAgentEcosystem();
        return;
      case AppDestination.projectAssets:
        await showProjectAssets();
        return;
      case AppDestination.longTaskStation:
        await showLongTaskStation();
        return;
      case AppDestination.taskCenter:
        await showTaskCenter();
        return;
      case AppDestination.settings:
        showSettings();
        return;
    }
  }
}
