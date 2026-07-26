import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSessionShellService', () {
    test(
      'lists, loads and stats sessions from the shared workspace contract',
      () async {
        // 中文注释: 这里验证 CLI 共享 session shell 直接消费工作区会话索引，而不是在 shell 层自己发明会话存储。
        final workspacePort = LocalProjectWorkspacePort();
        final hostPort = ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        );
        final sessionWorkspaceService = ProjectSessionWorkspaceService(
          hostPort: hostPort,
        );
        final shellService = ProjectSessionShellService(
          sessionWorkspaceService: sessionWorkspaceService,
        );
        final tempDirectory = await Directory.systemTemp.createTemp(
          'project_session_shell_service_list_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        final project = ProjectDescriptor(
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
              'mode': SessionRecordConstants.modeContinueWriting,
              'workflow_stage': 'draft',
              'public_status': '继续写作',
              'needs_goal_selection': false,
              'is_creative': true,
              'working_context_messages': <Object?>[
                <String, Object?>{'role': 'user', 'content': '第一轮正文'},
              ],
              'created_at': '2026-06-14T00:00:00.000Z',
              'updated_at': '2026-06-14T00:00:01.000Z',
            },
            <String, Object?>{
              'id': 'session_b',
              'title': '会话 B',
              'mode': SessionRecordConstants.modeContinueWriting,
              'workflow_stage': 'draft',
              'public_status': '继续写作',
              'needs_goal_selection': false,
              'is_creative': true,
              'working_context_messages': <Object?>[
                <String, Object?>{'role': 'assistant', 'content': '第二轮正文'},
              ],
              'created_at': '2026-06-14T00:01:00.000Z',
              'updated_at': '2026-06-14T00:01:01.000Z',
            },
          ],
          activeSessionId: 'session_b',
        );

        final listResult = await shellService.listSessions(project, limit: 1);
        final loadResult = await shellService.loadSession(project, 'session_a');
        final statsResult = await shellService.statsSession(
          project,
          'session_a',
        );

        expect(ValueReaders.boolValue(listResult['ok']), isTrue);
        expect(listResult['current_session_id'], 'session_b');
        expect(ValueReaders.objectList(listResult['sessions']), hasLength(1));
        expect(ValueReaders.boolValue(loadResult['ok']), isTrue);
        expect(loadResult['session_id'], 'session_a');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(loadResult['session_record'])['title'],
          ),
          '会话 A',
        );
        expect(loadResult['context_markdown'], contains('第一轮正文'));
        expect(ValueReaders.boolValue(statsResult['ok']), isTrue);
        expect(statsResult['public_summary'], contains('压力'));
        expect(statsResult['pressure_snapshot'], isA<JsonMap>());
      },
    );

    test(
      'send compact and stop all persist back into the same session store',
      () async {
        // 中文注释: 这条回归验证 send / compact / stop 都只修改正式 session 文件，不会让 shell 自己持有一份临时状态。
        final workspacePort = LocalProjectWorkspacePort();
        final hostPort = ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        );
        final sessionWorkspaceService = ProjectSessionWorkspaceService(
          hostPort: hostPort,
        );
        final shellService = ProjectSessionShellService(
          sessionWorkspaceService: sessionWorkspaceService,
        );
        final tempDirectory = await Directory.systemTemp.createTemp(
          'project_session_shell_service_send_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        final project = ProjectDescriptor(
          id: 'project',
          name: '测试项目',
          rootPath: tempDirectory.path,
          projectType: 'novel',
        );
        final longMessages = List<Object?>.generate(
          8,
          (index) => <String, Object?>{
            'role': index.isEven ? 'user' : 'assistant',
            'content': '很长的正文内容 ${'x' * 160} $index',
          },
        );

        await sessionWorkspaceService.saveSession(project, <String, Object?>{
          'id': 'session_send',
          'title': '发送会话',
          'mode': SessionRecordConstants.modeContinueWriting,
          'workflow_stage': 'draft',
          'public_status': '继续写作',
          'needs_goal_selection': false,
          'is_creative': true,
          'working_context_messages': longMessages,
          'created_at': '2026-06-14T00:02:00.000Z',
          'updated_at': '2026-06-14T00:02:01.000Z',
        });

        final sendResult = await shellService.sendSession(
          project,
          'session_send',
          '继续推进下一段。',
          settings: SessionTokenBudgetSettings(
            modelContextWindowTokens: 800,
            reservedOutputTokens: 80,
            warningThresholdRatio: 0.4,
            criticalThresholdRatio: 0.6,
          ),
        );
        final compactResult = await shellService.compactSession(
          project,
          'session_send',
          settings: SessionTokenBudgetSettings(
            modelContextWindowTokens: 800,
            reservedOutputTokens: 80,
            warningThresholdRatio: 0.4,
            criticalThresholdRatio: 0.6,
          ),
        );
        final stopResult = await shellService.stopSession(
          project,
          'session_send',
        );
        final storedAfterStop = await sessionWorkspaceService.loadSession(
          project,
          'session_send',
        );

        expect(ValueReaders.boolValue(sendResult['ok']), isTrue);
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              sendResult['compaction_decision'],
            )['should_compact'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.objectList(
            ValueReaders.mapValue(
              sendResult['session_prompt_context'],
            )['history_messages'],
          ),
          isNotEmpty,
        );
        expect(ValueReaders.boolValue(compactResult['ok']), isTrue);
        expect(
          ValueReaders.intValue(compactResult['working_message_count']),
          lessThan(
            ValueReaders.intValue(compactResult['transcript_message_count']),
          ),
        );
        expect(ValueReaders.boolValue(stopResult['ok']), isTrue);
        expect(
          ValueReaders.stringValue(stopResult['workflow_stage']),
          'stopped',
        );
        expect(ValueReaders.stringValue(stopResult['public_status']), '已停止');
        expect(
          ValueReaders.stringValue(storedAfterStop['public_status']),
          '已停止',
        );
      },
    );

    test(
      'resume reopens the active stopped session and returns the shared prompt context',
      () async {
        // 中文注释: resume 只应恢复共享 session 合同里的可继续状态，并把当前 active session 重新投影回索引。
        final workspacePort = LocalProjectWorkspacePort();
        final hostPort = ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        );
        final sessionWorkspaceService = ProjectSessionWorkspaceService(
          hostPort: hostPort,
        );
        final shellService = ProjectSessionShellService(
          sessionWorkspaceService: sessionWorkspaceService,
        );
        final tempDirectory = await Directory.systemTemp.createTemp(
          'project_session_shell_service_resume_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        final project = ProjectDescriptor(
          id: 'project',
          name: '测试项目',
          rootPath: tempDirectory.path,
          projectType: 'novel',
        );

        await sessionWorkspaceService.saveSessions(
          project,
          sessionRecords: const <JsonMap>[
            <String, Object?>{
              'id': 'session_resume',
              'title': '会话恢复',
              'mode': SessionRecordConstants.modeContinueWriting,
              'workflow_stage': 'stopped',
              'public_status': '已停止',
              'needs_goal_selection': false,
              'is_creative': true,
              'working_context_messages': <Object?>[
                <String, Object?>{'role': 'user', 'content': '继续写作的起点'},
              ],
              'created_at': '2026-06-14T00:03:00.000Z',
              'updated_at': '2026-06-14T00:03:01.000Z',
            },
          ],
          activeSessionId: 'session_resume',
        );

        final resumeResult = await shellService.resumeSession(project);
        final storedAfterResume = await sessionWorkspaceService.loadSession(
          project,
          'session_resume',
        );
        final snapshotAfterResume = await sessionWorkspaceService.loadSessions(
          project,
        );

        expect(ValueReaders.boolValue(resumeResult['ok']), isTrue);
        expect(
          ValueReaders.stringValue(resumeResult['resume_source']),
          'active_session',
        );
        expect(
          ValueReaders.stringValue(resumeResult['workflow_stage']),
          'draft',
        );
        expect(
          ValueReaders.stringValue(resumeResult['public_status']),
          '创作已启动',
        );
        expect(
          ValueReaders.stringValue(resumeResult['context_markdown']),
          contains('继续写作的起点'),
        );
        expect(
          ValueReaders.stringValue(storedAfterResume['workflow_stage']),
          'draft',
        );
        expect(
          ValueReaders.stringValue(storedAfterResume['public_status']),
          '创作已启动',
        );
        expect(snapshotAfterResume.activeSessionId, 'session_resume');
      },
    );
  });
}
