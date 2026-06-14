import 'dart:io';

import 'package:test/test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectSessionWorkspaceService', () {
    test(
      'persists and reloads session records with active session id',
      () async {
        final workspacePort = LocalProjectWorkspacePort();
        final hostPort = ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        );
        final service = ProjectSessionWorkspaceService(hostPort: hostPort);
        final tempDirectory = await Directory.systemTemp.createTemp(
          'project_session_workspace_service_',
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

        await service.saveSessions(
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
              'context_messages': <Object?>[
                <String, Object?>{'role': 'user', 'content': '第一轮'},
              ],
              'compressed_context': '',
              'compression_count': 0,
              'compression_threshold_chars': 12000,
              'total_context_chars': 3,
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
              'context_messages': <Object?>[
                <String, Object?>{'role': 'assistant', 'content': '第二轮'},
              ],
              'compressed_context': '',
              'compression_count': 0,
              'compression_threshold_chars': 12000,
              'total_context_chars': 3,
              'created_at': '2026-06-14T00:01:00.000Z',
              'updated_at': '2026-06-14T00:01:01.000Z',
            },
          ],
          activeSessionId: 'session_b',
        );

        final snapshot = await service.loadSessions(project);

        expect(snapshot.activeSessionId, 'session_b');
        expect(
          snapshot.sessionRecords.map((record) => record['id']).toList(),
          <Object?>['session_b', 'session_a'],
        );
        expect(
          ValueReaders.objectList(
            snapshot.sessionRecords.first['context_messages'],
          ).single,
          <String, Object?>{'role': 'assistant', 'content': '第二轮'},
        );
      },
    );
  });
}
