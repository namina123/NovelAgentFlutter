import '../modes/mode_guidance_state.dart';
import '../project/project_descriptor.dart';

abstract class ModeGuidanceStatePort {
  Future<ModeGuidanceState?> load(
    ProjectDescriptor project, {
    required String modeId,
  });

  Future<void> save(ProjectDescriptor project, ModeGuidanceState state);
}
