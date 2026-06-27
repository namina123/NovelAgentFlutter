import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

/// 端到端验证 CLI 侧命令后端把 core 命令动作接通到 ProjectSessionShellService 的真实持久化。
void main() {
  group('ProjectSessionShellCommandBackend', () {
    late ProjectSessionShellService shellService;
    late ProjectSessionWorkspaceService sessionWorkspaceService;
    late ProjectDescriptor project;
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'shell_command_backend_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      final hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      sessionWorkspaceService = ProjectSessionWorkspaceService(
        hostPort: hostPort,
      );
      shellService = ProjectSessionShellService(
        sessionWorkspaceService: sessionWorkspaceService,
      );
      project = ProjectDescriptor(
        id: 'project',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
      await sessionWorkspaceService.saveSessions(
        project,
        sessionRecords: const <JsonMap>[
          <String, Object?>{
            'id': 'session_a',
            'title': '会话 A',
            'mode': SessionRecordConstants.modeSmartOpening,
            'workflow_stage': 'draft',
            'public_status': '智能开局',
            'needs_goal_selection': false,
            'is_creative': false,
            'working_context_messages': <Object?>[
              <String, Object?>{'role': 'user', 'content': '第一轮'},
              <String, Object?>{'role': 'assistant', 'content': '第二轮'},
            ],
            'created_at': '2026-06-14T00:00:00.000Z',
            'updated_at': '2026-06-14T00:00:01.000Z',
          },
        ],
        activeSessionId: 'session_a',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    ProjectSessionShellCommandBackend backend() =>
        ProjectSessionShellCommandBackend(
          shellService: shellService,
          project: project,
          sessionId: 'session_a',
        );

    test('stats is read-only and surfaces pressure snapshot', () async {
      final outcome = await backend().stats(const <String, Object?>{
        'id': 'session_a',
      });
      expect(outcome.persist, isFalse);
      expect(
        outcome.detail?['pressure_snapshot'],
        isA<Map<String, Object?>>(),
      );
      expect(
        ValueReaders.stringValue(outcome.detail?['public_summary']),
        contains('压力'),
      );
    });

    test('compact persists and carries compaction decision', () async {
      final outcome = await backend().compact(const <String, Object?>{
        'id': 'session_a',
      });
      expect(outcome.persist, isTrue);
      expect(
        outcome.detail?['compaction_decision'],
        isA<Map<String, Object?>>(),
      );
    });

    test('setMode persists mode change', () async {
      final outcome = await backend().setMode(
        const <String, Object?>{'id': 'session_a'},
        SessionRecordConstants.modeContinueWriting,
      );
      expect(outcome.persist, isTrue);
      expect(
        ValueReaders.stringValue(outcome.updatedSessionRecord['mode']),
        SessionRecordConstants.modeContinueWriting,
      );
    });

    test('setGoalText persists free-text goal', () async {
      final outcome = await backend().setGoalText(
        const <String, Object?>{'id': 'session_a'},
        '收束第三章伏笔',
      );
      expect(outcome.persist, isTrue);
      expect(
        ValueReaders.stringValue(
          outcome.updatedSessionRecord[SessionRecordConstants.conversationGoalField],
        ),
        '收束第三章伏笔',
      );
      // 中文注释: 自由目标写入后应能从磁盘重新加载读到，验证真正持久化而非仅在内存。
      final reloaded = await shellService.loadSession(project, 'session_a');
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(reloaded['session_record'])[SessionRecordConstants.conversationGoalField],
        ),
        '收束第三章伏笔',
      );
    });

    test('clearContext empties working context and persists', () async {
      final outcome = await backend().clearContext(const <String, Object?>{
        'id': 'session_a',
      });
      expect(outcome.persist, isTrue);
      expect(
        ValueReaders.objectList(
          outcome.updatedSessionRecord[SessionRecordConstants.workingContextMessagesField],
        ),
        isEmpty,
      );
    });

    test('exitSession signals exit without persisting', () async {
      final outcome = await backend().exitSession(const <String, Object?>{
        'id': 'session_a',
        'mode': 'smart_opening',
      });
      expect(outcome.exitSession, isTrue);
      expect(outcome.persist, isFalse);
      expect(
        ValueReaders.stringValue(outcome.updatedSessionRecord['mode']),
        'smart_opening',
      );
    });
  });
}
