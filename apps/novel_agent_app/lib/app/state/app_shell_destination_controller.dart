import 'dart:async';

import '../diagnostics/navigation_trace_service.dart';
import '../diagnostics/project_hydration_trace_service.dart';
import '../../features/long_task_station/application/controllers/long_task_station_controller.dart';
import '../routing/app_destination.dart';

class AppShellDestinationController {
  AppShellDestinationController({
    required AppDestination Function() readCurrentDestination,
    required void Function(AppDestination destination) changeDestination,
    required Future<void> Function() refreshProjectOpen,
    required Future<void> Function() refreshTaskCenter,
    required LongTaskStationController longTaskStationController,
    NavigationTraceService? navigationTraceService,
    ProjectHydrationTraceService? projectHydrationTraceService,
    String Function()? readCurrentProjectPath,
    bool Function()? isProjectHydrationInProgress,
  }) : _changeDestination = changeDestination,
       _readCurrentDestination = readCurrentDestination,
       _refreshProjectOpen = refreshProjectOpen,
       _refreshTaskCenter = refreshTaskCenter,
       _longTaskStationController = longTaskStationController,
       _navigationTraceService = navigationTraceService,
       _projectHydrationTraceService = projectHydrationTraceService,
       _readCurrentProjectPath = readCurrentProjectPath,
       _isProjectHydrationInProgress = isProjectHydrationInProgress;

  final void Function(AppDestination destination) _changeDestination;
  final AppDestination Function() _readCurrentDestination;
  final Future<void> Function() _refreshProjectOpen;
  final Future<void> Function() _refreshTaskCenter;
  final LongTaskStationController _longTaskStationController;
  final NavigationTraceService? _navigationTraceService;
  final ProjectHydrationTraceService? _projectHydrationTraceService;
  final String Function()? _readCurrentProjectPath;
  final bool Function()? _isProjectHydrationInProgress;

  Future<void> showProjectOpen() async {
    // 中文注释: 打开项目页时先立刻切页，再后台刷新项目发现结果，避免目录扫描阻塞导航。
    _beginNavigation(AppDestination.projectOpen, reason: 'showProjectOpen');
    _changeDestination(AppDestination.projectOpen);
    unawaited(_refreshProjectOpen());
  }

  void showWorkbench() {
    // 中文注释: 壳层导航只负责切换全局目的地，不直接持有任何页面业务状态。
    _beginNavigation(AppDestination.workbench, reason: 'showWorkbench');
    _changeDestination(AppDestination.workbench);
  }

  void showSettings() {
    // 中文注释: 设置页导航统一从壳层发起，避免各 feature 自己改全局路由。
    _beginNavigation(AppDestination.settings, reason: 'showSettings');
    _changeDestination(AppDestination.settings);
  }

  Future<void> showBookDeconstructionWorkbench() async {
    // 中文注释: 拆书分析现在恢复为独立次级页，避免再借资料页壳层导致流程语义错位。
    _beginNavigation(
      AppDestination.bookDeconstruction,
      reason: 'showBookDeconstructionWorkbench',
    );
    _changeDestination(AppDestination.bookDeconstruction);
  }

  Future<void> showInspirationWorkbench() async {
    // 中文注释: 灵感不再作为独立全局目的地，旧入口暂时收束回工作台。
    showWorkbench();
  }

  Future<void> showAgentEcosystem() async {
    // 中文注释: 智能体生态页现在纳入主导航“工作”分组，切页仍只由壳层统一分发。
    _beginNavigation(
      AppDestination.agentEcosystem,
      reason: 'showAgentEcosystem',
    );
    _changeDestination(AppDestination.agentEcosystem);
  }

  Future<void> showProjectCollection() async {
    // 中文注释: 历史项目库入口统一并入“打开项目”。
    await showProjectOpen();
  }

  Future<void> showTaskCenter() async {
    // 中文注释: 任务中心作为长任务参数与队列控制面保留可直达入口，但仍不占主导航常驻位。
    _beginNavigation(AppDestination.taskCenter, reason: 'showTaskCenter');
    _changeDestination(AppDestination.taskCenter);
    await _refreshTaskCenter();
  }

  Future<void> showLongTaskStation() async {
    // 中文注释: 长任务总站是全局运行入口，路由切换后由独立控制器决定初始化还是刷新。
    _beginNavigation(
      AppDestination.longTaskStation,
      reason: 'showLongTaskStation',
    );
    _changeDestination(AppDestination.longTaskStation);
    await _longTaskStationController.onVisibilityRequested();
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
    _beginNavigation(AppDestination.projectAssets, reason: 'showProjectAssets');
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
      case AppDestination.bookDeconstruction:
        await showBookDeconstructionWorkbench();
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

  void _beginNavigation(
    AppDestination destination, {
    required String reason,
  }) {
    // 中文注释: 切页起点统一从这里记录，避免每个 show 方法各自拼一套 trace 逻辑。
    _recordHydrationDestinationChange(destination);
    _navigationTraceService?.beginNavigation(
      from: _readCurrentDestination(),
      to: destination,
      reason: reason,
    );
  }

  void _recordHydrationDestinationChange(AppDestination destination) {
    // 中文注释: 如果项目 hydration 正在进行，这里单独记一条切页冲突轨迹，方便后续排查打架来源。
    final traceService = _projectHydrationTraceService;
    final isHydrating = _isProjectHydrationInProgress?.call() ?? false;
    final currentProjectPath = _readCurrentProjectPath?.call().trim() ?? '';
    final activeToken = traceService?.activeToken;
    if (traceService == null ||
        !isHydrating ||
        currentProjectPath.isEmpty ||
        activeToken == null) {
      return;
    }
    traceService.recordDestinationChangeDuringHydration(
      token: activeToken,
      projectPath: currentProjectPath,
      from: _readCurrentDestination(),
      to: destination,
    );
  }
}
