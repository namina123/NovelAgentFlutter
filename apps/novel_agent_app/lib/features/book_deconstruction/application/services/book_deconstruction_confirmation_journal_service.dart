import 'dart:convert';

/// Durable progress marker for an otherwise multi-step confirmation commit.
///
/// The marker is intentionally a journal rather than a rollback log: several
/// targets are append-only or externally stored, so a failed confirmation must
/// state which step may be partial instead of claiming that it was rolled back.
class BookDeconstructionConfirmationJournalService {
  const BookDeconstructionConfirmationJournalService();

  static const String relativePath =
      '.novel_agent/state/book_deconstruction/confirmation.json';

  String confirmationId({
    required String extractionId,
    required String targetWritingProjectTypeId,
    required String targetRuntimeBaselineId,
    required Set<String> selectedItemIds,
    required bool inheritAsLiveNarrative,
    bool applyStagedAnalysisResults = false,
    String stagedAnalysisRunId = '',
    String stagedAnalysisPackageId = '',
    String stagedAnalysisPackageVersionId = '',
  }) {
    final selection =
        selectedItemIds
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList()
          ..sort();
    // The extraction id changes when the source is split again, while a reopen
    // restores it. This makes a retry stable without conflating a new split.
    return <String>[
      extractionId.trim(),
      targetWritingProjectTypeId.trim(),
      targetRuntimeBaselineId.trim(),
      inheritAsLiveNarrative ? 'live' : 'reference',
      applyStagedAnalysisResults
          ? 'apply_staged_analysis'
          : 'skip_staged_analysis',
      if (applyStagedAnalysisResults) ...<String>[
        stagedAnalysisRunId.trim(),
        stagedAnalysisPackageId.trim(),
        stagedAnalysisPackageVersionId.trim(),
      ],
      ...selection,
    ].join('|');
  }

  String pending({
    required String confirmationId,
    required String extractionId,
    required String targetWritingProjectTypeId,
    required String targetRuntimeBaselineId,
    required Set<String> selectedItemIds,
    required bool inheritAsLiveNarrative,
    required String currentStep,
    List<String> completedSteps = const <String>[],
    List<String> changedPaths = const <String>[],
    List<String> chapterPaths = const <String>[],
    bool projectTypeTransitioned = false,
    bool applyStagedAnalysisResults = false,
    String stagedAnalysisRunId = '',
    String stagedAnalysisPackageId = '',
    String stagedAnalysisPackageVersionId = '',
    bool stagedAnalysisApplied = false,
    String stagedAnalysisMountStatus = '',
  }) {
    return _encode(
      status: BookDeconstructionConfirmationStatus.pending,
      confirmationId: confirmationId,
      extractionId: extractionId,
      targetWritingProjectTypeId: targetWritingProjectTypeId,
      targetRuntimeBaselineId: targetRuntimeBaselineId,
      selectedItemIds: selectedItemIds,
      inheritAsLiveNarrative: inheritAsLiveNarrative,
      currentStep: currentStep,
      completedSteps: completedSteps,
      changedPaths: changedPaths,
      chapterPaths: chapterPaths,
      projectTypeTransitioned: projectTypeTransitioned,
      applyStagedAnalysisResults: applyStagedAnalysisResults,
      stagedAnalysisRunId: stagedAnalysisRunId,
      stagedAnalysisPackageId: stagedAnalysisPackageId,
      stagedAnalysisPackageVersionId: stagedAnalysisPackageVersionId,
      stagedAnalysisApplied: stagedAnalysisApplied,
      stagedAnalysisMountStatus: stagedAnalysisMountStatus,
    );
  }

  String completed({
    required String confirmationId,
    required String extractionId,
    required String targetWritingProjectTypeId,
    required String targetRuntimeBaselineId,
    required Set<String> selectedItemIds,
    required bool inheritAsLiveNarrative,
    required List<String> completedSteps,
    required List<String> changedPaths,
    required List<String> chapterPaths,
    required bool projectTypeTransitioned,
    required String previewPath,
    bool applyStagedAnalysisResults = false,
    String stagedAnalysisRunId = '',
    String stagedAnalysisPackageId = '',
    String stagedAnalysisPackageVersionId = '',
    bool stagedAnalysisApplied = false,
    String stagedAnalysisMountStatus = '',
  }) {
    return _encode(
      status: BookDeconstructionConfirmationStatus.completed,
      confirmationId: confirmationId,
      extractionId: extractionId,
      targetWritingProjectTypeId: targetWritingProjectTypeId,
      targetRuntimeBaselineId: targetRuntimeBaselineId,
      selectedItemIds: selectedItemIds,
      inheritAsLiveNarrative: inheritAsLiveNarrative,
      currentStep: '',
      completedSteps: completedSteps,
      changedPaths: changedPaths,
      chapterPaths: chapterPaths,
      projectTypeTransitioned: projectTypeTransitioned,
      previewPath: previewPath,
      applyStagedAnalysisResults: applyStagedAnalysisResults,
      stagedAnalysisRunId: stagedAnalysisRunId,
      stagedAnalysisPackageId: stagedAnalysisPackageId,
      stagedAnalysisPackageVersionId: stagedAnalysisPackageVersionId,
      stagedAnalysisApplied: stagedAnalysisApplied,
      stagedAnalysisMountStatus: stagedAnalysisMountStatus,
    );
  }

