import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintProfileRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ExpressionConstraintProfileRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-expression-constraint-profiles-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      repository = ExpressionConstraintProfileRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'persists only project profiles and merges builtin presets on load',
      () async {
        await repository.saveProjectProfiles(
          project,
          const <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'custom_platform_short_pulse',
              displayName: '平台短句脉冲',
              summary: '倾向较短句节奏和高信息密度段落。',
              kind: ExpressionConstraintKind.rhythmControl,
              rules: <String>['多数段落优先保持短句推进。'],
            ),
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '项目内去 AI 风',
              summary: '项目级覆盖版去 AI 风。',
              kind: ExpressionConstraintKind.naturalExpression,
              rules: <String>['项目内覆盖 builtin de_ai。'],
            ),
          ],
        );

        final projectOnly = await repository.loadProjectProfiles(project);
        final merged = await repository.loadProfiles(project);

        expect(projectOnly, hasLength(2));
        expect(projectOnly.map((profile) => profile.id), contains('de_ai'));
        expect(
          merged.map((profile) => profile.id),
          contains('strict_pov_boundary'),
        );
        expect(
          merged.map((profile) => profile.id),
          contains('low_jargon_narration'),
        );
        final deAi = merged.firstWhere((profile) => profile.id == 'de_ai');
        expect(deAi.displayName, '项目内去 AI 风');
        final profileFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}settings${Platform.pathSeparator}expression_constraint_profiles.json',
        );
        expect(await profileFile.exists(), isTrue);
      },
    );
  });
}
