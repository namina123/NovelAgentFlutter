import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectModeGuidanceRevisitService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectModeGuidanceRepository repository;
    late ProjectModeGuidanceRevisitService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_mode_guidance_revisit_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      repository = ProjectModeGuidanceRepository(workspacePort: workspacePort);
      service = ProjectModeGuidanceRevisitService(
        taskRepository: taskRepository,
        repository: repository,
      );
      project = ProjectDescriptor(
        id: 'mode_guidance_revisit_test',
        name: '长期约束回看测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );

      final transitionService = ModeGuidanceTransitionService();
      var state = transitionService.initialize('seed_autopilot_novel');
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'seed_scope',
          'field': 'seed_scope',
          'value': '黑暗奇幻长篇',
          'label': '黑暗奇幻长篇',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '誓约体系不可被真正伪造，违约会反噬。',
          'label': '誓约体系',
        },
        <String, String>{
          'stage': 'protagonist_drive',
          'field': 'protagonist_drive',
          'value': '主角要翻案复仇，并夺回北境话语权。',
          'label': '翻案复仇',
        },
        <String, String>{
          'stage': 'style_target',
          'field': 'style_target',
          'value': '干净利落，减少说明腔。',
          'label': '干净利落',
        },
      ]) {
        state = transitionService.answer(
          state,
          stageId: item['stage']!,
          fieldKey: item['field']!,
          value: item['value']!,
          label: item['label']!,
          source: 'option',
        );
      }
      await repository.save(project, state);
      await taskRepository.saveRecord(
        project,
        'tracking/checkpoint_reviews/chapter_001.json',
        const <String, Object?>{
          'mode': 'seed_autopilot_novel',
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
          ],
          'drift_signals': <Object?>[
            <String, Object?>{
              'domain': 'entity',
              'severity': 'high',
              'title': '角色状态漂移',
              'note': '主角动机表达不稳。',
            },
          ],
        },
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('builds revisit package with content previews', () async {
      final result = await service.buildPackage(
        project,
        'tracking/checkpoint_reviews/chapter_001.json',
      );

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(
        ValueReaders.stringList(result['focus_domains']),
        contains('entity'),
      );
      expect(
        ValueReaders.mapList(result['items']).any(
          (item) =>
              ValueReaders.stringValue(item['domain']) == 'summary' &&
              ValueReaders.stringValue(item['content_preview']).isNotEmpty,
        ),
        isTrue,
      );
      expect(
        ValueReaders.mapList(result['items']).any(
          (item) =>
              ValueReaders.stringValue(item['domain']) == 'entity' &&
              ValueReaders.stringValue(item['content_preview']).contains('主角'),
        ),
        isTrue,
      );
    });
  });
}
