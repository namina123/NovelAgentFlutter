import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Sub-agent package contracts', () {
    final runPackageService = SubAgentRunPackageService();
    final resultPackageService = SubAgentResultPackageService();
    final normalizer = WritingExecutionResultNormalizerService();

    test('builds single-member execution and child run packages', () {
      final package = runPackageService.buildSubAgentRunPackage(
        _singleMemberGroup,
        <Object?>[_writerAgent],
        const <String, Object?>{
          'task': '补一段紧张追逐戏。',
          'context_excerpt': '主角在钟楼外被追兵堵到雨夜巷口。',
          'source_paths': <String>['chapters/ch01.md'],
        },
        mainContext: const <String, Object?>{
          'project_title': '测试项目',
          'intent': 'draft',
          'sub_agent_max_tool_rounds': 2,
        },
        parentAgent: const <String, Object?>{
          'id': 'main_writer',
          'name': '主写手',
        },
        parentModelId: 'parent-model',
        createdAt: '2026-06-05T12:00:00Z',
      );

      final execution = ExecutionPackage.fromJson(
        ValueReaders.mapValue(package['execution_package']),
      );
      final child = ChildRunPackage.fromJson(
        ValueReaders.mapValue(package['child_run_package']),
      );

      expect(ValueReaders.boolValue(package['ok']), isTrue);
      expect(execution.validateBasics(), isEmpty);
      expect(child.validateBasics(), isEmpty);
      expect(execution.children, hasLength(1));
      expect(execution.children.single.selected, isTrue);
      expect(child.permissionPolicy.allowFormalDelivery, isFalse);
      expect(
        child.permissionPolicy.blockedToolIds,
        containsAll(<String>[
          'call_sub_agent',
          'present_user_options',
          'submit_chapter_delivery',
        ]),
      );
      expect(child.modelPolicy.requestedModelId, 'parent-model');
      expect(child.budgetPolicy.maxConcurrentChildren, 1);
      expect(child.budgetPolicy.maxRetryCount, 1);
      expect(child.budgetPolicy.timeoutSeconds, 45);
      expect(
        child.skillLoadout.finalSkillIds,
        contains('chapter_drafting_method'),
      );
      expect(child.skillLoadout.finalSkillGroupIds, contains('project_io'));
    });

    test(
      'builds multi-member execution package while selecting one child run',
      () {
        final package = runPackageService.buildSubAgentRunPackage(
          _multiMemberGroup,
          <Object?>[_writerAgent, _reviewerAgent],
          const <String, Object?>{
            'agent_id': 'reviewer',
            'task': '检查第一章冲突入口是否足够快。',
            'context_excerpt': '第一章开头仍然偏慢，需要更快把威胁推到台前。',
          },
          mainContext: const <String, Object?>{
            'project_title': '测试项目',
            'intent': 'review',
          },
          parentAgent: const <String, Object?>{
            'id': 'main_writer',
            'name': '主写手',
          },
          createdAt: '2026-06-05T12:00:00Z',
        );

        final execution = ExecutionPackage.fromJson(
          ValueReaders.mapValue(package['execution_package']),
        );
        final child = ChildRunPackage.fromJson(
          ValueReaders.mapValue(package['child_run_package']),
        );

        expect(execution.children, hasLength(2));
        expect(
          execution.children.map((entry) => entry.agentId),
          containsAll(<String>['writer', 'reviewer']),
        );
        expect(
          execution.children
              .singleWhere((entry) => entry.agentId == 'reviewer')
              .selected,
          isTrue,
        );
        expect(
          execution.children
              .singleWhere((entry) => entry.agentId == 'writer')
              .selected,
          isFalse,
        );
        expect(child.agentId, 'reviewer');
        expect(child.executionPackageId, execution.packageId);
        expect(execution.metadata['selected_agent_id'], 'reviewer');
      },
    );

    test(
      'keeps child context isolated and exposes collaboration result package to shared writing result',
      () {
        final package = runPackageService.buildSubAgentRunPackage(
          _singleMemberGroup,
          <Object?>[_writerAgent],
          const <String, Object?>{
            'task': '整理本章可用的压迫感细节。',
            'context_excerpt': '只看钟楼雨夜追逐这一段。',
            'source_paths': <String>['chapters/ch01.md'],
          },
          mainContext: const <String, Object?>{
            'project_title': '测试项目',
            'intent': 'draft',
            'private_transcript': 'SECRET_MAIN_TRANSCRIPT',
            'full_conversation': '用户私聊全文',
          },
          createdAt: '2026-06-05T12:00:00Z',
        );
        final child = ChildRunPackage.fromJson(
          ValueReaders.mapValue(package['child_run_package']),
        );
        final messageText = child.messages
            .map((entry) => ValueReaders.stringValue(entry['content']))
            .join('\n');
        final subResult = resultPackageService.subAgentSuccessResultPackage(
          package: package,
          task: '整理本章可用的压迫感细节。',
          content: '建议把雨声、呼吸和脚步回音一起压上来。',
          llmResult: const <String, Object?>{},
          executedTools: const <Object?>[
            <String, Object?>{'name': 'read_project_file'},
          ],
        );
        final collaborationPackage = CollaborationResultPackage.fromJson(
          ValueReaders.mapValue(subResult['collaboration_result_package']),
        );
        final writingExecutionResult = normalizer.normalize(
          executionId: 'collab_contract_001',
          workflowKind: 'ordinary_project',
          collaborationResults: <Object?>[subResult],
        );

        expect(child.context.includeFullMainConversation, isFalse);
        expect(child.context.includeParentMessages, isFalse);
        expect(messageText, contains('只看钟楼雨夜追逐这一段。'));
        expect(messageText, isNot(contains('SECRET_MAIN_TRANSCRIPT')));
        expect(messageText, isNot(contains('用户私聊全文')));
        expect(collaborationPackage.validateBasics(), isEmpty);
        expect(
          collaborationPackage.mergeContract.allowsDirectDelivery,
          isFalse,
        );
        expect(
          collaborationPackage.mergeContract.relationToWritingExecutionResult,
          'consumed_by_writing_execution_collaboration_summary',
        );
        expect(
          writingExecutionResult
              .collaboration
              .collaborators
              .single
              .metadata['execution_package_id'],
          collaborationPackage.executionPackageId,
        );
        expect(
          writingExecutionResult
              .collaboration
              .metadata['result_package_relation'],
          'derived_from_collaboration_result_package',
        );
      },
    );

    test(
      'shared writing result exposes collaboration failure summary and dispositions',
      () {
        final package = runPackageService.buildSubAgentRunPackage(
          _singleMemberGroup,
          <Object?>[_writerAgent],
          const <String, Object?>{
            'task': '补充失败摘要。',
            'context_excerpt': '只需要协作失败摘要。',
          },
          mainContext: const <String, Object?>{
            'project_title': '测试项目',
            'intent': 'draft',
          },
          createdAt: '2026-06-05T12:00:00Z',
        );
        final retryFailure = resultPackageService.subAgentFailureResultPackage(
          package: package,
          errorDetail: '审稿子链超时。',
          executedTools: const <Object?>[],
          cancelled: false,
          failureDisposition: ChildFailureDispositions.retryChild,
          failureCategory: 'timeout',
        );
        final degradedFailure = resultPackageService
            .subAgentFailureResultPackage(
              package: package,
              errorDetail: '资料子链预算耗尽。',
              executedTools: const <Object?>[],
              cancelled: false,
              failureDisposition: ChildFailureDispositions.fallbackSingleMain,
              failureCategory: 'budget_exhausted',
            );
        final writingExecutionResult = normalizer.normalize(
          executionId: 'collab_contract_002',
          workflowKind: 'ordinary_project',
          collaborationResults: <Object?>[retryFailure, degradedFailure],
        );

        expect(writingExecutionResult.collaboration.failedCollaboratorCount, 2);
        expect(writingExecutionResult.collaboration.blockingFailureCount, 1);
        expect(writingExecutionResult.collaboration.retryChildCount, 1);
        expect(writingExecutionResult.collaboration.fallbackSingleMainCount, 1);
        expect(
          writingExecutionResult.collaboration.failureSummary,
          contains('建议局部重试'),
        );
        expect(
          writingExecutionResult.collaboration.failureSummary,
          contains('建议退回单主链继续'),
        );
      },
    );

    test(
      'records structured collaboration conflict and arbitration contract',
      () {
        final package = runPackageService.buildSubAgentRunPackage(
          _multiMemberGroup,
          <Object?>[_writerAgent, _reviewerAgent],
          const <String, Object?>{
            'agent_id': 'reviewer',
            'task': '检查连续性冲突。',
            'context_excerpt': '审稿意见与既有连续性规则存在冲突。',
          },
          mainContext: const <String, Object?>{
            'project_title': '测试项目',
            'intent': 'review',
          },
          createdAt: '2026-06-05T12:00:00Z',
        );
        final result = resultPackageService.subAgentSuccessResultPackage(
          package: package,
          task: '检查连续性冲突。',
          content: '建议不要直接改写世界规则，先让主链判断采纳方向。',
          llmResult: const <String, Object?>{},
          executedTools: const <Object?>[],
          metadata: const <String, Object?>{
            'collaboration_conflicts': <Object?>[
              <String, Object?>{
                'group_key': 'continuity_opening_hook',
                'subject': '开篇是否提前揭露世界规则',
                'target': 'continuity_state',
                'risk': 'medium',
                'suggestion': '延后揭露世界规则，保留当前章节悬念。',
                'adoption_hint': 'repair_before_merge',
                'confidence': 0.86,
                'evidence': <Object?>[
                  <String, Object?>{
                    'kind': 'continuity_claim',
                    'summary': '现有连续性要求第一章不要显式揭露轮回机制。',
                    'reference':
                        '.novel_agent/continuity/reviews/review_001.json',
                  },
                ],
              },
            ],
          },
        );

        final packageJson = ValueReaders.mapValue(
          result['collaboration_result_package'],
        );
        final collaborationPackage = CollaborationResultPackage.fromJson(
          packageJson,
        );
        expect(collaborationPackage.validateBasics(), isEmpty);
        expect(collaborationPackage.conflicts, hasLength(1));
        expect(collaborationPackage.conflicts.single.risk, 'medium');
        expect(
          collaborationPackage.conflicts.single.adoptionHint,
          'repair_before_merge',
        );
        expect(
          collaborationPackage.arbitrationResult.status,
          CollaborationArbitrationStatuses.needsRepair,
        );
        expect(
          ValueReaders.mapList(
            result['collaboration_conflicts'],
          ).single['risk'],
          'medium',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['collaboration_arbitration_result'],
            )['status'],
          ),
          CollaborationArbitrationStatuses.needsRepair,
        );
      },
    );
  });
}

const JsonMap _writerAgent = <String, Object?>{
  'id': 'writer',
  'name': '正文智能体',
  'role': '作者',
  'skills': <String>['chapter_drafting_method'],
  'skill_groups': <String>['project_io'],
  'provider_profile': 'writer-provider',
  'thinking_supported': true,
  'thinking_enabled': true,
  'thinking_effort': 'medium',
};

const JsonMap _reviewerAgent = <String, Object?>{
  'id': 'reviewer',
  'name': '审稿智能体',
  'role': '审稿',
  'skills': <String>['review_only_skill'],
  'skill_groups': <String>['project_review'],
  'provider_profile': 'reviewer-provider',
  'thinking_supported': true,
  'thinking_enabled': false,
  'thinking_effort': 'low',
};

const JsonMap _singleMemberGroup = <String, Object?>{
  'id': 'solo_room',
  'name': '单人室',
  'orchestration': 'supervised',
  'agents': <String>['writer'],
};

const JsonMap _multiMemberGroup = <String, Object?>{
  'id': 'review_room',
  'name': '审稿室',
  'orchestration': 'supervised',
  'agents': <String>['writer', 'reviewer'],
};
