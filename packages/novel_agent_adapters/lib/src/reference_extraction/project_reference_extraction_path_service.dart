import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../tools/project_tool_path_policy.dart';

class ProjectReferenceExtractionPathService {
  ProjectReferenceExtractionPathService({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String substrateRootPath(ProjectDescriptor project) {
    return _joinProjectPath(project.rootPath, <String>[
      '.novel_agent',
      'reference_extraction',
      'substrate',
    ]);
  }

  String stagingRootPath(ProjectDescriptor project) {
    return _joinProjectPath(project.rootPath, <String>[
      '.novel_agent',
      'reference_extraction',
      'staging',
    ]);
  }

  String bundleRootPath(
    ProjectDescriptor project, {
    required String packageId,
    required String packageVersionId,
  }) {
    final bundleDirectoryName = _toolPathPolicy.safeFileName(
      '${packageId}_${packageVersionId}',
      fallback: 'reference_bundle',
    );
    return _joinProjectPath(project.rootPath, <String>[
      '.novel_agent',
      'reference_extraction',
      'bundles',
      bundleDirectoryName,
    ]);
  }

  String _joinProjectPath(String rootPath, List<String> segments) {
    return <String>[rootPath, ...segments].join(Platform.pathSeparator);
  }
}
