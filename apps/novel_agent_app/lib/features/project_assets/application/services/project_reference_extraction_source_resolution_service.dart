import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../book_deconstruction/application/services/book_deconstruction_structured_source_projection_service.dart';

class ProjectReferenceExtractionSourceResolution {
  const ProjectReferenceExtractionSourceResolution({
    required this.ok,
    required this.sourceFilePath,
    required this.statusMessage,
    this.usedDeconstructionProjection = false,
  });

  final bool ok;
  final String sourceFilePath;
  final String statusMessage;
  final bool usedDeconstructionProjection;
}

class ProjectReferenceExtractionSourceResolutionService {
  ProjectReferenceExtractionSourceResolutionService({
    ProjectRelativePathResolver? relativePathResolver,
    ProjectWorkspacePort? workspacePort,
    BookDeconstructionStructuredSourceProjectionService?
    structuredSourceProjectionService,
  }) : _relativePathResolver =
           relativePathResolver ?? ProjectRelativePathResolver(),
       _workspacePort = workspacePort ?? LocalProjectWorkspacePort(),
       _structuredSourceProjectionService =
           structuredSourceProjectionService ??
           const BookDeconstructionStructuredSourceProjectionService();

  final ProjectCapabilityService _projectCapabilityService =
      ProjectCapabilityService();
  final ProjectRelativePathResolver _relativePathResolver;
  final ProjectWorkspacePort _workspacePort;
  final BookDeconstructionStructuredSourceProjectionService
  _structuredSourceProjectionService;

  Future<ProjectReferenceExtractionSourceResolution> resolve({
    required ProjectDescriptor project,
    required Future<String?> Function() pickSourceFile,
  }) async {
    if (_hasBookDeconstructionCapability(project)) {
      final relativePath = _structuredSourceProjectionService.targetPath(
        storageStrategy: project.storageStrategy,
      );
      final content = await _workspacePort.readTextFile(
        project.rootPath,
        relativePath,
      );
      if (content == null || content.trim().isEmpty) {
        return const ProjectReferenceExtractionSourceResolution(
          ok: false,
          sourceFilePath: '',
          statusMessage: '当前拆书项目还没有可用的拆书产物，请先完成拆书预览并确认。',
        );
      }
      final absolutePath = _relativePathResolver.resolve(
        rootPath: project.rootPath,
        relativePath: relativePath,
      );
      final file = File(absolutePath);
      if (!await file.exists()) {
        await file.parent.create(recursive: true);
        await file.writeAsString(content, flush: true);
      }
      return ProjectReferenceExtractionSourceResolution(
        ok: true,
        sourceFilePath: absolutePath,
        statusMessage: '已使用拆书产物作为提取源文。',
        usedDeconstructionProjection: true,
      );
    }
    final selectedPath = await pickSourceFile();
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      return const ProjectReferenceExtractionSourceResolution(
        ok: false,
        sourceFilePath: '',
        statusMessage: '已取消参考资料提取。',
      );
    }
    return ProjectReferenceExtractionSourceResolution(
      ok: true,
      sourceFilePath: selectedPath.trim(),
      statusMessage: '已选择参考源文档。',
    );
  }

  bool _hasBookDeconstructionCapability(ProjectDescriptor project) {
    return _projectCapabilityService.hasBookDeconstruction(
      projectTypeId: project.projectType,
      additionalTraitIds: project.additionalTraitIds,
      runtimeBaselineId: project.runtimeBaselineId,
    );
  }
}
