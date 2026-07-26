import '../ports/project_repository.dart';
import '../ports/project_content_repository.dart';
import '../ports/project_workspace_port.dart';
import '../customization/customization_index_document_service.dart';
import '../customization/customization_root_catalog_service.dart';
import '../project/project_directory_layout_service.dart';
import '../project/project_descriptor.dart';
import '../project/project_create_request.dart';
import '../project/project_creation_next_step.dart';
import '../project/project_creation_plan.dart';
import '../project/knowledge_base_branch_catalog_service.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_manifest_corruption_exception.dart';
import '../project/project_readable_projection_service.dart';
import '../project/project_runtime_baseline_catalog_service.dart';
import '../project/project_runtime_profile_document_service.dart';
import '../project/project_storage_strategy.dart';
import '../project/project_type_catalog_service.dart';
import '../project/project_type_definition.dart';

class CreateProjectWorkspaceUseCase {
  CreateProjectWorkspaceUseCase({
    required ProjectRepository projectRepository,
    required ProjectWorkspacePort projectWorkspacePort,
    required ProjectContentRepository projectContentRepository,
    required ProjectReadableProjectionService projectReadableProjectionService,
    ProjectTypeCatalogService? projectTypeCatalogService,
    ProjectRuntimeBaselineCatalogService? projectRuntimeBaselineCatalogService,
    ProjectDirectoryLayoutService? projectDirectoryLayoutService,
    ProjectManifestCodecService? projectManifestCodecService,
    ProjectRuntimeProfileDocumentService? projectRuntimeProfileDocumentService,
    CustomizationRootCatalogService? customizationRootCatalogService,
    CustomizationIndexDocumentService? customizationIndexDocumentService,
  }) : _projectRepository = projectRepository,
       _projectWorkspacePort = projectWorkspacePort,
       _projectContentRepository = projectContentRepository,
       _projectReadableProjectionService = projectReadableProjectionService,
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _projectRuntimeBaselineCatalogService =
           projectRuntimeBaselineCatalogService ??
           const ProjectRuntimeBaselineCatalogService(),
       _projectDirectoryLayoutService =
           projectDirectoryLayoutService ??
           const ProjectDirectoryLayoutService(),
       _projectManifestCodecService =
           projectManifestCodecService ??
           ProjectManifestCodecService(
             projectTypeCatalogService:
                 projectTypeCatalogService ?? const ProjectTypeCatalogService(),
           ),
       _projectRuntimeProfileDocumentService =
           projectRuntimeProfileDocumentService ??
           ProjectRuntimeProfileDocumentService(),
       _customizationRootCatalogService =
           customizationRootCatalogService ??
           const CustomizationRootCatalogService(),
       _customizationIndexDocumentService =
           customizationIndexDocumentService ??
           CustomizationIndexDocumentService(
             rootCatalogService:
                 customizationRootCatalogService ??
                 const CustomizationRootCatalogService(),
           );

  final ProjectRepository _projectRepository;
  final ProjectWorkspacePort _projectWorkspacePort;
  final ProjectContentRepository _projectContentRepository;
  final ProjectReadableProjectionService _projectReadableProjectionService;
  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ProjectRuntimeBaselineCatalogService
  _projectRuntimeBaselineCatalogService;
  final ProjectDirectoryLayoutService _projectDirectoryLayoutService;
  final ProjectManifestCodecService _projectManifestCodecService;
  final ProjectRuntimeProfileDocumentService
  _projectRuntimeProfileDocumentService;
  final CustomizationRootCatalogService _customizationRootCatalogService;
  final CustomizationIndexDocumentService _customizationIndexDocumentService;

