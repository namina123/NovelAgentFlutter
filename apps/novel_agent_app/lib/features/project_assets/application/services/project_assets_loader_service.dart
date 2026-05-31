import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_expression_constraint_workspace.dart';
import '../models/project_assets_catalog.dart';
import 'project_expression_constraint_workspace_service.dart';

class ProjectAssetsLoaderService {
  ProjectAssetsLoaderService({
    required ProjectAssetLibraryService projectAssetLibraryService,
    required ProjectTimelineRepository timelineRepository,
    required ProjectRelationshipRepository relationshipRepository,
    required ProjectExpressionConstraintWorkspaceService
    expressionConstraintWorkspaceService,
    SharedNarrativeAssetReferenceIndexService? referenceIndexService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
  }) : _projectAssetLibraryService = projectAssetLibraryService,
       _timelineRepository = timelineRepository,
       _relationshipRepository = relationshipRepository,
       _expressionConstraintWorkspaceService =
           expressionConstraintWorkspaceService,
       _referenceIndexService =
           referenceIndexService ??
           const SharedNarrativeAssetReferenceIndexService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService();

  final ProjectAssetLibraryService _projectAssetLibraryService;
  final ProjectTimelineRepository _timelineRepository;
  final ProjectRelationshipRepository _relationshipRepository;
  final ProjectExpressionConstraintWorkspaceService
  _expressionConstraintWorkspaceService;
  final SharedNarrativeAssetReferenceIndexService _referenceIndexService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;

  Future<ProjectAssetsCatalog> load(ProjectDescriptor project) async {
    // 中文注释: 读侧装载器只汇总项目资产，不做 UI 选择态与表单投影。
    final results = await Future.wait<Object>(<Future<Object>>[
      _projectAssetLibraryService.listStyles(project),
      _expressionConstraintWorkspaceService.load(project),
      _projectAssetLibraryService.listForeshadows(project),
      _timelineRepository.list(project),
      _relationshipRepository.list(project),
    ]);
    final styles = List<JsonMap>.from(results[0] as List<JsonMap>);
    final expressionConstraintWorkspace =
        results[1] as ProjectExpressionConstraintWorkspace;
    final foreshadows = (results[2] as List<JsonMap>)
        .map(_foreshadowNormalizerService.normalize)
        .toList(growable: false);
    final timelines =
        List<TimelineRecord>.from(results[3] as List<TimelineRecord>)
          ..sort((left, right) {
            final order = left.sequence.compareTo(right.sequence);
            if (order != 0) {
              return order;
            }
            return left.displayName.compareTo(right.displayName);
          });
    final relationships = List<RelationshipRecord>.from(
      results[4] as List<RelationshipRecord>,
    )..sort((left, right) => left.displayName.compareTo(right.displayName));
    final referenceIndex = _referenceIndexService.buildIndex(
      foreshadows: foreshadows,
      timelines: timelines,
      relationships: relationships,
    );
    return ProjectAssetsCatalog(
      styles: styles,
      expressionConstraints: expressionConstraintWorkspace.profiles,
      expressionConstraintBindings: expressionConstraintWorkspace.bindings,
      foreshadows: foreshadows,
      timelines: timelines,
      relationships: relationships,
      referenceIndex: referenceIndex,
    );
  }
}
