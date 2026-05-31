import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_bundle_write_file.dart';

class ProjectBundleWritePlan {
  const ProjectBundleWritePlan({
    required this.bundleKind,
    required this.title,
    required this.sourcePath,
    required this.files,
    this.skippedPaths = const <String>[],
  });

  final String bundleKind;
  final String title;
  final String sourcePath;
  final List<ProjectBundleWriteFile> files;
  final List<String> skippedPaths;

  JsonMap toJson() {
    return <String, Object?>{
      'bundle_kind': bundleKind,
      'title': title,
      'source_path': sourcePath,
      'write_count': files.length,
      'files': files
          .map(
            (file) => <String, Object?>{
              'entry_kind': file.entryKind,
              'entry_id': file.entryId,
              'target_path': file.targetPath,
            },
          )
          .toList(growable: false),
      'skipped_paths': skippedPaths.toList(growable: false),
    };
  }
}