  String failed({
    required String confirmationId,
    required String extractionId,
    required String targetWritingProjectTypeId,
    required String targetRuntimeBaselineId,
    required Set<String> selectedItemIds,
    required bool inheritAsLiveNarrative,
    required String currentStep,
    required List<String> completedSteps,
    required List<String> changedPaths,
    required List<String> chapterPaths,
    required bool projectTypeTransitioned,
    required Object error,
    bool applyStagedAnalysisResults = false,
    String stagedAnalysisRunId = '',
    String stagedAnalysisPackageId = '',
    String stagedAnalysisPackageVersionId = '',
    bool stagedAnalysisApplied = false,
    String stagedAnalysisMountStatus = '',
  }) {
    return _encode(
      status: BookDeconstructionConfirmationStatus.failed,
      confirmationId: confirmationId,
      extractionId: extractionId,
      targetWritingProjectTypeId: targetWritingProjectTypeId,
      targetRuntimeBaselineId: targetRuntimeBaselineId,
      selectedItemIds: selectedItemIds,
      inheritAsLiveNarrative: inheritAsLiveNarrative,
      currentStep: currentStep,
      completedSteps: completedSteps,
      changedPaths: changedPaths,
      chapterPaths: chapterPaths,
      projectTypeTransitioned: projectTypeTransitioned,
      error: error.toString(),
      applyStagedAnalysisResults: applyStagedAnalysisResults,
      stagedAnalysisRunId: stagedAnalysisRunId,
      stagedAnalysisPackageId: stagedAnalysisPackageId,
      stagedAnalysisPackageVersionId: stagedAnalysisPackageVersionId,
      stagedAnalysisApplied: stagedAnalysisApplied,
      stagedAnalysisMountStatus: stagedAnalysisMountStatus,
    );
  }

  BookDeconstructionConfirmationJournal? tryParse(String source) {
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(cleanSource);
      if (decoded is! Map<Object?, Object?>) {
        return null;
      }
      return BookDeconstructionConfirmationJournal.fromJson(
        Map<String, Object?>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  String _encode({
    required String status,
    required String confirmationId,
    required String extractionId,
    required String targetWritingProjectTypeId,
    required String targetRuntimeBaselineId,
    required Set<String> selectedItemIds,
    required bool inheritAsLiveNarrative,
    required String currentStep,
    required List<String> completedSteps,
    required List<String> changedPaths,
    required List<String> chapterPaths,
    required bool projectTypeTransitioned,
    String previewPath = '',
    String error = '',
    bool applyStagedAnalysisResults = false,
    String stagedAnalysisRunId = '',
    String stagedAnalysisPackageId = '',
    String stagedAnalysisPackageVersionId = '',
    bool stagedAnalysisApplied = false,
    String stagedAnalysisMountStatus = '',
  }) {
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema_version': 3,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'confirmation_id': confirmationId.trim(),
      'extraction_id': extractionId.trim(),
      'target_writing_project_type_id': targetWritingProjectTypeId.trim(),
      'target_runtime_baseline_id': targetRuntimeBaselineId.trim(),
      'inherit_as_live_narrative': inheritAsLiveNarrative,
      'selected_item_ids': _sortedUnique(selectedItemIds),
      'current_step': currentStep.trim(),
      'completed_steps': _sortedUnique(completedSteps),
      'changed_paths': _sortedUnique(changedPaths),
      'chapter_paths': _sortedUnique(chapterPaths),
      'project_type_transitioned': projectTypeTransitioned,
      'apply_staged_analysis_results': applyStagedAnalysisResults,
      'staged_analysis_applied': stagedAnalysisApplied,
      if (stagedAnalysisRunId.trim().isNotEmpty)
        'staged_analysis_run_id': stagedAnalysisRunId.trim(),
      if (stagedAnalysisPackageId.trim().isNotEmpty)
        'staged_analysis_package_id': stagedAnalysisPackageId.trim(),
      if (stagedAnalysisPackageVersionId.trim().isNotEmpty)
        'staged_analysis_package_version_id': stagedAnalysisPackageVersionId
            .trim(),
      if (stagedAnalysisMountStatus.trim().isNotEmpty)
        'staged_analysis_mount_status': stagedAnalysisMountStatus.trim(),
      if (previewPath.trim().isNotEmpty) 'preview_path': previewPath.trim(),
      if (error.trim().isNotEmpty) 'error': error.trim(),
    });
  }

