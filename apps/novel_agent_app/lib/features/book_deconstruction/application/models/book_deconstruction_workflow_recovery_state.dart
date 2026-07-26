import 'dart:convert';

import 'book_deconstruction_step_id.dart';

/// The durable subset of a deconstruction session that can safely be resumed.
///
/// The complete draft result is deliberately excluded. Its pure split input is
/// saved instead so a fresh, deterministic result can be reconstructed without
/// re-running model-assisted normalization after reopening the project.
class BookDeconstructionWorkflowRecoveryState {
  const BookDeconstructionWorkflowRecoveryState({
    required this.sourceAbsolutePath,
    required this.sourceTitle,
    required this.sourceContent,
    required this.splitSourceContent,
    required this.splitExtractionId,
    required this.splitContinuationDirectionId,
    required this.splitUseModel,
    required this.splitModelOptionKey,
    required this.analysisUseModel,
    required this.analysisModelOptionKey,
    required this.analysisCompleted,
    required this.analysisStatusMessage,
    this.analysisStagingRunId = '',
    this.analysisStagingPackageId = '',
    this.analysisStagingPackageVersionId = '',
    this.applyStagedAnalysisResults = false,
    required this.selectedItemIds,
    required this.selectedFollowupOptionId,
    required this.selectedTargetWritingTypeId,
    required this.selectedTargetRuntimeBaselineId,
    required this.inheritAsLiveNarrative,
    required this.confirmedPreviewPath,
    required this.activeStepId,
  });

  static const String relativePath =
      '.novel_agent/state/book_deconstruction/workflow_state.json';

  final String sourceAbsolutePath;
  final String sourceTitle;
  final String sourceContent;
  final String splitSourceContent;
  final String splitExtractionId;
  final String splitContinuationDirectionId;
  final bool splitUseModel;
  final String splitModelOptionKey;
  final bool analysisUseModel;
  final String analysisModelOptionKey;
  final bool analysisCompleted;
  final String analysisStatusMessage;
  final String analysisStagingRunId;
  final String analysisStagingPackageId;
  final String analysisStagingPackageVersionId;
  final bool applyStagedAnalysisResults;
  final List<String> selectedItemIds;
  final String selectedFollowupOptionId;
  final String selectedTargetWritingTypeId;
  final String selectedTargetRuntimeBaselineId;
  final bool inheritAsLiveNarrative;
  final String confirmedPreviewPath;
  final String activeStepId;

  bool get hasSourceContent => sourceContent.trim().isNotEmpty;
  bool get hasSplitSourceContent => splitSourceContent.trim().isNotEmpty;

  String get restoredActiveStepId {
    if (!hasSourceContent) {
      return BookDeconstructionStepId.importSource;
    }
    if (!hasSplitSourceContent) {
      return BookDeconstructionStepId.splitChapters;
    }
    switch (activeStepId) {
      case BookDeconstructionStepId.splitChapters:
      case BookDeconstructionStepId.analyzeAssets:
      case BookDeconstructionStepId.confirmSelection:
        return activeStepId;
      default:
        return BookDeconstructionStepId.splitChapters;
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schema_version': 3,
      'source_absolute_path': sourceAbsolutePath,
      'source_title': sourceTitle,
      'source_content': sourceContent,
      'split_source_content': splitSourceContent,
      'split_extraction_id': splitExtractionId,
      'split_continuation_direction_id': splitContinuationDirectionId,
      'split_use_model': splitUseModel,
      'split_model_option_key': splitModelOptionKey,
      'analysis_use_model': analysisUseModel,
      'analysis_model_option_key': analysisModelOptionKey,
      'analysis_completed': analysisCompleted,
      'analysis_status_message': analysisStatusMessage,
      'analysis_staging_run_id': analysisStagingRunId,
      'analysis_staging_package_id': analysisStagingPackageId,
      'analysis_staging_package_version_id': analysisStagingPackageVersionId,
      'apply_staged_analysis_results': applyStagedAnalysisResults,
      'selected_item_ids': selectedItemIds.toList()..sort(),
      'selected_followup_option_id': selectedFollowupOptionId,
      'selected_target_writing_type_id': selectedTargetWritingTypeId,
      'selected_target_runtime_baseline_id': selectedTargetRuntimeBaselineId,
      'inherit_as_live_narrative': inheritAsLiveNarrative,
      'confirmed_preview_path': confirmedPreviewPath,
      'active_step_id': activeStepId,
    };
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static BookDeconstructionWorkflowRecoveryState? tryParse(String source) {
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(cleanSource);
      if (decoded is! Map<Object?, Object?>) {
        return null;
      }
      final json = Map<String, Object?>.from(decoded);
      return BookDeconstructionWorkflowRecoveryState(
        sourceAbsolutePath: _stringValue(json['source_absolute_path']),
        sourceTitle: _stringValue(json['source_title']),
        sourceContent: _stringValue(json['source_content']),
        splitSourceContent: _stringValue(json['split_source_content']),
        splitExtractionId: _stringValue(json['split_extraction_id']),
        splitContinuationDirectionId: _stringValue(
          json['split_continuation_direction_id'],
        ),
        splitUseModel: _boolValue(json['split_use_model']),
        splitModelOptionKey: _stringValue(json['split_model_option_key']),
        analysisUseModel: _boolValue(json['analysis_use_model']),
        analysisModelOptionKey: _stringValue(json['analysis_model_option_key']),
        analysisCompleted: _boolValue(json['analysis_completed']),
        analysisStatusMessage: _stringValue(json['analysis_status_message']),
        analysisStagingRunId: _stringValue(json['analysis_staging_run_id']),
        analysisStagingPackageId: _stringValue(
          json['analysis_staging_package_id'],
        ),
        analysisStagingPackageVersionId: _stringValue(
          json['analysis_staging_package_version_id'],
        ),
        applyStagedAnalysisResults: _boolValue(
          json['apply_staged_analysis_results'],
        ),
        selectedItemIds: _stringListValue(json['selected_item_ids']),
        selectedFollowupOptionId: _stringValue(
          json['selected_followup_option_id'],
        ),
        selectedTargetWritingTypeId: _stringValue(
          json['selected_target_writing_type_id'],
        ),
        selectedTargetRuntimeBaselineId: _stringValue(
          json['selected_target_runtime_baseline_id'],
        ),
        inheritAsLiveNarrative: _boolValue(json['inherit_as_live_narrative']),
        confirmedPreviewPath: _stringValue(json['confirmed_preview_path']),
        activeStepId: _stringValue(json['active_step_id']),
      );
    } catch (_) {
      return null;
    }
  }

  static String _stringValue(Object? value) => value is String ? value : '';

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
