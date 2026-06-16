import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectToolPermissionApprovalRecordService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectToolPermissionApprovalRecordService service;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'tool-permission-approval-service-',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectToolPermissionApprovalRecordService(
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'persists pending permission approvals, restores by session, and consumes allow-once override exactly once',
      () async {
        final persisted = await service.persistPendingApprovalsForExecutedTools(
          project,
          scopeType: ProjectToolPermissionApprovalScopes.ordinaryConversation,
          sessionId: 'session_alpha',
          executedTools: <Object?>[
            <String, Object?>{
              'name': 'request_gateway_tool',
              'call_id': 'call_1',
              'result': <String, Object?>{
                'waiting_for_user_choice': true,
                'question': '是否允许联网搜索？',
                'options': <Object?>[
                  <String, Object?>{
                    'id': 'allow_once',
                    'label': '允许这次',
                    'prompt': '允许这次网络搜索',
                  },
                  <String, Object?>{
                    'id': 'deny_and_continue',
                    'label': '保持禁止',
                    'prompt': '保持禁止并继续',
                  },
                ],
                'permission_decision': <String, Object?>{
                  'disposition':
                      HostToolPermissionDispositions.needsUserConfirmation,
                  'required_capability':
                      HostToolPermissionPolicyService.capabilityNetwork,
                },
                'permission_capability':
                    HostToolPermissionPolicyService.capabilityNetwork,
                'permission_context': const HostToolPermissionContext(
                  allowRead: true,
                  allowWrite: true,
                  allowNetwork: false,
                  permissionMode: HostToolPermissionModes.safe,
                  confirmationMode:
                      HostToolConfirmationModes.userConfirmationRequired,
                  source: 'test.pending',
                ).toJson(),
              },
            },
          ],
        );

        final executedTools = ValueReaders.objectList(
          persisted['executed_tools'],
        );
        final decoratedResult = ValueReaders.mapValue(
          ValueReaders.mapValue(executedTools.single)['result'],
        );
        final decoratedOptions = ValueReaders.mapList(
          decoratedResult['options'],
        );
        final approvalId = ValueReaders.stringValue(
          decoratedResult['permission_approval_id'],
        );

        expect(approvalId.trim(), isNotEmpty);
        expect(
          ValueReaders.stringValue(
            decoratedOptions.first['approval_record_id'],
          ),
          approvalId,
        );

        final pendingRecords = await service.listPending(
          project,
          scopeType: ProjectToolPermissionApprovalScopes.ordinaryConversation,
          sessionId: 'session_alpha',
        );
        expect(pendingRecords, hasLength(1));

        final restoredOptions = service.pendingOptionsForRecords(
          pendingRecords,
        );
        expect(restoredOptions, hasLength(2));
        expect(
          ValueReaders.stringValue(restoredOptions.first['approval_option_id']),
          'allow_once',
        );

        final resolved = await service.resolveSelection(
          project,
          approvalId: approvalId,
          optionId: 'allow_once',
        );
        expect(ValueReaders.boolValue(resolved['ok']), isTrue);
        expect(
          ValueReaders.stringValue(resolved['selected_option_kind']),
          ProjectToolPermissionApprovalOptionKinds.allowOnce,
        );

        final consumed = await service.consumeResolvedOverrideContext(
          project,
          approvalId: approvalId,
        );
        expect(ValueReaders.boolValue(consumed['ok']), isTrue);
        expect(
          ValueReaders.stringValue(consumed['action_status']),
          'override_ready',
        );
        final overrideContext = HostToolPermissionContext.fromJson(
          ValueReaders.mapValue(consumed['host_tool_permission_context']),
        );
        expect(overrideContext.allowNetwork, isTrue);
        expect(overrideContext.allowWrite, isTrue);

        final consumedAgain = await service.consumeResolvedOverrideContext(
          project,
          approvalId: approvalId,
        );
        expect(ValueReaders.boolValue(consumedAgain['ok']), isTrue);
        expect(
          ValueReaders.stringValue(consumedAgain['action_status']),
          'already_consumed',
        );
      },
    );
  });
}
