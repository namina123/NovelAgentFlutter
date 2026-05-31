import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_input_repository.dart';
import 'project_continuity_repository.dart';

class ProjectGeneralContinuitySetupService {
  ProjectGeneralContinuitySetupService({
    required ProjectContinuityRepository continuityRepository,
    required ProjectContinuityInputRepository inputRepository,
    GeneralProjectContinuityDefaultsService? defaultsService,
  }) : _continuityRepository = continuityRepository,
       _inputRepository = inputRepository,
       _defaultsService =
           defaultsService ?? const GeneralProjectContinuityDefaultsService();

  final ProjectContinuityRepository _continuityRepository;
  final ProjectContinuityInputRepository _inputRepository;
  final GeneralProjectContinuityDefaultsService _defaultsService;

  Future<ProjectContinuityBundle> ensureInitialized(
    ProjectDescriptor project,
  ) async {
    final existing = await _continuityRepository.load(project);
    if (existing != null) {
      return existing;
    }
    final input =
        await _inputRepository.load(project) ??
        const ProjectContinuityInputProfile();
    final bundle = _defaultsService.buildBundle(project, input: input);
    await _continuityRepository.save(project, bundle);
    return bundle;
  }

  Future<ProjectContinuityBundle> applyInput(
    ProjectDescriptor project,
    ProjectContinuityInputProfile input,
  ) async {
    await _inputRepository.save(project, input);
    final bundle = _defaultsService.buildBundle(project, input: input);
    await _continuityRepository.save(project, bundle);
    return bundle;
  }
}
