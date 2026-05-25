import '../modes/mode_guidance_state.dart';
import '../modes/mode_guidance_transition_service.dart';
import '../ports/mode_guidance_state_port.dart';
import '../project/project_descriptor.dart';

class LoadModeGuidanceStateUseCase {
  LoadModeGuidanceStateUseCase({
    required ModeGuidanceStatePort statePort,
    ModeGuidanceTransitionService? transitionService,
  }) : _statePort = statePort,
       _transitionService = transitionService ?? ModeGuidanceTransitionService();

  final ModeGuidanceStatePort _statePort;
  final ModeGuidanceTransitionService _transitionService;

  Future<ModeGuidanceState> execute(
    ProjectDescriptor project, {
    required String modeId,
    bool initializeIfMissing = true,
  }) async {
    // 中文注释: 读取模式状态时优先复用已落盘快照，缺失时才按模式定义初始化。
    final loaded = await _statePort.load(project, modeId: modeId);
    if (loaded != null) {
      return loaded;
    }
    final initialized = _transitionService.initialize(modeId);
    if (initializeIfMissing) {
      await _statePort.save(project, initialized);
    }
    return initialized;
  }
}
