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
        userPrompt:
            '请先联网核查明代制盐和水利资料，整理成知识库，只保留有来源线索的研究结论。',
        activeDocumentPath: 'premise/project_brief.md',
      );

      expect(profile.taskType, 'research');
      expect(profile.intent, 'research');
    });
  });
}
