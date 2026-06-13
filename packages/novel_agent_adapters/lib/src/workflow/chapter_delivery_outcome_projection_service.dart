import 'package:novel_agent_core/novel_agent_core.dart';

class ChapterDeliveryOutcomeProjectionService {
  const ChapterDeliveryOutcomeProjectionService({
    ChapterOutputPathPolicyService? chapterOutputPathPolicyService,
  }) : _chapterOutputPathPolicyService =
           chapterOutputPathPolicyService ??
           const ChapterOutputPathPolicyService();

  final ChapterOutputPathPolicyService _chapterOutputPathPolicyService;

  JsonMap latestFromExecutedTools(List<Object?> executedTools) {
    for (final rawTool in executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']).trim();
      if (toolName != NarrativeDomainToolNames.submitChapterDelivery) {
        continue;
      }
      final result = ValueReaders.mapValue(tool['result']);
      final outcome = ValueReaders.mapValue(result['domain_outcome']);
      final payload = ValueReaders.mapValue(outcome['outcome_payload']);
      if (payload.isEmpty) {
        continue;
      }
      return fromPayload(
        toolName: NarrativeDomainToolNames.submitChapterDelivery,
        outcomeStatus: ValueReaders.stringValue(
          outcome['outcome_status'],
          ValueReaders.stringValue(result['domain_outcome_status']),
        ),
        payload: payload,
      );
    }
    return const <String, Object?>{};
  }

  JsonMap fromDomainOutcome({
    required String toolName,
    required DomainToolOutcome outcome,
  }) {
    final payload = ValueReaders.mapValue(outcome.outcomePayload);
    if (payload.isEmpty) {
      return const <String, Object?>{};
    }
    return fromPayload(
      toolName: toolName,
      outcomeStatus: outcome.outcomeStatus,
      payload: payload,
    );
  }

  JsonMap fromPayload({
    required String toolName,
    required String outcomeStatus,
    required JsonMap payload,
  }) {
    final submission = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(payload['submission']),
    );
    final pathResolution = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(payload['path_resolution']),
    );
    final normalizedResolution = _chapterOutputPathPolicyService
        .resolveChapterOutput(
          requestedPath: ValueReaders.stringValue(
            payload['requested_chapter_path'],
            ValueReaders.stringValue(
              pathResolution['requested_path'],
              ValueReaders.stringValue(
                payload['resolved_chapter_path'],
                ValueReaders.stringValue(payload['chapter_path']),
              ),
            ),
          ),
          explicitTitle: ValueReaders.stringValue(payload['title']),
          submissionTitle: ValueReaders.stringValue(submission['title']),
          chapterContent: '',
          chapterNumber: ValueReaders.intValue(
            pathResolution['chapter_number'],
          ),
        );
    final normalizedChapterPath =
        normalizedResolution.resolvedPath.trim().isEmpty
        ? ValueReaders.stringValue(
            payload['resolved_chapter_path'],
            ValueReaders.stringValue(payload['chapter_path']),
          )
        : normalizedResolution.resolvedPath.trim();
    final normalizedTitle = normalizedResolution.title.trim().isEmpty
        ? ValueReaders.stringValue(
            payload['title'],
            ValueReaders.stringValue(submission['title']),
          )
        : normalizedResolution.title.trim();
    final normalizedSubmission = _normalizedSubmissionProjection(
      submission,
      chapterPath: normalizedChapterPath,
      title: normalizedTitle,
    );
    final projectedPathResolution = pathResolution.isEmpty
        ? normalizedResolution.toJson()
        : <String, Object?>{
            ...pathResolution,
            'requested_path': ValueReaders.stringValue(
              pathResolution['requested_path'],
              normalizedResolution.requestedPath,
            ),
            'resolved_path': normalizedChapterPath,
            'title': normalizedTitle,
            'chapter_number': ValueReaders.intValue(
              pathResolution['chapter_number'],
              normalizedResolution.chapterNumber,
            ),
            'path_changed':
                ValueReaders.boolValue(pathResolution['path_changed']) ||
                normalizedResolution.pathChanged,
            'reason': ValueReaders.stringValue(
              pathResolution['reason'],
              normalizedResolution.reason,
            ),
          };
    return <String, Object?>{
      'tool_name': toolName,
      'outcome_status': outcomeStatus,
      'delivery_id': ValueReaders.stringValue(payload['delivery_id']),
      'chapter_path': normalizedChapterPath,
      'requested_chapter_path': ValueReaders.stringValue(
        payload['requested_chapter_path'],
        normalizedResolution.requestedPath,
      ),
      'resolved_chapter_path': normalizedChapterPath,
      'title': normalizedTitle,
      'delivery_state': ValueReaders.stringValue(payload['delivery_state']),
      'chapter_body_state': ValueReaders.stringValue(
        payload['chapter_body_state'],
      ),
      'sidecar_state': ValueReaders.stringValue(payload['sidecar_state']),
      'state_result': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(payload['state_result']),
      ),
      'path_resolution': ValueReaders.deepCopyMap(projectedPathResolution),
      'submission': normalizedSubmission,
      'constraint_coverage': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(payload['constraint_coverage']),
      ),
      'metadata': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(payload['metadata']),
      ),
    };
  }

  JsonMap _normalizedSubmissionProjection(
    JsonMap submission, {
    required String chapterPath,
    required String title,
  }) {
    if (submission.isEmpty) {
      return const <String, Object?>{};
    }
    final normalized = ValueReaders.deepCopyMap(submission);
    if (title.trim().isNotEmpty) {
      normalized['title'] = title.trim();
    }
    final chapterRef = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(normalized['chapter_ref']),
    );
    if (chapterRef.isNotEmpty) {
      chapterRef['ref_id'] = chapterPath;
      chapterRef['relative_path'] = chapterPath;
      if (title.trim().isNotEmpty) {
        chapterRef['display_name'] = title.trim();
      }
      normalized['chapter_ref'] = chapterRef;
    }
    return normalized;
  }
}
