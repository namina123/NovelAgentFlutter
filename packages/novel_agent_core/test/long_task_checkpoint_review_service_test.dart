import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointReviewService', () {
    test('merges surface expression risk evidence into checkpoint signal', () {
      final service = LongTaskCheckpointReviewService(
        taskSummaryService: LongTaskTaskSummaryService(),
      );

      final review = service.buildReview(
        task: <String, Object?>{
          'id': 'chapter_001',
          'title': '第01章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'output_paths': <Object?>['chapters/ch01.md'],
          'metadata': <String, Object?>{'stage': 'draft'},
        },
        result: <String, Object?>{
          'ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'expression_constraint_surface_review': <String, Object?>{
            'authenticity_pass_level': 'aggressive',
            'mini_recheck_items': <Object?>['正文表面风险命中：去 AI 风：—— x6'],
          },
        },
        memorySections: const <JsonMap>[],
        outputPaths: const <String>['chapters/ch01.md'],
        execution: <String, Object?>{
          'execution_constraints': <String, Object?>{
            'expression_constraint_policy_mode': 'force',
            'expression_constraint_injection_strength': 'full',
            'expression_constraint_review_requirement': 'none',
            'expression_constraint_violation_disposition': 'repair',
            'expression_constraint_applied': true,
            'expression_constraint_injection_mode': 'brief_and_sections',
            'expression_constraint_profiles': <Object?>[
              <String, Object?>{
                'id': 'de_ai',
                'display_name': '去 AI 风',
                'summary': '降低模板化表达和解释腔。',
                'kind': 'natural_expression',
                'risk_signals': <Object?>['——'],
              },
            ],
            'project_expression_constraint_bindings': <Object?>[
              <String, Object?>{
                'id': 'binding_de_ai',
                'profile_id': 'de_ai',
                'default_for_project': true,
              },
            ],
          },
        },
      );

      final expressionReview = ValueReaders.mapValue(
        review['expression_constraint_review'],
      );
      final signal = ValueReaders.mapValue(
        review['expression_constraint_signal'],
      );
      expect(
        ValueReaders.stringList(expressionReview['mini_recheck_items']),
        contains('正文表面风险命中：去 AI 风：—— x6'),
      );
      expect(ValueReaders.stringValue(signal['category']), 'light_repair');
      expect(ValueReaders.boolValue(signal['repair_required']), isTrue);
      expect(
        ValueReaders.stringList(signal['risk_signals']),
        contains('正文表面风险命中：去 AI 风：—— x6'),
      );
    });

    test('builds checkpoint review with drift watch items and next actions', () {
      final service = LongTaskCheckpointReviewService(
        taskSummaryService: LongTaskTaskSummaryService(),
      );

      final review = service.buildReview(
        task: <String, Object?>{
          'id': 'chapter_001',
          'title': '样章：第01章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'output_paths': <Object?>['chapters/ch01.md'],
          'metadata': <String, Object?>{
            'stage': 'sample',
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
          },
        },
        result: <String, Object?>{
          'ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'changed_paths': <Object?>[
            'chapters/ch01.md',
            '.novel_agent/information/research_requests/research_request_writer_1.json',
          ],
          'executed_tools': <Object?>[
            <String, Object?>{
              'name': 'request_external_research',
              'result': <String, Object?>{
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'accepted',
                  'outcome_payload': <String, Object?>{
                    'request_registered': true,
                    'network_execution_performed': false,
                    'research_request': <String, Object?>{'query': '雾潮城历史母题'},
                  },
                },
              },
            },
          ],
          'chapter_length_evaluation': <String, Object?>{
            'current_length': 3100,
            'target_length': 2200,
            'preferred_min': 1800,
            'preferred_max': 2600,
            'level': 'needs_rebalance',
            'recommended_action': 'adjust_next_chapter',
            'notes': <Object?>[
              '当前章约 3100 字，目标基准约 2200 字。',
              '偏离尚可消化，建议在下一章优先回调分布，避免继续越拉越开。',
            ],
          },
          'response': <String, Object?>{
            'content': '已写出样章。',
            'tool_calls': <Object?>[
              <String, Object?>{'name': 'write_project_file'},
            ],
          },
        },
        memorySections: const <JsonMap>[
          <String, Object?>{'title': '风格锚点'},
          <String, Object?>{'title': '世界硬约束'},
          <String, Object?>{'title': '角色/身份锚点'},
        ],
        outputPaths: const <String>['chapters/ch01.md'],
        execution: <String, Object?>{
          'execution_constraints': <String, Object?>{
            'expression_constraint_policy_mode': 'adaptive',
            'expression_constraint_injection_strength': 'sections',
            'expression_constraint_review_requirement': 'when_applied',
            'expression_constraint_violation_disposition': 'adjust_next',
            'expression_constraint_applied': true,
            'expression_constraint_runtime_escalated': true,
            'expression_constraint_injection_mode': 'brief_and_sections',
            'expression_constraint_review_required': true,
            'expression_constraint_profiles': <Object?>[
              <String, Object?>{
                'id': 'de_ai',
                'display_name': '去 AI 风',
                'summary': '降低模板化表达和解释腔。',
                'kind': 'natural_expression',
              },
            ],
            'project_expression_constraint_bindings': <Object?>[
              <String, Object?>{
                'id': 'binding_de_ai',
                'profile_id': 'de_ai',
                'default_for_project': true,
              },
            ],
            'runtime_report': <String, Object?>{
              'expression_constraints': <String, Object?>{
                'runtime_escalated': true,
              },
            },
          },
          'activation_report': <String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'title': '轮回规则',
                'omitted': true,
                'metadata': <String, Object?>{
                  'source_kind': 'project_knowledge_card',
                  'required': true,
                },
              },
            ],
          },
          'context_pack': <String, Object?>{
            'creative_rule_stack': <String, Object?>{
              'expression_constraints': <Object?>[
                <String, Object?>{
                  'id': 'de_ai',
                  'display_name': '去 AI 风',
                  'summary': '降低模板化表达和解释腔。',
                  'kind': 'natural_expression',
                },
                <String, Object?>{
                  'id': 'strict_pov_boundary',
                  'display_name': '严格限知',
                  'summary': '严守 POV 信息边界。',
                  'kind': 'narrative_boundary',
                },
              ],
            },
          },
        },
        createdAt: '2026-05-25T08:00:00Z',
      );

      expect(
        ValueReaders.stringList(review['drift_watch_items']),
        containsAll(<String>['样章阶段要重点检查文风是否稳定、入口是否干净利落。', '视角泄漏', '信息边界混用']),
      );
      expect(
        ValueReaders.mapList(
          review['drift_signals'],
        ).map((item) => ValueReaders.stringValue(item['domain'])),
        containsAll(<String>['style', 'world', 'entity']),
      );
      expect(
        ValueReaders.stringList(review['confirmation_focus']),
        contains('样章入口是否成立，是否能证明题材钩子和叙事方式可持续。'),
      );
      expect(
        ValueReaders.stringList(review['next_actions']),
        contains('样章通过后，确认是否继续正文队列或先修订风格与大纲。'),
      );
      expect(
        ValueReaders.mapValue(review['chapter_length_evaluation'])['level'],
        'needs_rebalance',
      );
      expect(
        ValueReaders.stringList(review['next_actions']),
        contains('下一章优先按章节字数基准回调，避免与前后章节继续拉开差距。'),
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            review['expression_constraint_review'],
          )['authenticity_pass_level'],
        ),
        'medium',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(
              review['narrative_supervisor_risk'],
            )['overall'],
          )['category'],
        ),
        'repair',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(review['information_signal'])['category'],
        ),
        'repair',
      );
      expect(
        ValueReaders.stringList(review['information_changed_paths']),
        contains(
          '.novel_agent/information/research_requests/research_request_writer_1.json',
        ),
      );
      expect(
        ValueReaders.stringValue(review['information_summary']),
        contains('待研究 1 项'),
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            review['writing_execution_constraints'],
          )['policy_mode'],
        ),
        'adaptive',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            review['expression_constraint_signal'],
          )['category'],
        ),
        'suggest_strengthen',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(
              review['narrative_supervisor_risk'],
            )['expression_constraints'],
          )['category'],
        ),
        'suggest_strengthen',
      );
      expect(
        ValueReaders.stringList(review['mini_recheck_items']),
        contains('确认真实性清理后主角与关键说话者仍然保留各自声音。'),
      );
      final severity = LongTaskCheckpointSeverityService().assess(review);
      expect(ValueReaders.stringValue(severity['severity']), 'high');
    });

    test(
      'keeps disabled expression constraint signal out of repair classification',
      () {
        final service = LongTaskCheckpointReviewService(
          taskSummaryService: LongTaskTaskSummaryService(),
        );

        final review = service.buildReview(
          task: const <String, Object?>{
            'id': 'chapter_003',
            'title': '正文：第03章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusSucceeded,
            'output_paths': <Object?>['chapters/ch03.md'],
            'metadata': <String, Object?>{'stage': 'draft'},
          },
          result: const <String, Object?>{
            'ok': true,
            'output_paths': <Object?>['chapters/ch03.md'],
            'changed_paths': <Object?>['chapters/ch03.md'],
            'executed_tools': <Object?>[],
            'response': <String, Object?>{'content': '已完成正文草稿。'},
          },
          memorySections: const <JsonMap>[
            <String, Object?>{'title': '风格锚点'},
          ],
          outputPaths: const <String>['chapters/ch03.md'],
          execution: const <String, Object?>{
            'execution_constraints': <String, Object?>{
              'expression_constraint_policy_mode': 'disabled',
              'expression_constraint_injection_strength': 'none',
              'expression_constraint_review_requirement': 'none',
              'expression_constraint_violation_disposition': 'remind',
              'expression_constraint_applied': false,
              'expression_constraint_injection_mode': 'disabled',
              'expression_constraint_review_required': false,
              'runtime_report': <String, Object?>{},
            },
          },
          createdAt: '2026-06-06T01:00:00Z',
        );

        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              review['expression_constraint_signal'],
            )['category'],
          ),
          'policy_disabled',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                review['narrative_supervisor_risk'],
              )['overall'],
            )['category'],
          ),
          'accept',
        );
      },
    );

    test(
      'projects collaboration conflict into checkpoint review and blocks high-risk silent continue',
      () {
        final service = LongTaskCheckpointReviewService(
          taskSummaryService: LongTaskTaskSummaryService(),
        );

        final review = service.buildReview(
          task: <String, Object?>{
            'id': 'chapter_002',
            'title': '正文：第02章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusWaitingUser,
            'output_paths': <Object?>['chapters/ch02.md'],
            'metadata': const <String, Object?>{'stage': 'draft'},
          },
          result: <String, Object?>{
            'ok': true,
            'output_paths': <Object?>['chapters/ch02.md'],
            'writing_execution_result': <String, Object?>{
              'execution_id': 'writing_exec_conflict_001',
              'workflow_kind': 'long_task',
              'overall_status': 'user_action_required',
              'summary': '协作冲突：待用户确认 1 项',
              'delivery': const <String, Object?>{},
              'constraints': const <String, Object?>{},
              'information': const <String, Object?>{},
              'collaboration': <String, Object?>{
                'present': true,
                'strategy': 'main_with_children',
                'total_collaborator_count': 2,
                'successful_collaborator_count': 2,
                'failed_collaborator_count': 0,
                'blocking_failure_count': 0,
                'cancelled_collaborator_count': 0,
                'retryable_failure_count': 0,
                'retry_child_count': 0,
                'skip_child_count': 0,
                'fallback_single_main_count': 0,
                'require_user_count': 0,
                'total_conflict_count': 1,
                'auto_resolved_conflict_count': 0,
                'repair_required_conflict_count': 0,
                'user_confirmation_conflict_count': 1,
                'degraded': false,
                'highest_conflict_risk': 'high',
                'summary': '协作结果：成功 2 项，冲突 1 项',
                'failure_summary': '',
                'conflict_summary': '协作冲突：待用户确认 1 项',
                'agent_names': <Object?>['审稿智能体', '连续性守卫'],
                'failed_agent_names': const <Object?>[],
                'collaborators': const <Object?>[],
                'conflicts': <Object?>[
                  <String, Object?>{
                    'conflict_id': 'conflict_high_001',
                    'group_key': 'world_rule_reveal',
                    'subject': '是否提前公开世界规则',
                    'target': 'continuity_state',
                    'agent_id': 'continuity_guard',
                    'agent_name': '连续性守卫',
                    'task': '检查设定冲突',
                    'risk': 'high',
                    'suggestion': '保持连续性规则，不提前公开机制。',
                    'adoption_hint': 'user_confirmation_required',
                    'confidence': 0.92,
                    'evidence': <Object?>[
                      <String, Object?>{
                        'kind': 'continuity_rule',
                        'summary': '长期规则禁止第一章公开机制。',
                      },
                    ],
                    'metadata': <String, Object?>{
                      'requires_user_confirmation': true,
                    },
                  },
                ],
                'arbitration_results': <Object?>[
                  <String, Object?>{
                    'arbitration_id': 'arbitration_world_rule_reveal',
                    'group_key': 'world_rule_reveal',
                    'status': 'needs_user_confirmation',
                    'highest_risk': 'high',
                    'selected_conflict_id': 'conflict_high_001',
                    'summary': '协作冲突需要用户确认：是否提前公开世界规则。',
                    'reason': 'collaboration_conflict_needs_user_confirmation',
                    'auto_resolved': false,
                    'requires_repair': false,
                    'requires_user_confirmation': true,
                    'accepted_conflict_ids': const <Object?>[
                      'conflict_high_001',
                    ],
                    'rejected_conflict_ids': const <Object?>[],
                    'pending_conflict_ids': const <Object?>[
                      'conflict_high_001',
                    ],
                    'metadata': const <String, Object?>{},
                  },
                ],
                'metadata': const <String, Object?>{},
              },
              'recovery': const <String, Object?>{},
              'next_action': 'confirm_collaboration_conflict',
              'blocks_progress': true,
              'retryable': false,
              'requires_user_action': true,
              'schema_version': 1,
              'metadata': const <String, Object?>{},
            },
            'response': const <String, Object?>{'content': '已完成正文草稿。'},
          },
          memorySections: const <JsonMap>[
            <String, Object?>{'title': '连续性规则'},
          ],
          outputPaths: const <String>['chapters/ch02.md'],
          execution: const <String, Object?>{},
          createdAt: '2026-06-05T13:40:00Z',
        );

        final collaborationSignal = ValueReaders.mapValue(
          review['collaboration_signal'],
        );
        expect(ValueReaders.boolValue(collaborationSignal['present']), isTrue);
        expect(
          ValueReaders.stringValue(collaborationSignal['category']),
          'checkpoint_user',
        );
        expect(
          ValueReaders.stringValue(review['collaboration_summary']),
          contains('待用户确认'),
        );
        expect(
          ValueReaders.stringList(review['next_actions']),
          contains('先确认高风险协作冲突的采纳方向，再决定是否继续长任务主链。'),
        );

        final severity = LongTaskCheckpointSeverityService().assess(review);
        expect(ValueReaders.stringValue(severity['severity']), 'high');

        final reviewWithSeverity = <String, Object?>{
          ...review,
          'severity': severity['severity'],
          'severity_label': severity['severity_label'],
          'severity_reasons': severity['reasons'],
        };
        final disposition = LongTaskCheckpointDispositionService().resolve(
          reviewWithSeverity,
        );
        expect(
          ValueReaders.stringValue(disposition['reason']),
          'collaboration_conflict_requires_user_confirmation',
        );
        expect(ValueReaders.boolValue(disposition['allow_continue']), isFalse);
      },
    );
  });
}
