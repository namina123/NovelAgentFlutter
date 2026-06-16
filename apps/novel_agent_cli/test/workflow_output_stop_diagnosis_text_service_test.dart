import 'package:novel_agent_cli/commands/workflow/workflow_output_stop_diagnosis_text_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('StopDiagnosisTextService', () {
    const service = StopDiagnosisTextService();

    test('maps generic stop reasons into human-readable labels', () {
      expect(
        service.renderGenericReasonLine('waiting_user_checkpoint'),
        '停止原因：等待用户确认（waiting_user_checkpoint）',
      );
      expect(
        service.renderGenericReasonLine('content_quality_failed'),
        '停止原因：内容质量关口（content_quality_failed）',
      );
    });

    test('renders projected diagnosis and lifecycle labels directly', () {
      expect(
        service.renderDiagnosisLine(
          LongTaskStopDiagnosisProjection.fromJson(const <String, Object?>{
            'present': true,
            'code': 'delivery_manual_attention',
            'label': '内容质量关口',
            'summary': '当前运行需要先处理内容质量关口。',
          }),
        ),
        '停止原因：内容质量关口（delivery_manual_attention）',
      );
      expect(
        service.renderReferenceLifecycleLabel(
          const ContinuousTaskLifecycleState(
            runPhase: ContinuousTaskRunPhases.waitingUser,
            reason: 'reference_mount_confirmation_required',
          ),
        ),
        '挂载等待确认',
      );
      expect(
        service.renderReferenceStopReasonLine(
          'reference_mount_confirmation_required',
        ),
        '停止原因：挂载需要显式确认（reference_mount_confirmation_required）',
      );
    });
  });
}
