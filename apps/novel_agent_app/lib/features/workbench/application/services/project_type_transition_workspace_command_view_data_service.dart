import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/selector_option_view_data.dart';
import '../../presentation/models/workspace_command_request_view_data.dart';

class ProjectTypeTransitionWorkspaceCommandViewDataService {
  const ProjectTypeTransitionWorkspaceCommandViewDataService({
    ProjectTypeCatalogService? projectTypeCatalogService,
    ProjectRuntimeBaselineCatalogService? projectRuntimeBaselineCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _projectRuntimeBaselineCatalogService =
           projectRuntimeBaselineCatalogService ??
           const ProjectRuntimeBaselineCatalogService();

  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ProjectRuntimeBaselineCatalogService
  _projectRuntimeBaselineCatalogService;

  WorkspaceCommandViewData build({
    required ProjectDescriptor project,
    required ProjectTypeTransitionPlan plan,
    required String runtimeBaselineId,
    required String confirmLabel,
    String status = '',
  }) {
    final sourceLabel =
        plan.sourceProjectTypeDefinition?.name ?? project.projectType;
    final targetProjectTypeId = _selectedTargetProjectTypeId(project, plan);
    final targetDefinition = _projectTypeCatalogService.definitionOf(
      targetProjectTypeId,
    );
    final targetLabel = targetDefinition.name;
    final normalizedRuntimeBaselineId = _selectedRuntimeBaselineId(
      targetProjectTypeId: targetProjectTypeId,
      requestedRuntimeBaselineId: runtimeBaselineId,
      plan: plan,
    );
    return WorkspaceCommandViewData(
      mode: WorkspaceCommandMode.transitionProjectType,
      title: '项目类型转换',
      description: '将 $sourceLabel 切换为 $targetLabel，存储策略保持不变。',
      confirmLabel: confirmLabel,
      status: status.trim().isNotEmpty ? status.trim() : _statusOf(plan),
      projectTitle: project.name,
      projectType: targetProjectTypeId,
      transitionTargetProjectTypeId: targetProjectTypeId,
      transitionRuntimeBaselineId: normalizedRuntimeBaselineId,
      transitionTargetProjectTypeOptions: _targetProjectTypeOptions(plan),
      transitionRuntimeBaselineOptions: _runtimeBaselineOptions(
        targetProjectTypeId,
      ),
      transitionRequiresRuntimeBaselineSelection:
          targetDefinition.requiresRuntimeBaselineSelection,
      genre: '',
      premise: '',
      notes: '',
      relativePath: '',
      entryName: '',
      content: '',
      sourcePathsText: '',
      targetDirectory: '',
    );
  }

  String statusOf(ProjectTypeTransitionPlan plan) => _statusOf(plan);

  List<SelectorOptionViewData> _targetProjectTypeOptions(
    ProjectTypeTransitionPlan plan,
  ) {
    return List<SelectorOptionViewData>.unmodifiable(
      plan.availableTargetProjectTypeIds.map((id) {
        final definition = _projectTypeCatalogService.definitionOf(id);
        return SelectorOptionViewData(
          id: definition.id,
          label: definition.name,
          note: definition.description,
        );
      }),
    );
  }

  List<SelectorOptionViewData> _runtimeBaselineOptions(String projectTypeId) {
    return List<SelectorOptionViewData>.unmodifiable(
      _projectRuntimeBaselineCatalogService
          .definitionsForProjectType(projectTypeId)
          .where((definition) => definition.enabled)
          .map(
            (definition) => SelectorOptionViewData(
              id: definition.id,
              label: definition.title,
              note: definition.description,
            ),
          ),
    );
  }

  String _selectedTargetProjectTypeId(
    ProjectDescriptor project,
    ProjectTypeTransitionPlan plan,
  ) {
    final explicit = plan.targetProjectTypeDefinition?.id.trim() ?? '';
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final requestTarget = plan.request.targetProjectTypeId.trim();
    if (requestTarget.isNotEmpty &&
        plan.availableTargetProjectTypeIds.contains(requestTarget)) {
      return requestTarget;
    }
    if (plan.availableTargetProjectTypeIds.isNotEmpty) {
      return plan.availableTargetProjectTypeIds.first;
    }
    return project.projectType.trim();
  }

  String _selectedRuntimeBaselineId({
    required String targetProjectTypeId,
    required String requestedRuntimeBaselineId,
    required ProjectTypeTransitionPlan plan,
  }) {
    final normalized = plan.targetRuntimeBaselineId.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return _projectRuntimeBaselineCatalogService.normalizeForProjectType(
      targetProjectTypeId,
      requestedRuntimeBaselineId,
    );
  }

  String _statusOf(ProjectTypeTransitionPlan plan) {
    if (plan.blockers.isEmpty) {
      if (plan.targetProjectTypeDefinition?.id == 'long_novel') {
        return '转换条件已满足，请确认运行基准后执行。';
      }
      return '转换条件已满足，提交后会保留原存储策略。';
    }
    return plan.blockers.map((blocker) => blocker.message).join('；');
  }
}
