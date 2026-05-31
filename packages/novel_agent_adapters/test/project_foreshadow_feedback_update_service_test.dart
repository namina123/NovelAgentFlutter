import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectForeshadowFeedbackUpdateService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectForeshadowStateUpdateService foreshadowStateService;
    late ProjectForeshadowFeedbackUpdateService feedbackUpdateService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_foreshadow_feedback_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      final hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      foreshadowStateService = ProjectForeshadowStateUpdateService(
        hostPort: hostPort,
      );
      feedbackUpdateService = ProjectForeshadowFeedbackUpdateService(
        hostPort: hostPort,
      );
      project = ProjectDescriptor(
        id: 'foreshadow_feedback_project',
        name: '伏笔反馈测试',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('applies review report feedback back into foreshadow asset', () async {
      await foreshadowStateService.updateForeshadowState(
        project,
        const <String, Object?>{
          'title': '塔楼密钥',
          'status': 'planted',
          'summary': '主角得到一把可疑的钥匙。',
        },
      );

      final changedPaths = await feedbackUpdateService.applyReviewReport(
        project,
        const <String, Object?>{
          'review_type': 'continuity',
          'issues': <Object?>[
            <String, Object?>{
              'title': '伏笔应尽快回收',
              'detail': '塔楼密钥已经进入兑现阶段。',
              'suggestion': '下一章要推进回收。',
              'related_foreshadow_ids': <Object?>['塔楼密钥'],
            },
          ],
        },
      );

      expect(changedPaths, contains('assets/foreshadows/塔楼密钥.foreshadow.md'));
      final file = File(
        '${tempDirectory.path}\\assets\\foreshadows\\塔楼密钥.foreshadow.md',
      );
      final content = await file.readAsString();
      expect(content, contains('pending_payoff'));
    });
  });
}
