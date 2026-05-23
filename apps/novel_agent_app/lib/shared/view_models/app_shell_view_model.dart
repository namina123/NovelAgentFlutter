import '../../app/routing/app_destination.dart';
import '../../features/agent_ecosystem/presentation/models/agent_ecosystem_view_data.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/workbench/presentation/models/workbench_view_data.dart';

class AppShellViewModel {
  const AppShellViewModel({
    required this.destination,
    required this.workbench,
    required this.settings,
    required this.agentEcosystem,
  });

  final AppDestination destination;
  final WorkbenchViewData workbench;
  final SettingsViewData settings;
  final AgentEcosystemViewData agentEcosystem;

  factory AppShellViewModel.initial() {
    return AppShellViewModel(
      destination: AppDestination.workbench,
      workbench: WorkbenchViewData.initial(),
      settings: SettingsViewData.initial(),
      agentEcosystem: AgentEcosystemViewData.initial(),
    );
  }

  AppShellViewModel copyWith({
    AppDestination? destination,
    WorkbenchViewData? workbench,
    SettingsViewData? settings,
    AgentEcosystemViewData? agentEcosystem,
  }) {
    // 中文注释: copyWith 用于只替换当前页面相关的视图状态，避免整份壳层状态被粗暴重建。
    return AppShellViewModel(
      destination: destination ?? this.destination,
      workbench: workbench ?? this.workbench,
      settings: settings ?? this.settings,
      agentEcosystem: agentEcosystem ?? this.agentEcosystem,
    );
  }
}
