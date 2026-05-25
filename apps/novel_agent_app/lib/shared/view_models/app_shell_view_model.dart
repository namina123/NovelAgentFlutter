import '../../app/routing/app_destination.dart';
import '../../features/agent_ecosystem/presentation/models/agent_ecosystem_view_data.dart';
import '../../features/project_assets/presentation/models/project_assets_view_data.dart';
import '../../features/prompt_templates/presentation/models/prompt_templates_view_data.dart';
import '../../features/project_collection/presentation/models/project_collection_view_data.dart';
import '../../features/review_center/presentation/models/review_center_view_data.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/task_center/presentation/models/task_center_view_data.dart';
import '../../features/workbench/presentation/models/workbench_view_data.dart';

class AppShellViewModel {
  const AppShellViewModel({
    required this.destination,
    required this.workbench,
    required this.settings,
    required this.agentEcosystem,
    required this.projectCollection,
    required this.taskCenter,
    required this.reviewCenter,
    required this.promptTemplates,
    required this.projectAssets,
  });

  final AppDestination destination;
  final WorkbenchViewData workbench;
  final SettingsViewData settings;
  final AgentEcosystemViewData agentEcosystem;
  final ProjectCollectionViewData projectCollection;
  final TaskCenterViewData taskCenter;
  final ReviewCenterViewData reviewCenter;
  final PromptTemplatesViewData promptTemplates;
  final ProjectAssetsViewData projectAssets;

  factory AppShellViewModel.initial() {
    return AppShellViewModel(
      destination: AppDestination.workbench,
      workbench: WorkbenchViewData.initial(),
      settings: SettingsViewData.initial(),
      agentEcosystem: AgentEcosystemViewData.initial(),
      projectCollection: ProjectCollectionViewData.initial(),
      taskCenter: TaskCenterViewData.initial(),
      reviewCenter: ReviewCenterViewData.initial(),
      promptTemplates: PromptTemplatesViewData.initial(),
      projectAssets: ProjectAssetsViewData.initial(),
    );
  }

  AppShellViewModel copyWith({
    AppDestination? destination,
    WorkbenchViewData? workbench,
    SettingsViewData? settings,
    AgentEcosystemViewData? agentEcosystem,
    ProjectCollectionViewData? projectCollection,
    TaskCenterViewData? taskCenter,
    ReviewCenterViewData? reviewCenter,
    PromptTemplatesViewData? promptTemplates,
    ProjectAssetsViewData? projectAssets,
  }) {
    // 中文注释: copyWith 用于只替换当前页面相关的视图状态，避免整份壳层状态被粗暴重建。
    return AppShellViewModel(
      destination: destination ?? this.destination,
      workbench: workbench ?? this.workbench,
      settings: settings ?? this.settings,
      agentEcosystem: agentEcosystem ?? this.agentEcosystem,
      projectCollection: projectCollection ?? this.projectCollection,
      taskCenter: taskCenter ?? this.taskCenter,
      reviewCenter: reviewCenter ?? this.reviewCenter,
      promptTemplates: promptTemplates ?? this.promptTemplates,
      projectAssets: projectAssets ?? this.projectAssets,
    );
  }
}
