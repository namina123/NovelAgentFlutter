import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'open_narrative_state_path_service.dart';
import 'project_json_document_service.dart';

class LocalConstraintBindingRepository implements ConstraintBindingRepository {
  LocalConstraintBindingRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    OpenNarrativeStatePathService? pathService,
    NarrativeConstraintBindingCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _codecService =
           codecService ?? const NarrativeConstraintBindingCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStatePathService _pathService;
  final NarrativeConstraintBindingCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendBinding(
    ProjectDescriptor project,
    NarrativeConstraintBindingProposal binding,
  ) async {
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.bindingPath(binding.bindingId),
      _codecService.proposalToJson(binding),
    );
    final existingIds = await _readBindingIds(project);
    await _writeBindingIds(project, <String>[
      ...existingIds.where((id) => id != binding.bindingId),
      binding.bindingId,
    ]);
  }

  @override
  Future<List<NarrativeConstraintBindingProposal>> listBindings(
    ProjectDescriptor project, {
    String? constraintType,
  }) async {
    final result = <NarrativeConstraintBindingProposal>[];
    for (final bindingId in await _readBindingIds(project)) {
      final binding = await readBinding(project, bindingId: bindingId);
      if (binding == null) {
        continue;
      }
      if (constraintType != null && binding.constraintType != constraintType) {
        continue;
      }
      result.add(binding);
    }
    return result;
  }

  @override
  Future<NarrativeConstraintBindingProposal?> readBinding(
    ProjectDescriptor project, {
    required String bindingId,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.bindingPath(bindingId),
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.proposalFromJson(document);
  }

  Future<List<String>> _readBindingIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.bindingsIndexPath(),
      fieldName: 'binding_ids',
    );
  }

  Future<void> _writeBindingIds(ProjectDescriptor project, List<String> ids) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.bindingsIndexPath(),
      fieldName: 'binding_ids',
      ids: ids,
    );
  }
}
