import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_core/src/agents/sub_agent_effective_execution_profile_service.dart';
import 'package:test/test.dart';

void main() {
  group('SubAgentEffectiveExecutionProfileService', () {
    test(
      'uses shared runtime default candidate tools when child agent declares no allowed tools',
      () {
        final service = SubAgentEffectiveExecutionProfileService();

        final resolved = service.resolve(
          package: <String, Object?>{
            'child_run_package': <String, Object?>{
              'package_id': 'pkg_child_001',
              'execution_package_id': 'exec_pkg_001',
              'sub_session_id': 'sub_session_001',
              'continue_session_id': 'sub_session_001',
              'agent_id': 'reviewer',
              'agent_name': '审稿智能体',
              'agent_role': 'reviewer',
              'goal': const <String, Object?>{'summary': '请审稿'},
              'context': const <String, Object?>{
                'summary': 'review task context',
              },
              'skill_loadout': const <String, Object?>{
                'strategy': 'inherit',
              },
              'permission_policy': const <String, Object?>{
                'allowed_tool_ids': <Object?>[],
                'blocked_tool_ids': <Object?>[],
                'allow_formal_delivery': false,
                'allow_recursive_delegation': false,
                'allow_user_questions': false,
                'allow_long_task_control': false,
              },
              'model_policy': const <String, Object?>{
                'provider_profile': 'default',
              },
              'budget_policy': const <String, Object?>{
                'max_concurrent_children': 1,
                'token_budget': 0,
                'max_retry_count': 0,
                'max_tool_rounds': 1,
                'timeout_seconds': 30,
                'context_budget_chars': 0,
                'output_budget_chars': 0,
                'source_path_count': 0,
              },
              'failure_policy': const <String, Object?>{
                'on_tool_error': 'return_partial',
                'on_waiting_user': 'return_partial',
                'on_model_failure': 'return_partial',
                'on_timeout': 'return_partial',
                'on_empty_result': 'return_partial',
                'on_budget_exceeded': 'return_partial',
              },
              'messages': const <Object?>[
                <String, Object?>{'role': 'user', 'content': '请审稿。'},
              ],
              'response_contract': 'return_summary',
            },
          },
          childAgent: const <String, Object?>{
            'id': 'reviewer',
            'name': '审稿智能体',
          },
          mainContext: const <String, Object?>{
            'intent': 'workflow_task',
            'task_type': 'review',
            'continuous_task_family_id':
                ContinuousTaskFamilies.longFormWriting,
            'selected_collaboration_group': <String, Object?>{
              'id': 'review_room',
              'metadata': <String, Object?>{
                'tool_capability_family_ids': <String>[
                  ToolCapabilityFamilyCatalogService
                      .mountedReferenceConsumption,
                  ToolCapabilityFamilyCatalogService.review,
                ],
              },
            },
          },
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
            projectType: 'novel',
          ),
          hostPlatform: HostPlatform.windows,
          parentModelId: 'parent-model',
        );

        final allowedToolIds = ValueReaders.stringList(
          resolved['allowed_tool_ids'],
        );
        final resolution = ValueReaders.mapValue(
          resolved['continuous_task_tool_exposure_resolution'],
        );

        expect(
          allowedToolIds,
          containsAll(const <String>[
            'submit_semantic_review',
            'read_project_file',
            'list_project_files',
          ]),
        );
        expect(
          allowedToolIds,
          isNot(contains('submit_chapter_delivery')),
        );
        expect(
          allowedToolIds,
          isNot(contains('submit_narrative_state_claims')),
        );
        expect(
          allowedToolIds,
          isNot(contains('request_external_research')),
        );
        expect(
          allowedToolIds,
          isNot(contains('present_user_options')),
        );
        expect(
          ValueReaders.stringList(
            resolution['default_allowed_tool_ids'],
          ),
          containsAll(const <String>[
            'submit_semantic_review',
            'read_project_file',
            'list_project_files',
          ]),
        );
      },
    );
  });
}
