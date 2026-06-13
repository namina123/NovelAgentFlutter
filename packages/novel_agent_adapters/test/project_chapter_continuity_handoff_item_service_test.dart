import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_adapters/src/workflow/project_chapter_continuity_handoff_item_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectChapterContinuityHandoffItemService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectChapterContinuityHandoffItemService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-continuity-handoff-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'continuity_handoff_project',
        name: '连续性承接项目',
        rootPath: tempDirectory.path,
      );
      service = const ProjectChapterContinuityHandoffItemService();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'falls back to chapter end excerpt when delivery summary is a placeholder',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章.md',
          '# 第02章\n\n陆安站在门前敲了三下，门里的人应了一声，脚步声已经到了门后。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章.md.json',
          jsonEncode(<String, Object?>{
            'submission': <String, Object?>{
              'summary': 'ordinary conversation chapter delivery',
              'final_state_summary': <String, Object?>{
                'chapter_end_excerpt': '陆安站在门前敲了三下，门里的人应了一声，脚步声已经到了门后。',
                'next_chapter_handoff': '直接从门后人的回应继续，不要回退到敲门前。',
              },
            },
          }),
        );

        final visibleEntries = await workspacePort.listEntries(
          project.rootPath,
        );
        final items = await service.buildItems(
          workspacePort: workspacePort,
          project: project,
          visibleEntries: visibleEntries,
          taskType: 'chapter',
          chapterLabel: '第三章',
        );
        final deliveryItem = items.firstWhere(
          (item) => item.title.contains('交付摘要'),
        );
        final activationText = ValueReaders.stringValue(
          deliveryItem.metadata['activation_text'],
        );

        expect(activationText, contains('上一章已完成剧情（不要重复重演）：章末落点：陆安站在门前敲了三下'));
        expect(activationText, contains('下一章承接锚点（必须直接续上）：直接从门后人的回应继续'));
        expect(
          activationText,
          isNot(contains('ordinary conversation chapter delivery')),
        );
      },
    );
  });
}
