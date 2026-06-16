import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_tree_order_service.dart';
import 'project_gateway_tool_executor.dart';
import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectManagementToolExecutor {
  ProjectManagementToolExecutor({
    required ProjectToolHostPort hostPort,
    ProjectToolResultFactory? resultFactory,
    ProjectManifestCodecService? projectManifestCodecService,
    ProjectTypeCatalogService? projectTypeCatalogService,
    ProjectTreeOrderService? treeOrderService,
    ProjectGatewayToolExecutor? gatewayToolExecutor,
    ProjectToolPathPolicy? pathPolicy,
  }) : _hostPort = hostPort,
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _treeOrderService = treeOrderService ?? ProjectTreeOrderService(),
       _gatewayToolExecutor =
           gatewayToolExecutor ?? ProjectGatewayToolExecutor(),
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolHostPort _hostPort;
  final ProjectToolResultFactory _resultFactory;
  final ProjectManifestCodecService _projectManifestCodecService;
  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ProjectTreeOrderService _treeOrderService;
  final ProjectGatewayToolExecutor _gatewayToolExecutor;
  final ProjectToolPathPolicy _pathPolicy;

  Future<JsonMap> renameProject(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 项目重命名只改显示标题和简介文档，不移动磁盘目录，确保当前工作区和会话路径保持稳定。
    final newName = ValueReaders.stringValue(
      arguments['new_name'],
      ValueReaders.stringValue(
        arguments['name'],
        ValueReaders.stringValue(arguments['title']),
      ),
    ).trim();
    if (newName.isEmpty) {
      return _resultFactory.error(
        'new_name is required.',
        data: <String, Object?>{'project_title': project.name},
      );
    }
    final manifestSource =
        await _hostPort.readTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        ) ??
        '';
    final currentManifest = _projectManifestCodecService.parse(
      manifestSource,
      fallbackTitle: project.name,
      fallbackProjectType: project.projectType,
    );
    final nextManifest = _projectManifestCodecService.create(
      title: newName,
      projectType: currentManifest.projectType,
    );
    await _hostPort.writeTextFile(
      project.rootPath,
      ProjectManifestCodecService.manifestRelativePath,
      _projectManifestCodecService.encode(nextManifest),
    );
    final typeLabel = _projectTypeLabel(nextManifest.projectType);
    await _hostPort.writeTextFile(
      project.rootPath,
      ProjectSupportDocumentCatalog.projectOverviewRelativePath,
      '# 项目概览\n\n'
      '> 这是系统维护的快速概览，不是正式故事前提或长期创作宪章。\n\n'
      '- 项目标题：${nextManifest.title}\n'
      '- 项目类型：$typeLabel\n'
      '- 题材：\n'
      '- 当前已知核心设定：\n'
      '- 备注：\n',
    );
    return _resultFactory.success(
      '项目已重命名：${nextManifest.title}',
      data: <String, Object?>{
        'project_title': nextManifest.title,
        'changed_paths': <Object?>[
          ProjectManifestCodecService.manifestRelativePath,
          ProjectSupportDocumentCatalog.projectOverviewRelativePath,
        ],
      },
    );
  }

  Future<JsonMap> reorderProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 文件重排只持久化同级顺序元数据，不改真实目录结构，从而让资源树和 CLI 共享同一排序结果。
    final relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (!_pathPolicy.isSafeScopePath(relativePath)) {
      return _resultFactory.error(
        'Unsafe relative_path.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final targetIndex = ValueReaders.intValue(arguments['target_index'], -1);
    if (targetIndex < 0) {
      return _resultFactory.error(
        'target_index must be >= 0.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    try {
      final entries = await _hostPort.listEntries(project.rootPath);
      final reorderResult = await _treeOrderService.reorderEntry(
        rootPath: project.rootPath,
        relativePath: relativePath,
        targetIndex: targetIndex,
        existingEntries: entries,
      );
      return _resultFactory.success(
        '已重排项目条目：$relativePath',
        data: <String, Object?>{
          'relative_path': relativePath,
          'target_index': reorderResult.normalizedIndex,
          'ordered_siblings': reorderResult.orderedSiblingNames,
          'parent_path': reorderResult.parentPath,
          'changed_paths': <Object?>[relativePath, reorderResult.metadataPath],
        },
      );
    } catch (error) {
      return _resultFactory.error(
        '项目条目重排失败：$error',
        data: <String, Object?>{
          'relative_path': relativePath,
          'target_index': targetIndex,
        },
      );
    }
  }

  Future<JsonMap> requestGatewayTool(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 桌面 / CLI 宿主的高级能力统一下沉到专门网关执行器，避免管理执行器掺杂联网和命令细节。
    return _gatewayToolExecutor.execute(project, arguments);
  }

  String _projectTypeLabel(String projectType) {
    // 中文注释: 项目简介文档里的类型标签与共享创建 / 更新用例保持一致，避免这里出现第三套文案。
    final normalized = _projectTypeCatalogService.normalize(projectType);
    switch (normalized) {
      case 'long_task':
        return '长任务';
      case 'novel':
      default:
        return '小说';
    }
  }
}
