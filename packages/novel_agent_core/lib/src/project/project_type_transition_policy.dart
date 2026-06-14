import 'project_runtime_baseline_catalog_service.dart';
import 'project_storage_strategy.dart';
import 'project_type_catalog_service.dart';
import 'project_type_definition.dart';
import 'project_type_transition_blocker.dart';
import 'project_type_transition_plan.dart';
import 'project_type_transition_request.dart';

class ProjectTypeTransitionPolicy {
  const ProjectTypeTransitionPolicy({
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

  List<String> availableTargetProjectTypeIds(String sourceProjectTypeId) {
    // 中文注释: 这里返回的是第一阶段真正开放的转换目标，给 GUI/CLI 统一消费，避免各自猜图。
    final cleanSourceTypeId = sourceProjectTypeId.trim();
    if (!_projectTypeCatalogService.contains(cleanSourceTypeId)) {
      return const <String>[];
    }
    final sourceDefinition = _projectTypeCatalogService.definitionOf(
      cleanSourceTypeId,
    );
    if (!sourceDefinition.enabled) {
      return const <String>[];
    }
    final allowedTargets = _allowedTargetsBySourceTypeId(cleanSourceTypeId);
    return List<String>.unmodifiable(allowedTargets);
  }

  ProjectTypeTransitionPlan plan(ProjectTypeTransitionRequest request) {
    // 中文注释: 转换计划只负责算图、算阻断和算回切后的目标合同，不执行任何落盘或状态改写。
    final cleanSourceTypeId = request.sourceProjectTypeId.trim();
    final cleanTargetTypeId = request.targetProjectTypeId.trim();
    final sourceKnown = _projectTypeCatalogService.contains(cleanSourceTypeId);
    final targetKnown = _projectTypeCatalogService.contains(cleanTargetTypeId);
    final sourceDefinition = sourceKnown
        ? _projectTypeCatalogService.definitionOf(cleanSourceTypeId)
        : null;
    final targetDefinition = targetKnown
        ? _projectTypeCatalogService.definitionOf(cleanTargetTypeId)
        : null;
    final blockers = <ProjectTypeTransitionBlocker>[
      ..._buildRegistryBlockers(
        cleanSourceTypeId: cleanSourceTypeId,
        cleanTargetTypeId: cleanTargetTypeId,
        sourceKnown: sourceKnown,
        targetKnown: targetKnown,
        sourceDefinition: sourceDefinition,
        targetDefinition: targetDefinition,
      ),
    ];
    final allowedTargets = sourceDefinition == null
        ? const <String>[]
        : _allowedTargetsBySourceTypeId(sourceDefinition.id);
    final edgeAllowed =
        sourceDefinition != null &&
        targetDefinition != null &&
        allowedTargets.contains(targetDefinition.id);
    if (sourceDefinition != null &&
        targetDefinition != null &&
        sourceDefinition.enabled &&
        targetDefinition.enabled &&
        cleanSourceTypeId != cleanTargetTypeId &&
        !edgeAllowed) {
      blockers.add(
        const ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.transitionNotInFirstPhase,
          message: '当前阶段只开放 novel <-> long_novel 的项目类型转换。',
        ),
      );
    }

    final normalizedRuntimeBaselineId = targetDefinition?.id == 'long_novel'
        ? _projectRuntimeBaselineCatalogService.normalizeForProjectType(
            'long_novel',
            request.currentRuntimeBaselineId,
          )
        : '';
    if (targetDefinition?.id == 'long_novel' &&
        normalizedRuntimeBaselineId.isEmpty) {
      blockers.add(
        const ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.missingRuntimeBaseline,
          message: '转换到长篇长任务前必须先选择一个可用的运行基准。',
        ),
      );
    }
    if (cleanSourceTypeId == 'long_novel' &&
        cleanTargetTypeId == 'novel' &&
        request.hasActiveLongTaskRun) {
      blockers.add(
        const ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.activeLongTaskNotArchived,
          message: '存在活跃长任务时，必须先归档后才能回切普通小说。',
        ),
      );
    }
    if (sourceDefinition != null &&
        sourceDefinition.enabled &&
        !sourceDefinition.supportsStorageStrategy(request.storageStrategy)) {
      blockers.add(
        const ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.storageStrategyNotSupported,
          message: '源项目类型不支持当前存储策略。',
        ),
      );
    }
    if (targetDefinition != null &&
        targetDefinition.enabled &&
        !targetDefinition.supportsStorageStrategy(request.storageStrategy)) {
      blockers.add(
        const ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.storageStrategyNotSupported,
          message: '目标项目类型不支持当前存储策略。',
        ),
      );
    }
    return ProjectTypeTransitionPlan(
      request: request,
      sourceProjectTypeDefinition: sourceDefinition,
      targetProjectTypeDefinition: targetDefinition,
      availableTargetProjectTypeIds: allowedTargets,
      targetStorageStrategy: request.storageStrategy,
      targetRuntimeBaselineId: normalizedRuntimeBaselineId,
      requiresRuntimeBaselineSelection:
          targetDefinition?.id == 'long_novel' &&
          normalizedRuntimeBaselineId.isEmpty,
      blockers: blockers,
    );
  }

  List<ProjectTypeTransitionBlocker> _buildRegistryBlockers({
    required String cleanSourceTypeId,
    required String cleanTargetTypeId,
    required bool sourceKnown,
    required bool targetKnown,
    required ProjectTypeDefinition? sourceDefinition,
    required ProjectTypeDefinition? targetDefinition,
  }) {
    // 中文注释: 先把未知类型、禁用类型和自转这种基础非法组合拦住，再去计算更细的运行基准与长任务约束。
    final blockers = <ProjectTypeTransitionBlocker>[];
    if (!sourceKnown) {
      blockers.add(
        ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.unsupportedSourceProjectType,
          message: '源项目类型未登记，不能参与类型转换。',
        ),
      );
      return blockers;
    }
    if (!targetKnown) {
      blockers.add(
        ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.unsupportedTargetProjectType,
          message: '目标项目类型未登记，不能参与类型转换。',
        ),
      );
      return blockers;
    }
    if (sourceDefinition != null && !sourceDefinition.enabled) {
      blockers.add(
        ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.sourceProjectTypeDisabled,
          message: '源项目类型当前处于禁用态，不能参与转换。',
        ),
      );
    }
    if (targetDefinition != null && !targetDefinition.enabled) {
      blockers.add(
        ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.targetProjectTypeDisabled,
          message: '目标项目类型当前处于禁用态，不能参与转换。',
        ),
      );
    }
    if (cleanSourceTypeId == cleanTargetTypeId) {
      blockers.add(
        const ProjectTypeTransitionBlocker(
          code: ProjectTypeTransitionBlockerCodes.sameProjectType,
          message: '源项目类型和目标项目类型相同，不需要做转换。',
        ),
      );
    }
    return blockers;
  }

  List<String> _allowedTargetsBySourceTypeId(String sourceProjectTypeId) {
    // 中文注释: 第一阶段的转换图是静态冻结的，policy 只负责把冻结图暴露成稳定查询结果。
    switch (sourceProjectTypeId.trim()) {
      case 'novel':
        return const <String>['long_novel'];
      case 'long_novel':
        return const <String>['novel'];
      default:
        return const <String>[];
    }
  }
}
