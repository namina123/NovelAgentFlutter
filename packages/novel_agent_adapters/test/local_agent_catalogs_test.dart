import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Local agent catalogs', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-local-agent-catalogs-',
      );
      await Directory(
        '${tempDirectory.path}${Platform.pathSeparator}agents',
      ).create(recursive: true);
      await Directory(
        '${tempDirectory.path}${Platform.pathSeparator}agent_groups',
      ).create(recursive: true);
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('package catalog applies global agent overlays', () async {
      final overlayRepository = AgentCatalogOverlayRepository(
        settingsRootPath: tempDirectory.path,
      );
      await overlayRepository.saveOverlay(<String, Object?>{
        'agent_id': 'default_generalist',
        'display_label': '统一默认创作智能体',
        'recommended_by_default': true,
      });
      final catalog = LocalAgentPackageCatalog(
        packageDirectoryLoader: _FakePackageDirectoryLoader(),
        packageRootPathResolver: PackageRootPathResolver(
          workspaceRootPath: tempDirectory.path,
        ),
        overlayRepository: overlayRepository,
      );

      final packages = await catalog.loadAgentPackages(project);
      final agent = packages.singleWhere(
        (item) => ValueReaders.stringValue(item['id']) == 'default_generalist',
      );

      expect(agent['display_label'], '统一默认创作智能体');
      expect(agent['recommended_by_default'], isTrue);
    });

    test(
      'group catalog includes starter groups and applies overlays',
      () async {
        final overlayRepository = AgentGroupCatalogOverlayRepository(
          settingsRootPath: tempDirectory.path,
        );
        await overlayRepository.saveOverlay(<String, Object?>{
          'group_id': 'starter_long_novel_seed_generalist',
          'display_label': '统一长任务灵感组',
        });
        final catalog = LocalAgentGroupCatalog(
          groupDirectoryLoader: _FakeGroupDirectoryLoader(),
          packageRootPathResolver: PackageRootPathResolver(
            workspaceRootPath: tempDirectory.path,
          ),
          overlayRepository: overlayRepository,
        );

        final groups = await catalog.loadAgentGroups(
          ProjectDescriptor(
            id: project.id,
            name: project.name,
            rootPath: project.rootPath,
            projectType: 'long_novel',
          ),
        );

        final starterGroup = groups.singleWhere(
          (item) =>
              ValueReaders.stringValue(item['id']) ==
              'starter_long_novel_seed_generalist',
        );
        final fullOutlineGroup = groups.singleWhere(
          (item) =>
              ValueReaders.stringValue(item['id']) ==
              'starter_long_novel_full_outline_generalist',
        );
        expect(starterGroup['display_label'], '统一长任务灵感组');
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(starterGroup['metadata'])['starter_group'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.stringList(
            ValueReaders.mapValue(
              starterGroup['applicability_scope'],
            )['required_trait_ids'],
          ),
          contains('seed_driven'),
        );
        expect(
          ValueReaders.stringList(
            ValueReaders.mapValue(
              fullOutlineGroup['applicability_scope'],
            )['required_trait_ids'],
          ),
          contains('full_outline'),
        );
      },
    );
  });
}

class _FakePackageDirectoryLoader extends LocalPackageDirectoryLoader {
  @override
  Future<List<JsonMap>> loadAgentPackages(String rootDirectoryPath) async {
    return <JsonMap>[
      <String, Object?>{
        'id': 'default_generalist',
        'name': '综合创作智能体',
        'role': '默认智能体',
        'description': '默认智能体',
      },
    ];
  }
}

class _FakeGroupDirectoryLoader extends LocalGroupDirectoryLoader {
  @override
  Future<List<JsonMap>> loadAgentGroups(String rootDirectoryPath) async {
    return const <JsonMap>[];
  }
}
