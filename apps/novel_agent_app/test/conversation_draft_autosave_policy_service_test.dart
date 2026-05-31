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
  });
}

DraftGenerationResult _result({
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
    userPrompt: '写点内容',
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
