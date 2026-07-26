import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_structured_content_bridge_service.dart';
import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectFileEditToolExecutor {
  ProjectFileEditToolExecutor({
    required ProjectToolHostPort hostPort,
    TextEditPlanService? textEditPlanService,
    LineEditPlanService? lineEditPlanService,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _hostPort = hostPort,
       _textEditPlanService = textEditPlanService ?? TextEditPlanService(),
       _lineEditPlanService = lineEditPlanService ?? LineEditPlanService(),
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _hostPort;
  final TextEditPlanService _textEditPlanService;
  final LineEditPlanService _lineEditPlanService;
  final ProjectToolPathPolicy _pathPolicy;
  final ProjectToolResultFactory _resultFactory;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<JsonMap> editProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 修改已有文本文件时，计划计算在核心，宿主只负责安全读取和写回。
    final relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (!_pathPolicy.isSafeFilePath(relativePath)) {
      return _resultFactory.notExecuted(
        'edit_project_file 的 relative_path 无效。请使用项目内英文 relative_path。',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final original =
        await _structuredContentBridgeService.readProjectedBodyText(
          project,
          relativePath,
        ) ??
        await _hostPort.readTextFile(project.rootPath, relativePath);
    if (original == null) {
      return _resultFactory.notExecuted(
        'edit_project_file 未找到目标文件。请先调用 list_project_files 确认英文 relative_path。',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final plan = _textEditPlanService.applyTextEdit(original, arguments);
    if (!ValueReaders.boolValue(plan['ok'])) {
      return _resultFactory.error(
        ValueReaders.stringValue(plan['error'], '项目文件修改失败。'),
        data: <String, Object?>{...plan, 'relative_path': relativePath},
      );
    }
    if (ValueReaders.boolValue(plan['changed'])) {
      await _persistStructuredProjection(
        project: project,
        relativePath: relativePath,
        content: ValueReaders.stringValue(plan['content'], original),
      );
      await _hostPort.writeTextFile(
        project.rootPath,
        relativePath,
        ValueReaders.stringValue(plan['content'], original),
      );
    }
    return _resultFactory.success(
      '已修改项目文件：$relativePath',
      data: <String, Object?>{
        ...plan,
        'relative_path': relativePath,
        'content_type': _pathPolicy.inferContentTypeFromPath(relativePath),
        'changed_paths': ValueReaders.boolValue(plan['changed'])
            ? <Object?>[relativePath]
            : const <Object?>[],
      }..remove('content'),
    );
  }

  Future<JsonMap> manipulateProjectFileLines(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 行级工具支持跨文件 copy/cut，但仍严格限制在项目目录内的相对路径。
    final source = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    final operation = ValueReaders.stringValue(
      arguments['operation'],
    ).trim().toLowerCase();
    if (!_pathPolicy.isSafeFilePath(source)) {
      return _resultFactory.notExecuted(
        'manipulate_project_file_lines 的 relative_path 无效。请使用项目内英文 relative_path。',
        data: <String, Object?>{'relative_path': source},
      );
    }
    final sourceContent =
        await _structuredContentBridgeService.readProjectedBodyText(
          project,
          source,
        ) ??
        await _hostPort.readTextFile(project.rootPath, source);
    if (sourceContent == null) {
      return _resultFactory.notExecuted(
        'manipulate_project_file_lines 未找到源文件。请先调用 list_project_files 确认英文 relative_path。',
        data: <String, Object?>{'relative_path': source},
      );
    }
    final target = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['target_relative_path']),
    );
    var targetContent = '';
    if ((operation == 'copy' || operation == 'cut') && target.isNotEmpty) {
      if (!_pathPolicy.isSafeFilePath(target)) {
        return _resultFactory.notExecuted(
          'manipulate_project_file_lines 的 target_relative_path 无效。请使用项目内英文 relative_path。',
          data: <String, Object?>{'target_relative_path': target},
        );
      }
      targetContent =
          await _structuredContentBridgeService.readProjectedBodyText(
            project,
            target,
          ) ??
          await _hostPort.readTextFile(project.rootPath, target) ??
          '';
    }
    final plan = _lineEditPlanService.applyLineEdit(
      sourceContent,
      <String, Object?>{
        ...arguments,
        if (target.isNotEmpty) 'target_content': targetContent,
      },
    );
    if (!ValueReaders.boolValue(plan['ok'])) {
      return _resultFactory.error(
        ValueReaders.stringValue(plan['error'], '行级处理失败。'),
        data: <String, Object?>{...plan, 'relative_path': source},
      );
    }
    final changedPaths = <Object?>[];
    if (target.isNotEmpty && ValueReaders.boolValue(plan['target_changed'])) {
      await _persistStructuredProjection(
        project: project,
        relativePath: target,
        content: ValueReaders.stringValue(plan['target_content']),
      );
      await _hostPort.writeTextFile(
        project.rootPath,
        target,
        ValueReaders.stringValue(plan['target_content']),
      );
      changedPaths.add(target);
    }
    if (ValueReaders.boolValue(plan['source_changed'])) {
      await _persistStructuredProjection(
        project: project,
        relativePath: source,
        content: ValueReaders.stringValue(plan['content'], sourceContent),
      );
      await _hostPort.writeTextFile(
        project.rootPath,
        source,
        ValueReaders.stringValue(plan['content'], sourceContent),
      );
      changedPaths.add(source);
    }
    return _resultFactory.success(
      '已完成行级处理：$operation',
      data:
          <String, Object?>{
              ...plan,
              'relative_path': source,
              'target_relative_path': target,
              'changed_paths': changedPaths,
            }
            ..remove('content')
            ..remove('target_content'),
    );
  }

  Future<void> _persistStructuredProjection({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
  }) {
    return _structuredContentBridgeService.persistWorkspaceProjectionDocument(
      project: project,
      documentPath: relativePath,
      inferredDocumentKind: _pathPolicy.inferContentTypeFromPath(relativePath),
      title: relativePath.split('/').last,
      content: content,
    );
  }
}
