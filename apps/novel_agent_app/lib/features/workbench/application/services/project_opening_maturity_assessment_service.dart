import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/opening_session_projection.dart';
import '../models/project_opening_maturity_assessment.dart';
import '../models/project_opening_maturity_stage.dart';
import '../../presentation/models/resource_entry_view_data.dart';

class ProjectOpeningMaturityAssessmentService {
  const ProjectOpeningMaturityAssessmentService();

  static const List<String> _foundationPrefixes = <String>[
    'premise/',
    'outlines/',
    'chapters/',
    'scenes/',
    'assets/characters/',
    'assets/organizations/',
    'assets/locations/',
    'assets/items/',
    'assets/styles/',
    'assets/world/',
    'assets/foreshadows/',
    'assets/relationships/',
    'assets/timeline/',
  ];

  static const List<String> _narrativePrefixes = <String>[
    'outlines/',
    'chapters/',
    'scenes/',
  ];

  ProjectOpeningMaturityAssessment build({
    required String projectType,
    required List<ResourceEntryViewData> resourceEntries,
    List<JsonMap> resourceSnapshotEntries = const <JsonMap>[],
    required OpeningSessionProjection? openingProjection,
  }) {
    final effectiveEntries = _effectiveEntries(
      resourceEntries: resourceEntries,
      resourceSnapshotEntries: resourceSnapshotEntries,
    );
    final foundationFileCount = effectiveEntries
        .where(
          (entry) =>
              _isFoundationFile(entry.path, isDirectory: entry.isDirectory),
        )
        .length;
    final narrativeFileCount = effectiveEntries
        .where(
          (entry) =>
              _isNarrativeFile(entry.path, isDirectory: entry.isDirectory),
        )
        .length;
    if (narrativeFileCount > 0 || foundationFileCount >= 2) {
      return ProjectOpeningMaturityAssessment(
        stage: ProjectOpeningMaturityStage.continueReady,
        summary: _continueReadySummary(
          projectType: projectType,
          foundationFileCount: foundationFileCount,
          narrativeFileCount: narrativeFileCount,
        ),
        authoredFoundationFileCount: foundationFileCount,
        narrativeFileCount: narrativeFileCount,
      );
    }
    if (_hasOpeningSignals(openingProjection)) {
      return ProjectOpeningMaturityAssessment(
        stage: ProjectOpeningMaturityStage.openingInProgress,
        summary: '当前项目仍处于开局整理阶段，先补齐少量信息再继续。',
        authoredFoundationFileCount: foundationFileCount,
        narrativeFileCount: narrativeFileCount,
      );
    }
    return ProjectOpeningMaturityAssessment(
      stage: ProjectOpeningMaturityStage.fresh,
      summary: '当前项目还没有明显创作基础，适合先用轻量开局收束方向。',
      authoredFoundationFileCount: foundationFileCount,
      narrativeFileCount: narrativeFileCount,
    );
  }

  List<_OpeningMaturityEntry> _effectiveEntries({
    required List<ResourceEntryViewData> resourceEntries,
    required List<JsonMap> resourceSnapshotEntries,
  }) {
    if (resourceSnapshotEntries.isNotEmpty) {
      return resourceSnapshotEntries
          .map(
            (entry) => _OpeningMaturityEntry(
              path: _normalizedPath(
                ValueReaders.stringValue(entry['relative_path']),
              ),
              isDirectory: ValueReaders.boolValue(entry['is_dir']),
            ),
          )
          .where((entry) => entry.path.isNotEmpty)
          .toList(growable: false);
    }
    return resourceEntries
        .map(
          (entry) => _OpeningMaturityEntry(
            path: _normalizedPath(entry.relativePath),
            isDirectory: entry.isDirectory,
          ),
        )
        .where((entry) => entry.path.isNotEmpty)
        .toList(growable: false);
  }

  bool _isFoundationFile(String path, {required bool isDirectory}) {
    if (isDirectory) {
      return false;
    }
    if (ProjectSupportDocumentCatalog.isProjectOverviewPath(path)) {
      return false;
    }
    return _foundationPrefixes.any(path.startsWith);
  }

  bool _isNarrativeFile(String path, {required bool isDirectory}) {
    if (isDirectory) {
      return false;
    }
    return _narrativePrefixes.any(path.startsWith);
  }

  bool _hasOpeningSignals(OpeningSessionProjection? projection) {
    if (projection == null) {
      return false;
    }
    final readiness = projection.orchestration.readiness;
    return projection.currentGroupDisplayName.trim().isNotEmpty ||
        projection.groupSummaries.isNotEmpty ||
        projection.orchestration.state.stageRecords.isNotEmpty ||
        readiness.canStartInteractiveSession ||
        readiness.canStartLongTask ||
        readiness.missingRequirements.isNotEmpty;
  }

  String _continueReadySummary({
    required String projectType,
    required int foundationFileCount,
    required int narrativeFileCount,
  }) {
    if (projectType.trim() == 'long_novel') {
      return narrativeFileCount > 0
          ? '当前项目已经有大纲或正文基础，可直接继续推进长篇协作。'
          : '当前项目已经沉淀了可复用设定，可直接继续推进长篇协作。';
    }
    return narrativeFileCount > 0
        ? '当前项目已经有正文或结构基础，可直接继续创作。'
        : foundationFileCount > 0
        ? '当前项目已经有设定或资料基础，可直接继续创作。'
        : '当前项目已经具备继续创作所需的基础。';
  }

  String _normalizedPath(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/').toLowerCase();
  }
}

class _OpeningMaturityEntry {
  const _OpeningMaturityEntry({required this.path, required this.isDirectory});

  final String path;
  final bool isDirectory;
}
