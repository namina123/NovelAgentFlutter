import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_entry_view_data.dart';
import '../../presentation/models/project_creation_phase.dart';
import '../../presentation/models/project_deconstruction_followup_option_view_data.dart';
import '../../presentation/models/project_launcher_view_data.dart';
import '../../presentation/models/project_runtime_baseline_option_view_data.dart';
import '../../presentation/models/project_storage_strategy_option_view_data.dart';
import '../../presentation/models/project_type_option_view_data.dart';
import 'project_creation_phase_resolver_service.dart';

class ProjectLauncherViewDataService {
  ProjectLauncherViewDataService({
    ProjectTypeCatalogService? projectTypeCatalogService,
    ProjectCreationPhaseResolverService? projectCreationPhaseResolverService,
    BookDeconstructionProjectSetupResolverService?
    bookDeconstructionProjectSetupResolverService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _projectCreationPhaseResolverService =
           projectCreationPhaseResolverService ??
           const ProjectCreationPhaseResolverService(),
       _bookDeconstructionProjectSetupResolverService =
           bookDeconstructionProjectSetupResolverService ??
           const BookDeconstructionProjectSetupResolverService();

  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ProjectCreationPhaseResolverService
  _projectCreationPhaseResolverService;
  final BookDeconstructionProjectSetupResolverService
  _bookDeconstructionProjectSetupResolverService;

  ProjectLauncherViewData build({
    required ProjectLauncherMode mode,
    required String projectsRootPath,
    required List<JsonMap> projects,
    String status = '',
    String draftTitle = '',
    String selectedProjectTypeId = 'novel',
    ProjectStorageStrategy selectedStorageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    ProjectCreationPhase creationPhase = ProjectCreationPhase.projectType,
    String selectedBookDeconstructionFollowupRouteId =
        BookDeconstructionProjectSetupResolverService.continuationRouteId,
    List<ProjectRuntimeBaselineDefinition> runtimeBaselineOptions =
        const <ProjectRuntimeBaselineDefinition>[],
    String selectedRuntimeBaselineId = '',
    ProjectContinuityInputProfile continuityInput =
        const ProjectContinuityInputProfile(),
    bool canDismiss = true,
    bool allowOpenExisting = true,
  }) {
    // 中文注释: 项目启动面板的数据投影统一收口在这里，避免控制器直接理解核心层返回的动态字典。
    final normalizedProjectTypeId = _projectTypeCatalogService.normalize(
      selectedProjectTypeId,
    );
    final selectedProjectType = _projectTypeCatalogService.definitionOf(
      normalizedProjectTypeId,
    );
    final options = _projectTypeCatalogService
        .enabledDefinitions()
        .map(_projectTypeOptionFrom)
        .toList(growable: false);
    final storageStrategyOptions = selectedProjectType
        .supportedStorageStrategies
        .map((strategy) => _storageOptionFrom(selectedProjectType, strategy))
        .toList(growable: false);
    return ProjectLauncherViewData(
      mode: mode,
      title: _titleOf(
        mode: mode,
        creationPhase: creationPhase,
        projectTypeId: normalizedProjectTypeId,
        requiresRuntimeBaselineSelection:
            selectedProjectType.requiresRuntimeBaselineSelection,
      ),
      description: _descriptionOf(
        mode: mode,
        creationPhase: creationPhase,
        allowOpenExisting: allowOpenExisting,
        projectTypeId: normalizedProjectTypeId,
      ),
      projectsRootPath: projectsRootPath,
      entries: projects
          .map(
            (project) => ProjectEntryViewData(
              id: project['id']?.toString() ?? '',
              title: project['title']?.toString() ?? '未命名项目',
              path: project['path']?.toString() ?? '',
            ),
          )
          .where((entry) => entry.path.trim().isNotEmpty)
          .toList(growable: false),
      status: status,
      draftTitle: draftTitle.trim().isEmpty
          ? _projectTypeDefaultTitleOf(selectedProjectType)
          : draftTitle,
      projectTypeOptions: options,
      selectedProjectTypeId: normalizedProjectTypeId,
      storageStrategyOptions: storageStrategyOptions,
      selectedStorageStrategyId: _resolveStorageStrategyId(
        selectedProjectType,
        selectedStorageStrategy,
      ),
      creationPhase: creationPhase,
      bookDeconstructionFollowupOptions: _bookDeconstructionFollowupOptionsOf(
        selectedProjectType.id,
      ),
      selectedBookDeconstructionFollowupRouteId:
          _bookDeconstructionProjectSetupResolverService.normalizeRouteId(
            selectedBookDeconstructionFollowupRouteId,
          ),
      runtimeBaselineOptions: runtimeBaselineOptions
          .map(
            (definition) => ProjectRuntimeBaselineOptionViewData(
              id: definition.id,
              title: definition.title,
              description: definition.description,
            ),
          )
          .toList(growable: false),
      selectedRuntimeBaselineId: selectedRuntimeBaselineId.trim(),
      selectedProjectTypeRequiresRuntimeBaseline:
          selectedProjectType.requiresRuntimeBaselineSelection,
      continuityInput: continuityInput,
      canDismiss: canDismiss,
      allowOpenExisting: allowOpenExisting,
    );
  }

  String _titleOf({
    required ProjectLauncherMode mode,
    required ProjectCreationPhase creationPhase,
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
  }) {
    switch (mode) {
      case ProjectLauncherMode.guard:
        return '先选择一个项目入口';
      case ProjectLauncherMode.create:
        final stepIndex =
            _projectCreationPhaseResolverService
                .phasesFor(
                  projectTypeId: projectTypeId,
                  requiresRuntimeBaselineSelection:
                      requiresRuntimeBaselineSelection,
                )
                .indexOf(creationPhase) +
            1;
        switch (creationPhase) {
          case ProjectCreationPhase.projectType:
            return '第$stepIndex步：选择项目类型';
          case ProjectCreationPhase.storageStrategy:
            return '第$stepIndex步：选择主存储策略';
          case ProjectCreationPhase.bookDeconstructionFollowup:
            return '第$stepIndex步：选择拆书承接路线';
          case ProjectCreationPhase.runtimeBaseline:
            return '第$stepIndex步：选择长任务运行基准';
        }
    }
  }

  String _descriptionOf({
    required ProjectLauncherMode mode,
    required ProjectCreationPhase creationPhase,
    required bool allowOpenExisting,
    required String projectTypeId,
  }) {
    switch (mode) {
      case ProjectLauncherMode.guard:
        return allowOpenExisting
            ? '当前没有有效项目。先创建一个新项目，或从本机选择一个已有项目根目录。'
            : '当前没有有效项目。请先在应用项目目录中创建第一个项目。';
      case ProjectLauncherMode.create:
        switch (creationPhase) {
          case ProjectCreationPhase.projectType:
            return '先决定这个项目按哪类创作策略起步，项目名会随默认模板联动。';
          case ProjectCreationPhase.storageStrategy:
            return projectTypeId == 'book_deconstruction'
                ? '确认拆书承接路线后，再确定这个项目的主存储策略，后续拆书资产与派生配置都会按这里落定。'
                : '接着确定正文主存储策略，后续文件树与数据组织都会按这里落定。';
          case ProjectCreationPhase.bookDeconstructionFollowup:
            return '拆书项目先确定后续承接路线，决定默认偏向续写还是同人派生。';
          case ProjectCreationPhase.runtimeBaseline:
            return '最后为需要长任务运行基准的项目补齐运行方式，再正式创建项目。';
        }
    }
  }

  List<ProjectDeconstructionFollowupOptionViewData>
  _bookDeconstructionFollowupOptionsOf(String projectTypeId) {
    if (!_projectCreationPhaseResolverService.usesBookDeconstructionFollowup(
      projectTypeId,
    )) {
      return const <ProjectDeconstructionFollowupOptionViewData>[];
    }
    return const <ProjectDeconstructionFollowupOptionViewData>[
      ProjectDeconstructionFollowupOptionViewData(
        id: BookDeconstructionProjectSetupResolverService.continuationRouteId,
        title: '续写承接',
        description: '默认把原作当作同一条正文连续体的前段，后续拆书预演和派生更偏向续写承接。',
      ),
      ProjectDeconstructionFollowupOptionViewData(
        id: BookDeconstructionProjectSetupResolverService.fanficRouteId,
        title: '同人派生',
        description: '默认把原作保留在来源与参考层，后续拆书预演和派生更偏向同人创作与世界观借力。',
      ),
    ];
  }

  ProjectTypeOptionViewData _projectTypeOptionFrom(
    ProjectTypeDefinition definition,
  ) {
    // 中文注释: 资料知识库在 GUI 层需要更明确的治理语义，避免被默认写作壳文案带偏。
    final displayTitle = switch (definition.id) {
      'knowledge_base' => '资料知识库 / 参考资产治理',
      _ => definition.name,
    };
    final displayDescription = switch (definition.id) {
      'knowledge_base' =>
        '适合导入、整理、审核和挂载参考资产，以 SQLite 作为主事实源，Markdown 仅保留投影与导出层。',
      _ => definition.description,
    };
    return ProjectTypeOptionViewData(
      id: definition.id,
      title: displayTitle,
      description: displayDescription,
      defaultTitle: _projectTypeDefaultTitleOf(definition),
      requiresRuntimeBaselineSelection:
          definition.requiresRuntimeBaselineSelection,
    );
  }

  String _projectTypeDefaultTitleOf(ProjectTypeDefinition definition) {
    // 中文注释: 默认标题也跟随资料知识库的治理语义单独收束，避免继续沿用普通知识库的旧称呼。
    return switch (definition.id) {
      'knowledge_base' => '未命名资料知识库',
      _ => definition.defaultTitle,
    };
  }

  ProjectStorageStrategyOptionViewData _storageOptionFrom(
    ProjectTypeDefinition projectType,
    ProjectStorageStrategy strategy,
  ) {
    switch (strategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return const ProjectStorageStrategyOptionViewData(
          id: 'markdown_project_store',
          title: 'Markdown 项目',
          description: '主内容直接落到 Markdown / 普通文件，适合以文件树为主的创作方式。',
        );
      case ProjectStorageStrategy.sqliteProjectStore:
        if (projectType.id == 'knowledge_base') {
          return const ProjectStorageStrategyOptionViewData(
            id: 'sqlite_project_store',
            title: 'SQLite 参考资产库',
            description:
                '主内容以结构化 SQLite 承载，便于导入、整理、审核和挂载参考资产，Markdown 仅保留投影或导出层。',
          );
        }
        return const ProjectStorageStrategyOptionViewData(
          id: 'sqlite_project_store',
          title: 'SQLite 项目',
          description: '主内容以结构化存储为主，Markdown 作为投影或导出层，适合后续结构化扩展。',
        );
    }
  }

  String _resolveStorageStrategyId(
    ProjectTypeDefinition definition,
    ProjectStorageStrategy selectedStorageStrategy,
  ) {
    // 中文注释: 视图层只保留当前项目类型支持的存储策略，避免显示一个实际无法提交的选项。
    for (final strategy in definition.supportedStorageStrategies) {
      if (strategy == selectedStorageStrategy) {
        return strategy.id;
      }
    }
    return definition.supportedStorageStrategies.isEmpty
        ? ProjectStorageStrategy.markdownProjectStore.id
        : definition.supportedStorageStrategies.first.id;
  }
}
