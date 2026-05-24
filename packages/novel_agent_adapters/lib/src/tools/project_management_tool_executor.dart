import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tool_result_factory.dart';

class ProjectManagementToolExecutor {
  ProjectManagementToolExecutor({
    required ProjectToolHostPort hostPort,
    ProjectToolResultFactory? resultFactory,
    ProjectManifestCodecService? projectManifestCodecService,
    ProjectTypeCatalogService? projectTypeCatalogService,
  }) : _hostPort = hostPort,
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService();

  final ProjectToolHostPort _hostPort;
  final ProjectToolResultFactory _resultFactory;
  final ProjectManifestCodecService _projectManifestCodecService;
  final ProjectTypeCatalogService _projectTypeCatalogService;

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
      'specs/project_brief.md',
      '# ${nextManifest.title}\n\n- 项目类型：$typeLabel\n- 题材：\n- 核心设定：\n- 备注：\n',
    );
    await _hostPort.writeTextFile(
      project.rootPath,
      'README.md',
      '# ${nextManifest.title}\n\nNovelAgent Flutter 项目工作区。\n\n- 项目类型：$typeLabel\n',
    );
    return _resultFactory.success(
      '项目已重命名：${nextManifest.title}',
      data: <String, Object?>{
        'project_title': nextManifest.title,
        'changed_paths': <Object?>[
          ProjectManifestCodecService.manifestRelativePath,
          'specs/project_brief.md',
          'README.md',
        ],
      },
    );
  }

  JsonMap reorderProjectFile(JsonMap arguments) {
    // 中文注释: 当前项目树仍未引入排序元数据，因此保留旧项目同款“已识别但未执行”结果。
    return _resultFactory.notExecuted(
      '当前项目树尚未启用手动排序，未执行文件重排。',
      data: <String, Object?>{
        'relative_path': ValueReaders.stringValue(arguments['relative_path']),
        'target_index': ValueReaders.intValue(arguments['target_index'], -1),
      },
    );
  }

  JsonMap requestGatewayTool(JsonMap arguments) {
    // 中文注释: 网关工具在当前宿主仍未接通真实桌面 / 远程代理，因此继续返回 requires_gateway 合同。
    final gatewayTool = ValueReaders.stringValue(
      arguments['gateway_tool'],
      ValueReaders.stringValue(
        arguments['tool'],
        ValueReaders.stringValue(arguments['name']),
      ),
    ).trim();
    return _resultFactory.notExecuted(
      gatewayTool.isEmpty
          ? 'Gateway tool is not connected in this host.'
          : '该能力需要桌面端或远程 Gateway 承接：$gatewayTool',
      data: <String, Object?>{
        'requires_gateway': true,
        'gateway_tool': gatewayTool,
        'arguments': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(arguments['arguments']),
        ),
        'platform_policy': 'desktop_or_gateway_only',
      },
    );
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
