import '../modes/mode_guidance_plan_input.dart';
import '../modes/mode_guidance_plan_input_builder_service.dart';
import '../ports/mode_guidance_state_port.dart';
import '../project/project_descriptor.dart';

class BuildModeGuidancePlanInputUseCase {
  BuildModeGuidancePlanInputUseCase({
    required ModeGuidanceStatePort statePort,
    ModeGuidancePlanInputBuilderService? builderService,
  }) : _statePort = statePort,
       _builderService =
           builderService ?? ModeGuidancePlanInputBuilderService();

  final ModeGuidanceStatePort _statePort;
  final ModeGuidancePlanInputBuilderService _builderService;

  Future<ModeGuidancePlanInput?> execute(
    ProjectDescriptor project, {
    required String modeId,
  }) async {
    // 中文注释: 该用例统一负责从已保存的模式状态构建计划输入，避免上层分别加载状态和手工映射。
    final state = await _statePort.load(project, modeId: modeId);
    if (state == null) {
      return null;
    }
    return _builderService.build(state);
  }
}
