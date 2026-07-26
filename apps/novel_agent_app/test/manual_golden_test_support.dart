import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Resolves a manually maintained golden-artifact directory from any app test.
Directory manualGoldenArtifactsDirectory(String directoryName) {
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 8; depth += 1) {
    final appPubspec = File(
      '${current.path}${Platform.pathSeparator}apps${Platform.pathSeparator}novel_agent_app${Platform.pathSeparator}pubspec.yaml',
    );
    if (appPubspec.existsSync()) {
      return Directory(
        '${current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}$directoryName',
      );
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }

  throw StateError(
    'Unable to locate the repository root for manual golden artifacts.',
  );
}

/// Marks the current manual-golden test as skipped when its source images are absent.
///
/// Golden screenshots under `artifacts/` are reviewed and supplied outside source
/// control. Keeping that prerequisite explicit lets normal test runs stay useful
/// while preserving strict pixel comparison whenever the artifacts are available.
bool skipManualGoldenTestIfArtifactsAreMissing({
  required Directory artifactsDirectory,
  required Iterable<String> expectedFileNames,
}) {
  if (autoUpdateGoldenFiles) {
    return false;
  }

  final missingArtifactPaths = <String>[
    for (final fileName in expectedFileNames)
      if (!File(
        '${artifactsDirectory.path}${Platform.pathSeparator}$fileName',
      ).existsSync())
        '${artifactsDirectory.path}${Platform.pathSeparator}$fileName',
  ];

  if (missingArtifactPaths.isEmpty) {
    return false;
  }

  markTestSkipped(
    'Manual golden artifact(s) are unavailable. Skipping visual comparison: '
    '${missingArtifactPaths.join(', ')}. Restore the recorded artifact(s) to run this comparison.',
  );
  return true;
}
