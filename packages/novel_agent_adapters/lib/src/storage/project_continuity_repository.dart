import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_document_codec_service.dart';
import 'project_continuity_frame_document_codec_service.dart';
import 'project_continuity_path_policy.dart';
import 'project_continuity_scope_document_codec_service.dart';
import 'project_json_document_service.dart';

class ProjectContinuityRepository {
  ProjectContinuityRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectContinuityPathPolicy? pathPolicy,
    ProjectContinuityDocumentCodecService? bundleCodecService,
    ProjectContinuityScopeDocumentCodecService? scopeCodecService,
    ProjectContinuityFrameDocumentCodecService? frameCodecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathPolicy = pathPolicy ?? ProjectContinuityPathPolicy(),
       _bundleCodecService =
           bundleCodecService ?? ProjectContinuityDocumentCodecService(),
       _scopeCodecService =
           scopeCodecService ?? ProjectContinuityScopeDocumentCodecService(),
       _frameCodecService =
           frameCodecService ?? ProjectContinuityFrameDocumentCodecService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectContinuityPathPolicy _pathPolicy;
  final ProjectContinuityDocumentCodecService _bundleCodecService;
  final ProjectContinuityScopeDocumentCodecService _scopeCodecService;
  final ProjectContinuityFrameDocumentCodecService _frameCodecService;

  Future<ProjectContinuityBundle?> load(ProjectDescriptor project) async {
    final bundleDocument = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathPolicy.bundlePath(),
    );
    if (bundleDocument.isEmpty) {
      return null;
    }

    final scopes = <ContinuationScope>[];
    final overlays = <ContinuationScopeOverlay>[];
    for (final scopeId in _bundleCodecService.scopeIds(bundleDocument)) {
      final scopeDocument = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        _pathPolicy.scopePath(scopeId),
      );
      if (scopeDocument.isEmpty) {
        continue;
      }
      final parsed = _scopeCodecService.parseDocument(scopeDocument);
      if (parsed.scope.id.isEmpty) {
        continue;
      }
      scopes.add(parsed.scope);
      overlays.addAll(parsed.overlays);
    }

    final frames = <ContinuityFrame>[];
    for (final frameId in _bundleCodecService.frameIds(bundleDocument)) {
      final frameDocument = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        _pathPolicy.framePath(frameId),
      );
      if (frameDocument.isEmpty) {
        continue;
      }
      final frame = _frameCodecService.parseDocument(frameDocument);
      if (frame.id.isEmpty) {
        continue;
      }
      frames.add(frame);
    }

    return _bundleCodecService.parseDocument(
      bundleDocument,
      scopes: scopes,
      scopeOverlays: overlays,
      frames: frames,
    );
  }

  Future<void> save(
    ProjectDescriptor project,
    ProjectContinuityBundle bundle,
  ) async {
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathPolicy.bundlePath(),
      _bundleCodecService.toDocument(bundle),
    );

    for (final scope in bundle.scopes) {
      final overlays = bundle.scopeOverlays
          .where((item) => item.scopeId == scope.id)
          .toList(growable: false);
      await _jsonDocumentService.writeJsonMap(
        project.rootPath,
        _pathPolicy.scopePath(scope.id),
        _scopeCodecService.toDocument(scope: scope, overlays: overlays),
      );
    }

    for (final frame in bundle.frames) {
      await _jsonDocumentService.writeJsonMap(
        project.rootPath,
        _pathPolicy.framePath(frame.id),
        _frameCodecService.toDocument(frame),
      );
    }
  }
}
