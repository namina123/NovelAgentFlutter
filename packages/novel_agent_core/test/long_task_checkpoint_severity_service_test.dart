import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointSeverityService', () {
    final service = LongTaskCheckpointSeverityService();

    test(
      'keeps sample chapter with advisory-only checkpoint signals at medium severity',
      () {
        final severity = service.assess(const <String, Object?>{
          'task_type': 'chapter',
          'stage': 'sample',
          'result_ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'drift_watch_items': <Object?>[
            '样章阶段要重点检查文风是否稳定、入口是否干净利落。',
            '当前节点触及设定文件，需重点检查新增规则、代价和因果是否自洽。',
            '检查角色动机、身份、称谓和关系是否与既有锚点一致。',
          ],
          'drift_signals': <Object?>[
            <String, Object?>{
              'domain': 'style',
              'severity': 'high',
              'note': '样章阶段要重点检查文风是否稳定、入口是否干净利落。',
            },
            <String, Object?>{
              'domain': 'world',
              'severity': 'high',
              'note': '当前节点触及设定文件，需重点检查新增规则、代价和因果是否自洽。',
            },
          ],
          'confirmation_focus': <Object?>[
            '本轮产出的正文或样章是否保持了既定口吻、节奏和冲突推进。',
            '样章入口是否成立，是否能证明题材钩子和叙事方式可持续。',
          ],
          'narrative_supervisor_risk': <String, Object?>{
            'overall': <String, Object?>{
              'category': 'accept',
              'reason': 'narrative_risk_clear',
              'summary': '当前没有来自交付、语义复核或权限层的额外阻塞信号。',
            },
            'review': <String, Object?>{
              'blocking_finding_count': 0,
              'questioned_claim_count': 0,
            },
            'permission': <String, Object?>{
              'waiting_for_user': false,
            },
            'expression_constraints': <String, Object?>{
              'category': 'suggest_strengthen',
              'summary': '表达限制风险开始连续出现，建议下一章优先回调。',
            },
          },
          'information_signal': <String, Object?>{
            'category': 'accept',
            'summary': '当前没有新的 information 风险信号。',
          },
          'collaboration_signal': <String, Object?>{
            'category': 'accept',
            'summary': '',
          },
        });

        expect(ValueReaders.stringValue(severity['severity']), 'medium');
        expect(
          ValueReaders.stringList(severity['reasons']),
          contains('样章阶段决定长期可写性，建议提高人工确认强度。'),
        );
      },
    );
  });
}
