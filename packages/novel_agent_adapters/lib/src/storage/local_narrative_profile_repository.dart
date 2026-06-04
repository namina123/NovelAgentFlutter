import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'open_narrative_state_path_service.dart';
import 'project_json_document_service.dart';

class LocalNarrativeProfileRepository implements NarrativeProfileRepository {
  LocalNarrativeProfileRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    OpenNarrativeStatePathService? pathService,
    NarrativeProfileCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _codecService = codecService ?? const NarrativeProfileCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStatePathService _pathService;
  final NarrativeProfileCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendProfile(
    ProjectDescriptor project,
    NarrativeProfile profile,
  ) async {
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.profilePath(profile.profileId),
      _codecService.profileToJson(profile),
    );
    final existingIds = await _readProfileIds(project);
    await _writeProfileIds(project, <String>[
      ...existingIds.where((id) => id != profile.profileId),
      profile.profileId,
    ]);
  }

  @override
  Future<List<NarrativeProfile>> listProfiles(
    ProjectDescriptor project, {
    String? profileNamespace,
  }) async {
    final result = <NarrativeProfile>[];
    for (final profileId in await _readProfileIds(project)) {
      final profile = await readProfile(project, profileId: profileId);
      if (profile == null) {
        continue;
      }
      if (profileNamespace != null &&
          profile.profileNamespace != profileNamespace) {
        continue;
      }
      result.add(profile);
    }
    return result;
  }

  @override
  Future<NarrativeProfile?> readProfile(
    ProjectDescriptor project, {
    required String profileId,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.profilePath(profileId),
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.profileFromJson(document);
  }

  Future<List<String>> _readProfileIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.profilesIndexPath(),
      fieldName: 'profile_ids',
    );
  }

  Future<void> _writeProfileIds(ProjectDescriptor project, List<String> ids) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.profilesIndexPath(),
      fieldName: 'profile_ids',
      ids: ids,
    );
  }
}
