import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/sub_agent_run_projection_service.dart';

void main() {
  group('SubAgentRunProjectionService', () {
    const service = SubAgentRunProjectionService();

    test(
      'projects expert opinion evidence and adoption summary from collaboration package',
      () {
        final run = service.projectFromToolResult(const <String, Object?>{
          'ok': true,
          'sub_agent_run_id': 'sub_run_1',
          'sub_session_id': 'sub_session_1',
          'agent_id': 'reviewer',
          'agent_name': '审稿员',
          'task': '审一下第一章冲突是否立得住。',
          'summary': '已给出一条主修建议。',
          'result_markdown': '建议把冲突前置到第一段。',
          'reasoning_content': '先看冲突是否太晚出现。',
          'tool_count': 1,
          'sub_agent_events': <Object?>[
            <String, Object?>{'summary': '接收任务。'},
            <String, Object?>{'summary': '返回审稿建议。'},
          ],
          'collaboration_result_package': <String, Object?>{
            'package_id': 'pkg_1',
            'execution_package_id': 'exec_1',
            'child_run_package_id': 'child_1',
            'agent_id': 'reviewer',
            'agent_name': '审稿员',
            'status': 'success',
            'used_tool_count': 1,
            'result_summary': '已给出一条主修建议。',
            'result_markdown': '建议把冲突前置到第一段。',
            'merge_contract': <String, Object?>{
              'merge_mode': 'main_agent_merges',
              'parent_review_required': true,
              'allows_direct_delivery': false,
              'accepted_result_types': <Object?>['suggestion'],
            },
            'conflicts': <Object?>[
              <String, Object?>{
                'conflict_id': 'conflict_1',
                'subject': '第一章冲突露出',
                'agent_id': 'reviewer',
                'agent_name': '审稿员',
                'risk': 'low',
                'suggestion': '建议把冲突前置到第一段。',
                'adoption_hint': '先由主智能体复核后再吸收。',
                'confidence': 0.84,
                'evidence': <Object?>[
                  <String, Object?>{
                    'summary': '第二段之前还没有明确外部阻力。',
                    'reference': 'chapter_01#p1',
                  },
                ],
              },
            ],
            'arbitration_result': <String, Object?>{
              'arbitration_id': 'arb_1',
              'status': 'auto_resolved',
              'highest_risk': 'low',
              'selected_conflict_id': 'conflict_1',
              'summary': '主链可以先复核这条建议，再决定是否吸收。',
              'accepted_conflict_ids': <Object?>['conflict_1'],
            },
          },
        });

        expect(run, isNotNull);
        expect(run!.status, '完成');
        expect(run.expertOpinion, contains('建议把冲突前置到第一段'));
        expect(run.evidenceItems.single, contains('chapter_01#p1'));
        expect(run.adoptionSummary, contains('主链可以先复核这条建议'));
        expect(run.degradationSummary, isEmpty);
        expect(run.diagnosticItems.join('\n'), contains('run_id: sub_run_1'));
        expect(run.diagnosticItems.join('\n'), contains('agent_id: reviewer'));
      },
    );

    test('projects degraded child failure as recoverable continuation', () {
      final run = service.projectFromToolResult(const <String, Object?>{
        'ok': false,
        'sub_agent_run_id': 'sub_run_2',
        'sub_session_id': 'sub_session_2',
        'agent_id': 'evidence_reader',
        'agent_name': '资料考据员',
        'task': '补齐时代背景证据。',
        'summary': '子智能体模型失败，建议退回单主链继续：上下文不足。',
        'failure_disposition': 'fallback_single_main',
        'tool_count': 0,
        'sub_agent_events': <Object?>[
          <String, Object?>{'summary': '接收任务。'},
          <String, Object?>{'summary': '转回单主链继续。'},
        ],
        'collaboration_result_package': <String, Object?>{
          'package_id': 'pkg_2',
          'execution_package_id': 'exec_2',
          'child_run_package_id': 'child_2',
          'agent_id': 'evidence_reader',
          'agent_name': '资料考据员',
          'status': 'failed',
          'retryable': false,
          'used_tool_count': 0,
          'merge_contract': <String, Object?>{
            'merge_mode': 'main_agent_merges',
            'parent_review_required': true,
            'allows_direct_delivery': false,
            'accepted_result_types': <Object?>['suggestion'],
          },
          'metadata': <String, Object?>{
            'failure_disposition': 'fallback_single_main',
          },
        },
      });

      expect(run, isNotNull);
      expect(run!.status, '已降级返回');
      expect(run.degradationSummary, contains('已退回单主链继续'));
      expect(run.summary, contains('建议退回单主链继续'));
      expect(run.expertOpinion, isEmpty);
    });
  });
}
