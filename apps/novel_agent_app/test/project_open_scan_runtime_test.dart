import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_open/application/services/project_open_scan_runtime.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectOpenScanRuntime', () {
    test('scan collects projects from default, current and recent paths', () async {
      final rootDirectory = await Directory.systemTemp.createTemp(
        'project_open_scan_runtime_test',
      );
      addTearDown(() async {
        if (await rootDirectory.exists()) {
          await rootDirectory.delete(recursive: true);
        }
      });

      final defaultDirectory = Directory(
        '${rootDirectory.path}${Platform.pathSeparator}alpha_project',
      );
      final currentDirectory = Directory(
        '${rootDirectory.path}${Platform.pathSeparator}beta_project',
      );
      final recentDirectory = Directory(
        '${rootDirectory.path}${Platform.pathSeparator}gamma_project',
      );
      await defaultDirectory.create(recursive: true);
      await currentDirectory.create(recursive: true);
      await recentDirectory.create(recursive: true);

      await _writeManifest(defaultDirectory.path, title: 'Alpha Project');
      await _writeManifest(
        currentDirectory.path,
        title: 'Beta Project',
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      );
      await _writeManifest(recentDirectory.path, title: 'Gamma Project');

      final runtime = ProjectOpenScanRuntime();
      final snapshot = await runtime.scan(
        projectsRootPath: rootDirectory.path,
        recentProjectPath: recentDirectory.path,
        currentProjectPath: currentDirectory.path,
        allowImportLocal: true,
      );

      expect(snapshot.records, hasLength(3));
      expect(snapshot.selectedEntryId, contains('beta_project'));
      expect(
        snapshot.records.first.sourceBadges,
        containsAll(<String>['默认目录']),
      );
      expect(snapshot.records.any((record) => record.isCurrentProject), isTrue);
    });
  });
}

Future<void> _writeManifest(
  String rootPath, {
  required String title,
  String projectType = 'novel',
  String runtimeBaselineId = '',
}) async {
  final manifestPath =
      '$rootPath${Platform.pathSeparator}'
      '${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}';
  final manifestFile = File(manifestPath);
  await manifestFile.parent.create(recursive: true);
  final manifest = ProjectManifestCodecService().create(
    title: title,
    projectType: projectType,
    runtimeBaselineId: runtimeBaselineId,
  );
  await manifestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      ProjectManifestCodecService().toJson(manifest),
    ),
  );
}
