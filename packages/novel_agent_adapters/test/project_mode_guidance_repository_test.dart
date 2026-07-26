import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectModeGuidanceRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectModeGuidanceRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_mode_guidance_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      repository = ProjectModeGuidanceRepository(workspacePort: workspacePort);
      project = ProjectDescriptor(
        id: 'project_test',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('saves hidden json, summary markdown and sqlite projections', () async {
      final transitionService = ModeGuidanceTransitionService();
      var state = transitionService.initialize('seed_autopilot_novel');
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'seed_scope',
          'field': 'seed_scope',
          'value': '只有一句灵感',
          'label': '只有一句灵感',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '帝国靠誓约维持秩序。违约会反噬。',
          'label': '奇幻秩序',
        },
        <String, String>{
          'stage': 'protagonist_drive',
          'field': 'protagonist_drive',
          'value': '复仇与翻案。',
          'label': '复仇翻盘',
        },
        <String, String>{
          'stage': 'style_target',
          'field': 'style_target',
          'value': '干净利落，偏商业长篇。',
          'label': '干净利落',
        },
        <String, String>{
          'stage': 'core_promise',
          'field': 'core_promise',
          'value': '高压权谋与连续逆转。',
          'label': '权谋悬压',
        },
        <String, String>{
          'stage': 'autonomy_guardrails',
          'field': 'autonomy_guardrails',
          'value': '跨卷大转折需要确认。',
          'label': '按卷确认',
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
      final loaded = await repository.load(
        project,
        modeId: 'seed_autopilot_novel',
      );

      expect(loaded, isNotNull);
      expect(loaded!.answers.any((answer) => answer.label == '只有一句灵感'), isTrue);

      final summaryPath = File(
        '${tempDirectory.path}${Platform.pathSeparator}tracking${Platform.pathSeparator}modes${Platform.pathSeparator}seed_autopilot_novel${Platform.pathSeparator}guidance.md',
      );
      final statePath = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}modes${Platform.pathSeparator}seed_autopilot_novel${Platform.pathSeparator}guidance_state.json',
      );
      final sqlitePath = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}sqlite${Platform.pathSeparator}novel_agent.db',
      );

      expect(await summaryPath.exists(), isTrue);
      expect(await statePath.exists(), isTrue);
      expect(await sqlitePath.exists(), isTrue);

      final summaryText = await summaryPath.readAsString();
      expect(summaryText, contains('灵感托管式长篇 引导摘要'));
      expect(summaryText, contains('只有一句灵感'));

      final database = sqlite3.open(sqlitePath.path);
      addTearDown(database.dispose);
      final styleCount = database.select(
        'SELECT COUNT(*) AS total FROM style_profile WHERE mode_id = ?',
        <Object?>['seed_autopilot_novel'],
      );
      final worldCount = database.select(
        'SELECT COUNT(*) AS total FROM world_rule_set WHERE mode_id = ?',
        <Object?>['seed_autopilot_novel'],
      );
      final entityCount = database.select(
        'SELECT COUNT(*) AS total FROM entity_identity WHERE mode_id = ?',
        <Object?>['seed_autopilot_novel'],
      );
      final styleRuleCount = database.select(
        'SELECT COUNT(*) AS total FROM style_rule',
      );
      final worldRuleEntryCount = database.select(
        'SELECT COUNT(*) AS total FROM world_rule_entry',
      );
      expect(styleCount.first['total'], 1);
      expect(worldCount.first['total'], 1);
      expect(entityCount.first['total'], 1);
      expect(styleRuleCount.first['total'], greaterThanOrEqualTo(2));
      expect(worldRuleEntryCount.first['total'], greaterThanOrEqualTo(2));
    });
  });
}
