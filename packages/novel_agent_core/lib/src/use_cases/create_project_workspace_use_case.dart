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
import '../project/project_manifest_codec_service.dart';
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
    final normalizedProjectType = _projectTypeCatalogService.normalize(
      request.projectTypeId,
    );
    final projectTypeDefinition = _projectTypeCatalogService.definitionOf(
      normalizedProjectType,
    );
    final normalizedTitle = request.title.trim().isEmpty
        ? projectTypeDefinition.defaultTitle
        : request.title.trim();
    final normalizedStorageStrategy = _normalizeStorageStrategy(
      projectTypeDefinition,
      request.storageStrategy,
    );
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
    String runtimeBaselineId = '',
  }) async {
    // 中文注释: 直接执行入口保留给现有探针和脚本，但仍会严格走三段式准备结果，不再绕开运行基准判断。
    final plan = prepare(
      ProjectCreateRequest(
        title: title,
        projectTypeId: projectType,
        storageStrategy: storageStrategy,
        runtimeBaselineId: runtimeBaselineId,
      ),
    );
    return executePrepared(projectsRootPath: projectsRootPath, plan: plan);
  }

  Future<ProjectDescriptor> executePrepared({
    required String projectsRootPath,
    required ProjectCreationPlan plan,
  }) async {
    // 中文注释: 真正落盘前必须先确认三段式创建计划已收束到 readyToCreate，避免长任务项目跳过运行基准选择。
    if (!plan.canCreate) {
      throw StateError(
        '项目类型 ${plan.projectTypeDefinition.name} 还需要先选择长任务运行基准。',
      );
    }
    final normalizedTitle = plan.request.title.trim();
    final directoryName = _safeDirectoryName(normalizedTitle);
    final rootPath = await _uniqueProjectRootPath(
      projectsRootPath,
      directoryName,
    );

    await _writeScaffold(
      rootPath,
      normalizedTitle,
      plan.request.projectTypeId,
      plan.request.storageStrategy,
      plan.request.runtimeBaselineId,
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
    String runtimeBaselineId,
  ) async {
    // 中文注释: 项目骨架先统一走“目录布局 + 内容仓储 + 可读投影”三段式，后续换目录结构时只改集中合同。
    final layout = _projectDirectoryLayoutService.layoutFor(storageStrategy);
    final manifest = _projectManifestCodecService.create(
      title: title,
      projectType: projectType,
      storageStrategy: storageStrategy,
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
    while (await _projectRepository.openByPath(
          _joinPath(projectsRootPath, candidateName),
        ) !=
        null) {
      index += 1;
      candidateName = '${directoryName}_$index';
    }
    return _joinPath(projectsRootPath, candidateName);
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