  static List<String> _sortedUnique(Iterable<String> values) {
    final result =
        values
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return result;
  }
}

abstract final class BookDeconstructionConfirmationStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

class BookDeconstructionConfirmationJournal {
  const BookDeconstructionConfirmationJournal({
    required this.status,
    required this.confirmationId,
    required this.extractionId,
    required this.targetWritingProjectTypeId,
    required this.targetRuntimeBaselineId,
    required this.inheritAsLiveNarrative,
    required this.selectedItemIds,
    required this.currentStep,
    required this.completedSteps,
    required this.changedPaths,
    required this.chapterPaths,
    required this.projectTypeTransitioned,
    required this.previewPath,
    required this.error,
    this.applyStagedAnalysisResults = false,
    this.stagedAnalysisRunId = '',
    this.stagedAnalysisPackageId = '',
    this.stagedAnalysisPackageVersionId = '',
    this.stagedAnalysisApplied = false,
    this.stagedAnalysisMountStatus = '',
  });

  final String status;
  final String confirmationId;
  final String extractionId;
  final String targetWritingProjectTypeId;
  final String targetRuntimeBaselineId;
  final bool inheritAsLiveNarrative;
  final List<String> selectedItemIds;
  final String currentStep;
  final List<String> completedSteps;
  final List<String> changedPaths;
  final List<String> chapterPaths;
  final bool projectTypeTransitioned;
  final String previewPath;
  final String error;
  final bool applyStagedAnalysisResults;
  final String stagedAnalysisRunId;
  final String stagedAnalysisPackageId;
  final String stagedAnalysisPackageVersionId;
  final bool stagedAnalysisApplied;
  final String stagedAnalysisMountStatus;

  bool get isCompleted =>
      status == BookDeconstructionConfirmationStatus.completed;

  bool get requiresRecovery =>
      status == BookDeconstructionConfirmationStatus.pending ||
      status == BookDeconstructionConfirmationStatus.failed;

  factory BookDeconstructionConfirmationJournal.fromJson(
    Map<String, Object?> json,
  ) {
    return BookDeconstructionConfirmationJournal(
      status: _stringValue(json['status']),
      confirmationId: _stringValue(json['confirmation_id']),
      extractionId: _stringValue(json['extraction_id']),
      targetWritingProjectTypeId: _stringValue(
        json['target_writing_project_type_id'],
      ),
      targetRuntimeBaselineId: _stringValue(json['target_runtime_baseline_id']),
      inheritAsLiveNarrative: _boolValue(json['inherit_as_live_narrative']),
      selectedItemIds: _stringListValue(json['selected_item_ids']),
      currentStep: _stringValue(json['current_step']),
      completedSteps: _stringListValue(json['completed_steps']),
      changedPaths: _stringListValue(json['changed_paths']),
      chapterPaths: _stringListValue(json['chapter_paths']),
      projectTypeTransitioned: _boolValue(json['project_type_transitioned']),
      previewPath: _stringValue(json['preview_path']),
      error: _stringValue(json['error']),
      applyStagedAnalysisResults: _boolValue(
        json['apply_staged_analysis_results'],
      ),
      stagedAnalysisRunId: _stringValue(json['staged_analysis_run_id']),
      stagedAnalysisPackageId: _stringValue(json['staged_analysis_package_id']),
      stagedAnalysisPackageVersionId: _stringValue(
        json['staged_analysis_package_version_id'],
      ),
      stagedAnalysisApplied: _boolValue(json['staged_analysis_applied']),
      stagedAnalysisMountStatus: _stringValue(
        json['staged_analysis_mount_status'],
      ),
    );
  }

  static String _stringValue(Object? value) =>
      value is String ? value.trim() : '';

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static List<String> _stringListValue(Object? value) {
    if (value is! List<Object?>) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
