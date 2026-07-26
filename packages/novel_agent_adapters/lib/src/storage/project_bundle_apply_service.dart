import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_bundle_write_plan.dart';
import 'project_structured_content_bridge_service.dart';

class ProjectBundleApplyService {
  ProjectBundleApplyService({
    required ProjectToolHostPort hostPort,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _hostPort = hostPort,
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _hostPort;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<JsonMap> applyToProject(
    ProjectDescriptor project,
    ProjectBundleWritePlan plan,
  ) async {
    // 中文注释: apply 阶段只执行已经生成好的写盘计划，不再反向参与预检和冲突判定。
    final changedPaths = <String>[];
    for (final file in plan.files) {
      final documentKind = _documentKindFor(file.entryKind);
      final snapshot = documentKind.isEmpty
          ? null
          : await _structuredContentBridgeService.loadStructuredDocument(
              project: project,
              documentPath: file.targetPath,
            );
      try {
        if (documentKind.isNotEmpty) {
          await _structuredContentBridgeService.persistStructuredDocument(
            project: project,
            documentPath: file.targetPath,
            documentKind: documentKind,
            title: file.targetPath.split('/').last,
            content: file.content,
          );
        }
        await _hostPort.writeTextFile(
          project.rootPath,
          file.targetPath,
          file.content,
        );
      } catch (_) {
        if (documentKind.isNotEmpty) {
          try {
            await _structuredContentBridgeService.restoreStructuredDocument(
              project: project,
              documentPath: file.targetPath,
              snapshot: snapshot,
            );
          } catch (_) {}
        }
        rethrow;
      }
      changedPaths.add(file.targetPath);
    }
    return <String, Object?>{
      'ok': changedPaths.isNotEmpty,
      'bundle_kind': plan.bundleKind,
      'title': plan.title,
      'source_path': plan.sourcePath,
      'changed_paths': changedPaths,
      'skipped_paths': plan.skippedPaths,
      'summary': changedPaths.isEmpty
          ? '没有需要写入的文件。'
          : '已写入 ${changedPaths.length} 个文件。',
    };
  }

  String _documentKindFor(String entryKind) {
    switch (entryKind.trim()) {
      case 'character':
        return 'character';
      case 'organization':
        return 'organization_profile';
      case 'style':
        return 'style';
      case 'foreshadow':
        return 'foreshadow_record';
      case 'relationship':
        return 'relationship_record';
      case 'timeline':
        return 'timeline_record';
      default:
        return '';
    }
  }
}