  ProjectCreationPlan prepare(ProjectCreateRequest request) {
    // 中文注释: 创建前准备阶段只做领域归一化与下一步判断，不直接产生文件系统副作用。
    final requestedProjectType = request.projectTypeId.trim();
    // 中文注释: 打开旧 manifest 可以宽容地回退到普通小说，但新建项目不能把拼写错误的
    // 类型静默创建成另一个项目。空值仍保留为历史默认的普通小说入口。
    if (requestedProjectType.isNotEmpty &&
        !_projectTypeCatalogService.contains(requestedProjectType)) {
      throw StateError('项目类型 $requestedProjectType 未登记，不能创建新项目。');
    }
    final normalizedProjectType = requestedProjectType.isEmpty
        ? 'novel'
        : requestedProjectType;
    final projectTypeDefinition = _projectTypeCatalogService.definitionOf(
      normalizedProjectType,
    );
    if (!projectTypeDefinition.enabled) {
      // 中文注释: 禁用态项目类型可以继续被旧项目识别和打开，但任何创建入口都不能绕过目录的启用状态。
      throw StateError('项目类型 ${projectTypeDefinition.name} 当前处于禁用态，不能创建新项目。');
    }
    final normalizedTitle = request.title.trim().isEmpty
        ? projectTypeDefinition.defaultTitle
        : request.title.trim();
    final normalizedStorageStrategy = _normalizeStorageStrategy(
      projectTypeDefinition,
      request.storageStrategy,
    );
    final normalizedProjectBranchId = const KnowledgeBaseBranchCatalogService()
        .normalize(normalizedProjectType, request.projectBranchId);
    final runtimeBaselineOptions = _projectRuntimeBaselineCatalogService
        .definitionsForProjectType(normalizedProjectType);
    final normalizedRuntimeBaselineId = _projectRuntimeBaselineCatalogService
        .normalizeForProjectType(
          normalizedProjectType,
          request.runtimeBaselineId,
        );
    final normalizedRequest = ProjectCreateRequest(
      title: normalizedTitle,
      projectTypeId: normalizedProjectType,
      storageStrategy: normalizedStorageStrategy,
      projectBranchId: normalizedProjectBranchId,
      runtimeBaselineId: normalizedRuntimeBaselineId,
    );
    final nextStep =
        projectTypeDefinition.requiresRuntimeBaselineSelection &&
            normalizedRuntimeBaselineId.isEmpty
        ? ProjectCreationNextStep.selectRuntimeBaseline
        : ProjectCreationNextStep.readyToCreate;
    return ProjectCreationPlan(
      request: normalizedRequest,
      projectTypeDefinition: projectTypeDefinition,
      runtimeBaselineOptions: runtimeBaselineOptions,
      nextStep: nextStep,
    );
  }

  Future<ProjectDescriptor> execute({
    required String projectsRootPath,
    String title = '',
    String projectType = 'novel',
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    String projectBranchId = '',
    String runtimeBaselineId = '',
  }) async {
    // 中文注释: 直接执行入口保留给现有探针和脚本，但仍会严格走三段式准备结果，不再绕开运行基准判断。
    final plan = prepare(
      ProjectCreateRequest(
        title: title,
        projectTypeId: projectType,
        storageStrategy: storageStrategy,
        projectBranchId: projectBranchId,
        runtimeBaselineId: runtimeBaselineId,
      ),
    );
    return executePrepared(projectsRootPath: projectsRootPath, plan: plan);
  }

  Future<ProjectDescriptor> executePrepared({
    required String projectsRootPath,
    required ProjectCreationPlan plan,
  }) async {
    // 中文注释: ProjectCreationPlan 是公开数据对象，不能把调用方传入的 nextStep 当成
    // 授权凭据。重新准备一次可阻止伪造计划绕过禁用类型、存储策略或长篇运行基准校验。
    final validatedPlan = prepare(plan.request);
    if (!validatedPlan.canCreate) {
      throw StateError(
        '项目类型 ${validatedPlan.projectTypeDefinition.name} 还需要先选择长任务运行基准。',
      );
    }
    final normalizedTitle = validatedPlan.request.title.trim();
    final directoryName = _safeDirectoryName(normalizedTitle);
    final rootPath = await _uniqueProjectRootPath(
      projectsRootPath,
      directoryName,
    );

    await _writeScaffold(
      rootPath,
      normalizedTitle,
      validatedPlan.request.projectTypeId,
      validatedPlan.request.storageStrategy,
      validatedPlan.request.projectBranchId,
      validatedPlan.request.runtimeBaselineId,
    );
    final project = await _projectRepository.openByPath(rootPath);
    if (project == null) {
      throw StateError('项目创建后无法重新打开：$rootPath');
    }
    return project;
  }

