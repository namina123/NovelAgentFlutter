import '../modes/mode_guidance_state.dart';
import '../modes/mode_guidance_transition_service.dart';
import '../ports/mode_guidance_state_port.dart';
import '../project/project_descriptor.dart';

class AnswerModeGuidanceStageUseCase {
  AnswerModeGuidanceStageUseCase({
    required ModeGuidanceStatePort statePort,
    ModeGuidanceTransitionService? transitionService,
  }) : _statePort = statePort,
       _transitionService = transitionService ?? ModeGuidanceTransitionService();

  final ModeGuidanceStatePort _statePort;
  final ModeGuidanceTransitionService _transitionService;

  Future<ModeGuidanceState> execute(
    ProjectDescriptor project, {
    required String modeId,
    required String stageId,
    required String fieldKey,
    required String value,
    String label = '',
    String source = 'free_text',
  }) async {
    // 中文注释: 阶段作答用例统一串起读取、推进和保存，避免 GUI/CLI 各自手写状态更新流程。
    final current =
        await _statePort.load(project, modeId: modeId) ??
        _transitionService.initialize(modeId);
    final next = _transitionService.answer(
      current,
      stageId: stageId,
      fieldKey: fieldKey,
      value: value,
      label: label,
      source: source,
    );
    await _statePort.save(project, next);
    return next;
  }
}
