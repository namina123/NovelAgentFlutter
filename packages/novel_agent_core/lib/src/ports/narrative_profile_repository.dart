import '../continuity/narrative_state/narrative_profile.dart';
import '../project/project_descriptor.dart';

abstract class NarrativeProfileRepository {
  Future<void> appendProfile(
    ProjectDescriptor project,
    NarrativeProfile profile,
  );

  Future<NarrativeProfile?> readProfile(
    ProjectDescriptor project, {
    required String profileId,
  });

  Future<List<NarrativeProfile>> listProfiles(
    ProjectDescriptor project, {
    String? profileNamespace,
  });
}
