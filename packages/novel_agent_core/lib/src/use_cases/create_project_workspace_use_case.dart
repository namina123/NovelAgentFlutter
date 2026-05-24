import '../ports/project_repository.dart';
import '../ports/project_workspace_port.dart';
import '../customization/customization_index_document_service.dart';
import '../customization/customization_root_catalog_service.dart';
import '../project/project_descriptor.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_type_catalog_service.dart';
import '../project/project_workspace_catalog.dart';

class CreateProjectWorkspaceUseCase {
  CreateProjectWorkspaceUseCase({
    required ProjectRepository projectRepository,
    required ProjectWorkspacePort projectWorkspacePort,
    ProjectTypeCatalogService? projectTypeCatalogService,
    ProjectManifestCodecService? projectManifestCodecService,
    CustomizationRootCatalogService? customizationRootCatalogService,
    CustomizationIndexDocumentService? customizationIndexDocumentService,
  }) : _projectRepository = projectRepository,
       _projectWorkspacePort = projectWorkspacePort,
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _projectManifestCodecService =
           projectManifestCodecService ??
           ProjectManifestCodecService(
             projectTypeCatalogService:
                 projectTypeCatalogService ?? const ProjectTypeCatalogService(),
           ),
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
  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ProjectManifestCodecService _projectManifestCodecService;
  final CustomizationRootCatalogService _customizationRootCatalogService;
  final CustomizationIndexDocumentService _customizationIndexDocumentService;

  Future<ProjectDescriptor> execute({
    required String projectsRootPath,
    String title = '',
    String projectType = 'novel',
  }) async {
    // 中文注释: 项目创建用例只负责生成一套标准工作区骨架，不介入宿主端弹窗、路由和目录选择流程。
    final normalizedType = _projectTypeCatalogService.normalize(projectType);
    final normalizedTitle = title.trim().isEmpty
        ? _projectTypeCatalogService.defaultTitle(normalizedType)
        : title.trim();
    final directoryName = _safeDirectoryName(normalizedTitle);
    final rootPath = await _uniqueProjectRootPath(
      projectsRootPath,
      directoryName,
    );

    await _writeScaffold(rootPath, normalizedTitle, normalizedType);
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
  ) async {
    // 中文注释: 工作区骨架统一从目录目录表生成，保证 GUI、CLI 和工具调度看到的是同一套项目结构。
    final manifest = _projectManifestCodecService.create(
      title: title,
      projectType: projectType,
    );
    await _projectWorkspacePort.writeTextFile(
      rootPath,
      ProjectManifestCodecService.manifestRelativePath,
      _projectManifestCodecService.encode(manifest),
    );
    await _projectWorkspacePort.writeTextFile(
      rootPath,
      'specs/project_brief.md',
      '# $title\n\n- 项目类型：$projectType\n- 题材：\n- 核心卖点：\n- 创作边界：\n- 当前阶段：起步\n',
    );
    for (final descriptor in ProjectWorkspaceCatalog.userWorkspaceDirs) {
      await _projectWorkspacePort.writeTextFile(
        rootPath,
        '${descriptor.path}README.md',
        '# ${descriptor.name}\n\n${descriptor.purpose}\n',
      );
    }
    for (final descriptor in ProjectWorkspaceCatalog.advancedWorkspaceDirs) {
      await _projectWorkspacePort.writeTextFile(
        rootPath,
        '${descriptor.path}README.md',
        '# ${descriptor.name}\n',
      );
    }
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
    await _projectWorkspacePort.writeTextFile(
      rootPath,
      'README.md',
      '# $title\n\nNovelAgent Flutter 项目工作区。\n\n- 项目类型：$projectType\n',
    );
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
