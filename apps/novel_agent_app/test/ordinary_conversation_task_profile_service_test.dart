import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_assessment.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_stage.dart';
import 'package:novel_agent_app/features/workbench/application/services/ordinary_conversation_task_profile_service.dart';

void main() {
  group('OrdinaryConversationTaskProfileService', () {
    const service = OrdinaryConversationTaskProfileService();

    const freshOpening = ProjectOpeningMaturityAssessment(
      stage: ProjectOpeningMaturityStage.fresh,
      summary: '',
      authoredFoundationFileCount: 0,
      narrativeFileCount: 0,
    );
    const continueReady = ProjectOpeningMaturityAssessment(
      stage: ProjectOpeningMaturityStage.continueReady,
      summary: '',
      authoredFoundationFileCount: 3,
      narrativeFileCount: 1,
    );

    test('routes opening-stage premise prompts to planning', () {
      final profile = service.resolve(
        agent: const <String, Object?>{
          'id': 'default_generalist',
          'role': 'writer',
        },
        openingMaturity: freshOpening,
        userPrompt: '我先说背景，主角是游戏代练，刚开始只会打杂，先帮我整理世界观和主线。',
        activeDocumentPath: 'premise/project_brief.md',
      );

      expect(profile.taskType, 'planning');
      expect(profile.intent, 'planning');
    });

    test('keeps explicit chapter requests on chapter drafting', () {
      final profile = service.resolve(
        agent: const <String, Object?>{
          'id': 'default_generalist',
          'role': 'writer',
        },
        openingMaturity: continueReady,
        userPrompt: '直接写第一章正文，主角今晚第一次进入副本。',
        activeDocumentPath: 'chapters/第一章.md',
      );

      expect(profile.taskType, 'chapter');
      expect(profile.intent, 'draft');
    });

    test(
      'keeps explicit chapter continuation on chapter drafting even when opening stage and asset file are active',
      () {
        final profile = service.resolve(
          agent: const <String, Object?>{
            'id': 'default_generalist',
            'role': 'writer',
          },
          openingMaturity: freshOpening,
          userPrompt: '继续写第03章。这不是重新规划开局，直接承接上一章章末。',
          activeDocumentPath: 'assets/characters/周砚.md',
        );

        expect(profile.taskType, 'chapter');
        expect(profile.intent, 'draft');
      },
    );

    test('routes research-style prompts to research task', () {
      final profile = service.resolve(
        agent: const <String, Object?>{
          'id': 'default_generalist',
          'role': 'writer',
        },
        openingMaturity: freshOpening,
        userPrompt: '请先联网核查明代制盐和水利资料，整理成知识库，只保留有来源线索的研究结论。',
        activeDocumentPath: 'premise/project_brief.md',
      );

      expect(profile.taskType, 'research');
      expect(profile.intent, 'research');
    });

    test(
      'routes concept-system planning prompts to planning even when project is continue-ready',
      () {
        final profile = service.resolve(
          agent: const <String, Object?>{
            'id': 'default_generalist',
            'role': 'writer',
          },
          openingMaturity: continueReady,
          userPrompt: '先定概念级能力体系，收束一下世界规则和角色边界。',
          activeDocumentPath: '',
        );

        expect(profile.taskType, 'planning');
        expect(profile.intent, 'planning');
      },
    );

    test(
      'routes confirmed character personality and style option into planning instead of chapter drafting',
      () {
        final profile = service.resolve(
          agent: const <String, Object?>{
            'id': 'default_generalist',
            'role': 'writer',
          },
          openingMaturity: continueReady,
          userPrompt:
              '我选择「主角性格与处事风格」。\n\n补充说明：我刚才点击并确认了上一轮选项「主角性格与处事风格」。请把这个选择视为已确认的用户决策，继续推进，不要重新让用户选择同一组选项。\n上一轮候选摘要：已选：主角性格与处事风格；候选：第一章正式正文（直接进入章节写作）。',
          activeDocumentPath: '',
        );

        expect(profile.taskType, 'planning');
        expect(profile.intent, 'planning');
      },
    );

    test(
      'routes style-boundary option selection to planning when active document is not pinned',
      () {
        final profile = service.resolve(
          agent: const <String, Object?>{
            'id': 'default_generalist',
            'role': 'writer',
          },
          openingMaturity: continueReady,
          userPrompt: '我选择了“全书风格与表达边界”。先确认文风、禁区和语言质地。',
          activeDocumentPath: '',
        );

        expect(profile.taskType, 'planning');
        expect(profile.intent, 'planning');
      },
    );
  });
}
