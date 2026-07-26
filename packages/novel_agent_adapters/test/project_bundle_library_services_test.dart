import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project bundle library services', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkspaceToolHostAdapter hostPort;
    late ProjectAssetLibraryService assetLibraryService;
    late ProjectCharacterProfileRepository characterRepository;
    late ProjectOrganizationProfileRepository organizationRepository;
    late ProjectPromptTemplateService promptTemplateService;
    late ProjectRelationshipRepository relationshipRepository;
    late ProjectTimelineRepository timelineRepository;
    late ProjectRuntimeProfileRepository runtimeProfileRepository;
    late ProjectStyleBundleLibraryService styleBundleLibraryService;
    late ProjectCharacterBundleLibraryService characterBundleLibraryService;
    late ProjectAssetBundleLibraryService assetBundleLibraryService;
    late ProjectPackageLibraryService projectPackageLibraryService;
    late Future<ProjectDescriptor> Function(String name) prepareProject;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_bundle_library_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      assetLibraryService = ProjectAssetLibraryService(
        workspacePort: workspacePort,
        projectToolHostPort: hostPort,
      );
      characterRepository = ProjectCharacterProfileRepository(
        hostPort: hostPort,
      );
      organizationRepository = ProjectOrganizationProfileRepository(
        hostPort: hostPort,
      );
      promptTemplateService = ProjectPromptTemplateService(
        workspacePort: workspacePort,
      );
      relationshipRepository = ProjectRelationshipRepository(
        hostPort: hostPort,
      );
      timelineRepository = ProjectTimelineRepository(hostPort: hostPort);
      runtimeProfileRepository = ProjectRuntimeProfileRepository(
        workspacePort: workspacePort,
      );
      final fileAccessService = ProjectBundleFileAccessService(
        hostPort: hostPort,
      );
      final applyService = ProjectBundleApplyService(hostPort: hostPort);
      styleBundleLibraryService = ProjectStyleBundleLibraryService(
        assetLibraryService: assetLibraryService,
        fileAccessService: fileAccessService,
        applyService: applyService,
      );
      characterBundleLibraryService = ProjectCharacterBundleLibraryService(
        characterRepository: characterRepository,
        organizationRepository: organizationRepository,
        fileAccessService: fileAccessService,
        applyService: applyService,
      );
      assetBundleLibraryService = ProjectAssetBundleLibraryService(
        assetLibraryService: assetLibraryService,
        fileAccessService: fileAccessService,
        applyService: applyService,
      );
      projectPackageLibraryService = ProjectPackageLibraryService(
        workspacePort: workspacePort,
        runtimeProfileRepository: runtimeProfileRepository,
        promptTemplateService: promptTemplateService,
        characterRepository: characterRepository,
        organizationRepository: organizationRepository,
        assetLibraryService: assetLibraryService,
        relationshipRepository: relationshipRepository,
        timelineRepository: timelineRepository,
        fileAccessService: fileAccessService,
        applyService: applyService,
      );
      prepareProject = (name) async {
        final root = Directory('${tempDirectory.path}\\$name');
        await root.create(recursive: true);
        final project = ProjectDescriptor(
          id: name,
          name: name,
          rootPath: root.path,
          projectType: 'standard_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          runtimeBaselineId: 'continuous_autonomous',
        );
        final manifestCodecService = ProjectManifestCodecService();
        final runtimeProfileDocumentService =
            ProjectRuntimeProfileDocumentService();
        final manifest = manifestCodecService.create(
          title: name,
          projectType: project.projectType,
          storageStrategy: project.storageStrategy,
          runtimeBaselineId: project.runtimeBaselineId,
        );
        await workspacePort.writeTextFile(
          root.path,
          ProjectManifestCodecService.manifestRelativePath,
          manifestCodecService.encode(manifest),
        );
        final runtimeProfile = runtimeProfileDocumentService.buildProfile(
          projectType: project.projectType,
          runtimeBaselineId: project.runtimeBaselineId,
        );
        await workspacePort.writeTextFile(
          root.path,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
          runtimeProfileDocumentService.encode(runtimeProfile),
        );
        return project;
      };
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'style bundle exports directory and imports into target project',
      () async {
        final sourceProject = await prepareProject('style_source');
        final targetProject = await prepareProject('style_target');
        final exportRoot = Directory('${tempDirectory.path}\\exports');
        await exportRoot.create(recursive: true);
        await assetLibraryService.saveStyle(
          sourceProject,
          const <String, Object?>{
            'id': 'serial_style',
            'display_name': '连载风格',
            'summary': '克制、压抑、视角贴近人物。',
          },
        );

        final exportResult = await styleBundleLibraryService.exportBundle(
          sourceProject,
          targetDirectoryPath: exportRoot.path,
          title: '风格包测试',
        );

        expect(ValueReaders.boolValue(exportResult['ok']), isTrue);
        final exportDirectoryPath = ValueReaders.stringValue(
          exportResult['export_directory_path'],
        );
        expect(File('$exportDirectoryPath\\bundle.json').existsSync(), isTrue);
        expect(
          File(
            '$exportDirectoryPath\\assets\\styles\\serial_style.style.md',
          ).existsSync(),
          isTrue,
        );

        final importResult = await styleBundleLibraryService.importBundle(
          targetProject,
          sourcePath: exportDirectoryPath,
        );

        expect(ValueReaders.boolValue(importResult['ok']), isTrue);
        expect(
          File(
            '${targetProject.rootPath}\\assets\\styles\\serial_style.style.md',
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'character bundle exports character and organization markdown snapshots',
      () async {
        final sourceProject = await prepareProject('character_source');
        final targetProject = await prepareProject('character_target');
        final exportRoot = Directory(
          '${tempDirectory.path}\\exports_character',
        );
        await exportRoot.create(recursive: true);
        await characterRepository.saveProfile(
          sourceProject,
          profile: const CharacterProfile(
            id: 'hero_01',
            displayName: '主角',
            summary: '谨慎、沉稳。',
          ),
        );
        await organizationRepository.saveProfile(
          sourceProject,
          profile: const OrganizationProfile(
            id: 'sect_01',
            displayName: '夜雨会',
            summary: '地下情报组织。',
          ),
        );

        final exportResult = await characterBundleLibraryService.exportBundle(
          sourceProject,
          targetDirectoryPath: exportRoot.path,
          title: '角色卡包测试',
        );

        expect(ValueReaders.boolValue(exportResult['ok']), isTrue);
        final exportDirectoryPath = ValueReaders.stringValue(
          exportResult['export_directory_path'],
        );
        expect(
          File(
            '$exportDirectoryPath\\assets\\characters\\hero_01.md',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '$exportDirectoryPath\\assets\\organizations\\sect_01.md',
          ).existsSync(),
          isTrue,
        );

        final importResult = await characterBundleLibraryService.importBundle(
          targetProject,
          sourcePath: exportDirectoryPath,
        );

        expect(ValueReaders.boolValue(importResult['ok']), isTrue);
        expect(
          File(
            '${targetProject.rootPath}\\assets\\characters\\hero_01.md',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${targetProject.rootPath}\\assets\\organizations\\sect_01.md',
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'project asset bundle uses canonical assets paths during import',
      () async {
        final sourceProject = await prepareProject('asset_source');
        final targetProject = await prepareProject('asset_target');
        final exportRoot = Directory('${tempDirectory.path}\\exports_asset');
        await exportRoot.create(recursive: true);
        await assetLibraryService.saveStyle(
          sourceProject,
          const <String, Object?>{
            'id': 'serial_style',
            'display_name': '连载风格',
            'summary': '克制、冷峻。',
          },
        );
        await assetLibraryService.saveForeshadow(
          sourceProject,
          const <String, Object?>{
            'id': 'tower_secret',
            'title': '高塔秘密',
            'summary': '第一卷埋下的异常迹象。',
          },
        );

        final exportResult = await assetBundleLibraryService.exportBundle(
          sourceProject,
          targetDirectoryPath: exportRoot.path,
          title: '项目资产包测试',
        );

        expect(ValueReaders.boolValue(exportResult['ok']), isTrue);
        final importResult = await assetBundleLibraryService.importBundle(
          targetProject,
          sourcePath: ValueReaders.stringValue(
            exportResult['export_directory_path'],
          ),
        );

        expect(ValueReaders.boolValue(importResult['ok']), isTrue);
        expect(
          File(
            '${targetProject.rootPath}\\assets\\styles\\serial_style.style.md',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${targetProject.rootPath}\\assets\\foreshadows\\tower_secret.foreshadow.md',
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'project package exports and imports manifest runtime assets and templates',
      () async {
        final sourceProject = await prepareProject('package_source');
        final targetProject = await prepareProject('package_target');
        final exportRoot = Directory('${tempDirectory.path}\\exports_package');
        await exportRoot.create(recursive: true);
        await characterRepository.saveProfile(
          sourceProject,
          profile: const CharacterProfile(
            id: 'hero_01',
            displayName: '主角',
            summary: '冷静敏锐。',
          ),
        );
        await organizationRepository.saveProfile(
          sourceProject,
          profile: const OrganizationProfile(
            id: 'sect_01',
            displayName: '夜雨会',
            summary: '地下组织。',
          ),
        );
        await assetLibraryService.saveStyle(
          sourceProject,
          const <String, Object?>{
            'id': 'serial_style',
            'display_name': '连载风格',
            'summary': '低饱和、贴近视角。',
          },
        );
        await assetLibraryService.saveForeshadow(
          sourceProject,
          const <String, Object?>{
            'id': 'tower_secret',
            'title': '高塔秘密',
            'summary': '埋在第一卷。',
          },
        );
        await relationshipRepository.save(
          sourceProject,
          const RelationshipRecord(
            id: 'hero_vs_sect',
            displayName: '主角与夜雨会',
            leftEntityId: 'hero_01',
            rightEntityId: 'sect_01',
            summary: '互相利用又彼此提防。',
          ),
        );
        await timelineRepository.save(
          sourceProject,
          const TimelineRecord(
            id: 'event_01',
            displayName: '黑市相遇',
            summary: '主角第一次接触夜雨会。',
          ),
        );
        await promptTemplateService
            .saveTemplate(sourceProject, const <String, Object?>{
              'id': 'chapter_atomic_plus',
              'name': '章节任务增强模板',
              'scope': 'task',
              'content': '请根据 {{chapter}} 扩写。',
            });

        final exportResult = await projectPackageLibraryService.exportBundle(
          sourceProject,
          targetDirectoryPath: exportRoot.path,
          title: '项目包测试',
        );

        expect(ValueReaders.boolValue(exportResult['ok']), isTrue);
        final exportDirectoryPath = ValueReaders.stringValue(
          exportResult['export_directory_path'],
        );
        expect(
          File(
            '$exportDirectoryPath\\${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', '\\')}',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '$exportDirectoryPath\\${ProjectRuntimeProfileDocumentService.profileRelativePath.replaceAll('/', '\\')}',
          ).existsSync(),
          isTrue,
        );

        final importResult = await projectPackageLibraryService.importBundle(
          targetProject,
          sourcePath: exportDirectoryPath,
        );

        expect(ValueReaders.boolValue(importResult['ok']), isTrue);
        expect(
          File(
            '${targetProject.rootPath}\\${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', '\\')}',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${targetProject.rootPath}\\assets\\characters\\hero_01.md',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${targetProject.rootPath}\\prompts\\chapter_atomic_plus.json',
          ).existsSync(),
          isTrue,
        );
      },
    );
  });
}
