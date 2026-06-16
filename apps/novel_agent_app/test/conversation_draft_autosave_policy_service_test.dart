import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_draft_autosave_policy_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ConversationDraftAutosavePolicyService', () {
    const service = ConversationDraftAutosavePolicyService();

    test('does not autosave mode guidance question summary', () {
      final result = _result(
        draftMarkdown: '''
好的，收到你的方向。我先总结一下已收束的种子信息。

**还没确认的（需要你回答）：**
- 世界整体风格更偏向哪一类？
- 主角在现实中的职业是否固定？

请先选一个方向，或者直接输入你的想法。
''',
        waitingForUserChoice: false,
      );

      expect(
        service.shouldAutoSave(
          result: result,
          activeDocumentPath: 'chapters/current.md',
          wasModeGuidanceActive: true,
        ),
        isFalse,
      );
    });

    test('autosaves prose-like content for chapter document', () {
      final result = _result(
        draftMarkdown: '''
雨下得很密，像有人把整座城的光都揉进了水里。

林述站在桥边，没有立刻往前走。他听见远处列车的轰鸣，又听见脚下河水撞向护栏的碎响。

这一夜像是某种漫长的前奏，而他知道，自己已经没有回头的余地。
''',
      );

      expect(
        service.shouldAutoSave(
          result: result,
          activeDocumentPath: 'chapters/chapter_01.md',
          wasModeGuidanceActive: false,
        ),
        isTrue,
      );
    });

    test(
      'does not autosave chapter-like reply when no content document is open',
      () {
        final result = _result(
          userPrompt: '直接写第一章正文。',
          draftMarkdown: '''
雨下得很密，像有人把整座城的光都揉进了水里。

林述站在桥边，没有立刻往前走。他听见远处列车的轰鸣，又听见脚下河水撞向护栏的碎响。

这一夜像是某种漫长的前奏，而他知道，自己已经没有回头的余地。
''',
        );

        expect(
          service.shouldAutoSave(
            result: result,
            activeDocumentPath: '',
            wasModeGuidanceActive: false,
          ),
          isFalse,
        );
      },
    );

    test(
      'does not autosave session-style planning reply into markdown file',
      () {
        final result = _result(
          userPrompt: '我先补充一下背景设定，主角是个社畜，先别写正文。',
          draftMarkdown: '''
主角原本在城市里做最普通的外包工作，长期被时间表和绩效压着走，所以他对秩序、效率和生存压力都特别敏感。

这会自然影响后面的世界观组织方式、他进入新环境后的第一反应，以及他看待权力、资源和安全感的角度。

如果继续往下推进，下一步更合适的是先把世界规则、主线冲突和人物边界收束清楚，再决定第一章从哪一个切口进入。
''',
        );

        expect(
          service.shouldAutoSave(
            result: result,
            activeDocumentPath: '',
            wasModeGuidanceActive: false,
          ),
          isFalse,
        );
      },
    );
  });
}

DraftGenerationResult _result({
  String userPrompt = '写点内容',
  required String draftMarkdown,
  bool waitingForUserChoice = false,
}) {
  return DraftGenerationResult(
    project: const ProjectDescriptor(
      id: 'demo',
      name: '示例项目',
      rootPath: 'D:/demo',
    ),
    projectInfo: const <String, Object?>{},
    userPrompt: userPrompt,
    prompt: 'prompt',
    modelId: 'demo-model',
    draftMarkdown: draftMarkdown,
    contextPack: const <String, Object?>{},
    selectedPaths: const <String>[],
    executedTools: const <Object?>[],
    writtenPaths: const <String>[],
    changedPaths: const <String>[],
    transcriptMessages: const <JsonMap>[],
    waitingForUserChoice: waitingForUserChoice,
    reasoningContent: '',
    stoppedByToolError: false,
    toolErrorSummary: '',
  );
}
