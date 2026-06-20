import '../../presentation/models/project_rag_extraction_view_data.dart';
import '../models/project_rag_extraction_snapshot.dart';
import '../models/project_rag_extraction_mode_id.dart';
import 'project_rag_analysis_summary_decoder.dart';
import 'project_rag_extraction_mode_view_data_service.dart';

class ProjectRagExtractionViewDataService {
  const ProjectRagExtractionViewDataService({
    ProjectRagExtractionModeViewDataService? modeViewDataService,
    ProjectRagAnalysisSummaryDecoder? analysisSummaryDecoder,
  }) : _modeViewDataService =
           modeViewDataService ??
           const ProjectRagExtractionModeViewDataService(),
       _analysisSummaryDecoder =
           analysisSummaryDecoder ?? const ProjectRagAnalysisSummaryDecoder();

  final ProjectRagExtractionModeViewDataService _modeViewDataService;
  final ProjectRagAnalysisSummaryDecoder _analysisSummaryDecoder;

  ProjectRagExtractionViewData build({
    required ProjectRagExtractionSnapshot snapshot,
  }) {
    // 中文注释: 语料提取视图只消费正式摘要与模式状态，不在这里发起任何存储或检索动作。
    final selectedCorpus = snapshot.selectedCorpus;
    final corpusSummary = selectedCorpus == null
        ? ProjectRagExtractionCorpusSummaryViewData.empty()
        : ProjectRagExtractionCorpusSummaryViewData(
            title: selectedCorpus.title.trim().isEmpty
                ? '语料包'
                : selectedCorpus.title.trim(),
            corpusId: selectedCorpus.corpusId,
            sourceKind: selectedCorpus.sourceKind,
            buildMode: selectedCorpus.buildMode,
            language: selectedCorpus.language,
            chapterCountLabel: selectedCorpus.chapterCount.toString(),
            chunkCountLabel: selectedCorpus.chunkCount.toString(),
            modelAssistedLabel: selectedCorpus.isModelAssisted ? '是' : '否',
            indexBackendLabel: selectedCorpus.indexBackend,
            updatedAt: selectedCorpus.updatedAt,
            sourcePath:
                selectedCorpus.metadata['source_file_path']?.toString() ?? '',
          );
    final mountSummary = ProjectRagExtractionMountSummaryViewData(
      bindingCount: snapshot.mountSummary.bindingCount,
      corpusIds: snapshot.mountSummary.corpusIds,
      topCorpusId: snapshot.mountSummary.topCorpusId,
      topBindingId: snapshot.mountSummary.topBindingId,
      topMountScope: snapshot.mountSummary.topMountScope,
      topUsagePolicy: snapshot.mountSummary.topUsagePolicy,
      topActivationPolicy: snapshot.mountSummary.topActivationPolicy,
      emptyMessage: snapshot.mountSummary.hasBindings ? '' : '当前项目尚未挂载任何语料。',
    );
    final analysisSummary = snapshot.analysisSummary.isEmpty
        ? _analysisSummaryDecoder.decode(selectedCorpus)
        : snapshot.analysisSummary;
    return ProjectRagExtractionViewData(
      title: '语料提取',
      description: '先提取 txt 语料，再挂载到当前项目。挂载完成后，这份语料才能在后续写作里被项目调用。',
      status: snapshot.statusMessage,
      activeModeId: snapshot.activeModeId,
      modes: _modeViewDataService.buildModes(
        selectedModeId: snapshot.activeModeId,
      ),
      corpusSummary: corpusSummary,
      mountSummary: mountSummary,
      analysisSummary: ProjectRagExtractionAnalysisSummaryViewData(
        storyOutlineSummary: analysisSummary.storyOutlineSummary,
        premiseSummary: analysisSummary.premiseSummary,
        styleSummary: analysisSummary.styleSummary,
        chapterTitles: analysisSummary.chapterTitles,
        characterNames: analysisSummary.characterNames,
        organizationNames: analysisSummary.organizationNames,
        worldRuleTitles: analysisSummary.worldRuleTitles,
        relationshipPairs: analysisSummary.relationshipPairs,
        timelineLabels: analysisSummary.timelineLabels,
        foreshadowTitles: analysisSummary.foreshadowTitles,
      ),
      recentSourcePath: snapshot.recentSourcePath,
      normalizationNote: snapshot.normalizationNote,
      canBuildTxt: ProjectRagExtractionModeId.isImplemented(
        snapshot.activeModeId,
      ),
      canMountCorpus: snapshot.selectedCorpus != null,
      isLoading: snapshot.isLoading,
    );
  }
}
