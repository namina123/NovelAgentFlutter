import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalProjectRepository', () {
    for (final projectType in <String>[
      'novel',
      'long_novel',
      'knowledge_base',
      'book_deconstruction',
      'short_collection',
    ]) {
      test(
        'does not open a $projectType project with an invalid manifest contract',
        () async {
          final tempRoot = await Directory.systemTemp.createTemp(
            'novel-agent-local-project-corrupt-',
          );
          try {
            final projectRoot = Directory(
              '${tempRoot.path}${Platform.pathSeparator}$projectType-project',
            )..createSync(recursive: true);
            final manifestFile = File(
              '${projectRoot.path}${Platform.pathSeparator}${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}',
            )..createSync(recursive: true);
            await manifestFile.writeAsString('''
{
  "title": "损坏项目",
  "project_type": "$projectType",
  "storage_strategy": "future_store"
}
''');

            final repository = LocalProjectRepository();

            await expectLater(
              repository.openByPath(projectRoot.path),
              throwsA(isA<ProjectManifestCorruptionException>()),
            );
          } finally {
            if (tempRoot.existsSync()) {
              await tempRoot.delete(recursive: true);
            }
          }
        },
      );
    }

    test('openByPath ignores directory without manifest', () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-local-project-no-manifest-',
      );
      try {
        final projectRoot = Directory(
          '${tempRoot.path}${Platform.pathSeparator}plain-folder',
        )..createSync(recursive: true);

        final repository = LocalProjectRepository();
        final descriptor = await repository.openByPath(projectRoot.path);

        expect(descriptor, isNull);
      } finally {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      }
    });

    test('openByPath rejects a present null contract field', () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-local-project-null-contract-',
      );
      try {
        final projectRoot = Directory(
          '${tempRoot.path}${Platform.pathSeparator}null-contract-project',
        )..createSync(recursive: true);
        final manifestFile = File(
          '${projectRoot.path}${Platform.pathSeparator}${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}',
        )..createSync(recursive: true);
        await manifestFile.writeAsString('''
{
  "title": "不应降级的 SQLite 长篇",
  "project_type": null,
  "storage_strategy": "sqlite_project_store",
  "runtime_baseline_id": "continuous_autonomous"
}
''');

        await expectLater(
          LocalProjectRepository().openByPath(projectRoot.path),
          throwsA(isA<ProjectManifestCorruptionException>()),
        );
      } finally {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      }
    });

    test(
      'openByPath reads runtime baseline and additional traits from manifest',
      () async {
        // 中文注释: 这里验证项目重新打开时会把创建阶段选定的运行基准和复合能力一并识别回来。
        final tempRoot = await Directory.systemTemp.createTemp(
          'novel-agent-local-project-',
        );
        try {
          final projectRoot = Directory(
            '${tempRoot.path}${Platform.pathSeparator}long-project',
          )..createSync(recursive: true);
          final manifestFile = File(
            '${projectRoot.path}${Platform.pathSeparator}${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}',
          )..createSync(recursive: true);
          final manifest = ProjectManifestCodecService().create(
            title: '长篇项目',
            projectType: 'long_novel',
            runtimeBaselineId: 'continuous_autonomous',
            additionalTraitIds: const <String>['book_deconstruction'],
          );
          await manifestFile.writeAsString(
            ProjectManifestCodecService().encode(manifest),
          );

          final repository = LocalProjectRepository();
          final descriptor = await repository.openByPath(projectRoot.path);

          expect(descriptor, isNotNull);
          expect(descriptor!.projectType, 'long_novel');
          expect(descriptor.runtimeBaselineId, 'continuous_autonomous');
          expect(descriptor.additionalTraitIds, <String>[
            'book_deconstruction',
          ]);
        } finally {
          if (tempRoot.existsSync()) {
            await tempRoot.delete(recursive: true);
          }
        }
      },
    );
  });
}
