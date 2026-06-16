import 'package:novel_agent_cli/commands/workflow/workflow_output_run_center_summary_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('RunCenterSummaryRenderer', () {
    final renderer = RunCenterSummaryRenderer();

    test('extracts run center contract from nested workflow output', () {
      final contract = renderer.extractContract(const <String, Object?>{
        'record': <String, Object?>{
          'run_center_contract': <String, Object?>{
            'status_label': '已暂停',
            'phase_label': '检查点',
            'reason': 'waiting_user_checkpoint',
          },
        },
      });

      expect(contract['status_label'], '已暂停');
      expect(contract['phase_label'], '检查点');
      expect(contract['reason'], 'waiting_user_checkpoint');
    });

    test('renders stop diagnosis and resume brief text without inference', () {
      final lines = renderer.renderLines(const <String, Object?>{
        'status_label': '运行中',
        'phase_label': '恢复',
        'progress': <String, Object?>{'overall_percent': 67},
        'active_task': <String, Object?>{'title': '推进正文'},
        'stop_diagnosis': <String, Object?>{
          'present': true,
          'code': 'delivery_manual_attention',
          'label': '内容质量关口',
        },
        'recommended_action_label': '继续推进',
        'resume_brief': <String, Object?>{
          'resume_title': '恢复标题',
          'resume_summary': '恢复摘要',
          'last_step_summary': '上一轮已完成整理。',
          'next_action_summary': '下一步继续补齐正文。',
        },
      });

      expect(lines, contains('状态：运行中'));
      expect(lines, contains('阶段：恢复'));
      expect(lines, contains('进度：67%'));
      expect(lines, contains('当前任务：推进正文'));
      expect(lines, contains('停止原因：内容质量关口（delivery_manual_attention）'));
      expect(lines, contains('下一步：继续推进'));
      expect(lines, contains('恢复标题：恢复标题'));
      expect(lines, contains('恢复摘要'));
      expect(lines, contains('上一轮已完成整理。'));
      expect(lines, contains('下一步继续补齐正文。'));
    });
  });
}