  Future<void> _writeScaffold(
    String rootPath,
    String title,
    String projectType,
    ProjectStorageStrategy storageStrategy,
    String projectBranchId,
    String runtimeBaselineId,
  ) async {
    // 中文注释: 项目骨架先统一走“目录布局 + 内容仓储 + 可读投影”三段式，后续换目录结构时只改集中合同。
    final layout = _projectDirectoryLayoutService.layoutFor(storageStrategy);
    final manifest = _projectManifestCodecService.create(
      title: title,
      projectType: projectType,
      storageStrategy: storageStrategy,
      projectBranchId: projectBranchId,
      runtimeBaselineId: runtimeBaselineId,
    );
    await _projectContentRepository.initializeProjectContent(
      rootPath: rootPath,
      manifest: manifest,
      layout: layout,
    );
    await _projectWorkspacePort.writeTextFile(
      rootPath,
      ProjectManifestCodecService.manifestRelativePath,
      _projectManifestCodecService.encode(manifest),
    );
    if (manifest.runtimeBaselineId.trim().isNotEmpty) {
      final runtimeProfile = _projectRuntimeProfileDocumentService.buildProfile(
        projectType: manifest.projectType,
        runtimeBaselineId: manifest.runtimeBaselineId,
      );
      await _projectWorkspacePort.writeTextFile(
        rootPath,
        ProjectRuntimeProfileDocumentService.profileRelativePath,
        _projectRuntimeProfileDocumentService.encode(runtimeProfile),
      );
    }
    await _projectReadableProjectionService.ensureReadableProjection(
      rootPath: rootPath,
      manifest: manifest,
      layout: layout,
    );
    for (final descriptor in _customizationRootCatalogService.roots()) {
      final root = descriptor['root'] ?? '';
      if (root.trim().isEmpty) {
        continue;
      }
      await _projectWorkspacePort.writeTextFile(
        rootPath,
        '$root/index.json',
        _customizationIndexDocumentService.buildIndexDocument(root),
      );
    }
  }

  ProjectStorageStrategy _normalizeStorageStrategy(
    ProjectTypeDefinition definition,
    ProjectStorageStrategy storageStrategy,
  ) {
    // 中文注释: 存储策略归一化统一跟随项目类型支持范围走，后续某些项目类型若限制策略，只改目录定义即可。
    for (final supportedStrategy in definition.supportedStorageStrategies) {
      if (supportedStrategy == storageStrategy) {
        return supportedStrategy;
      }
    }
    return definition.supportedStorageStrategies.isEmpty
        ? ProjectStorageStrategy.markdownProjectStore
        : definition.supportedStorageStrategies.first;
  }

  Future<String> _uniqueProjectRootPath(
    String projectsRootPath,
    String directoryName,
  ) async {
    // 中文注释: 新项目目录名在这里统一做去重，避免 UI 层自己猜测文件系统冲突策略。
    var index = 1;
    var candidateName = directoryName;
    while (await _isProjectRootPathOccupied(
      _joinPath(projectsRootPath, candidateName),
    )) {
      index += 1;
      candidateName = '${directoryName}_$index';
    }
    return _joinPath(projectsRootPath, candidateName);
  }

  Future<bool> _isProjectRootPathOccupied(String rootPath) async {
    // Project recognition is not an existence check: a non-project directory
    // can contain user data and must never receive a new scaffold by title.
    try {
      if (await _projectRepository.openByPath(rootPath) != null) {
        return true;
      }
    } on ProjectManifestCorruptionException {
      // Keep a corrupt project intact for the recovery flow instead of
      // overwriting it merely because a new project shares its title.
      return true;
    }
    final directEntries = await _projectWorkspacePort.listEntries(
      rootPath,
      recursive: false,
    );
    return directEntries.isNotEmpty;
  }

  String _joinPath(String rootPath, String child) {
    // 中文注释: 轻量路径拼接留在这里，避免为了简单项目骨架创建把平台 IO 细节带进核心接口层。
    final normalizedRoot = rootPath
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    final normalizedChild = child
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^/+'), '');
    return '$normalizedRoot/$normalizedChild';
  }

  String _safeDirectoryName(String value) {
    // 中文注释: 目录名清洗规则保持宽松但可跨平台，尽量保留中文标题同时滤掉危险字符。
    var result = value.trim();
    result = result.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    result = result.replaceAll(RegExp(r'\s+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? '新建小说项目' : result;
  }
}
