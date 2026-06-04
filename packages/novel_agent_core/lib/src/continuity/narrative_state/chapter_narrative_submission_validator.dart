import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import 'chapter_narrative_submission.dart';
import 'chapter_narrative_submission_validation_codes.dart';
import 'narrative_ref.dart';
import 'narrative_segment.dart';
import 'narrative_transition.dart';

class ChapterNarrativeSubmissionValidator {
  const ChapterNarrativeSubmissionValidator({
    OpenJsonStructureValidatorService? structureValidatorService,
  }) : _structureValidatorService =
           structureValidatorService ??
           const OpenJsonStructureValidatorService();

  final OpenJsonStructureValidatorService _structureValidatorService;

  List<String> validateJson(JsonMap json) {
    return validate(ChapterNarrativeSubmission.fromJson(json));
  }

  List<String> validate(ChapterNarrativeSubmission submission) {
    final result = <String>[];
    result.addAll(submission.validateBasics());
    result.addAll(
      _validateRef(
        submission.chapterRef,
        ChapterNarrativeSubmissionValidationCodes.invalidChapterRef,
      ),
    );
    result.addAll(_validateSegments(submission.segments));
    result.addAll(
      _validateTransitions(submission.transitions, submission.segments),
    );
    return result;
  }

  List<String> _validateRef(NarrativeRef ref, String code) {
    return _structureValidatorService.requireCondition(
      ref.refType.trim().isNotEmpty && ref.refId.trim().isNotEmpty,
      code,
    );
  }

  List<String> _validateSegments(List<NarrativeSegment> segments) {
    final result = <String>[];
    final seenIds = <String>{};
    var lastOrderIndex = -2147483648;
    for (final segment in segments) {
      final segmentId = segment.segmentId.trim();
      if (segmentId.isNotEmpty) {
        if (!seenIds.add(segmentId)) {
          result.add(
            ChapterNarrativeSubmissionValidationCodes.duplicateSegmentId,
          );
        }
      }
      if (segment.orderIndex < lastOrderIndex) {
        result.add(
          ChapterNarrativeSubmissionValidationCodes.segmentOrderOutOfSequence,
        );
      }
      lastOrderIndex = segment.orderIndex;
    }
    return result;
  }

  List<String> _validateTransitions(
    List<NarrativeTransition> transitions,
    List<NarrativeSegment> segments,
  ) {
    final segmentIds = segments
        .map((segment) => segment.segmentId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final result = <String>[];
    for (final transition in transitions) {
      final fromSegmentId = transition.fromSegmentId.trim();
      final toSegmentId = transition.toSegmentId.trim();
      final referencesUnknownSegment =
          (fromSegmentId.isNotEmpty && !segmentIds.contains(fromSegmentId)) ||
          (toSegmentId.isNotEmpty && !segmentIds.contains(toSegmentId));
      result.addAll(
        _structureValidatorService.requireCondition(
          !referencesUnknownSegment,
          ChapterNarrativeSubmissionValidationCodes
              .transitionReferencesUnknownSegment,
        ),
      );
    }
    return result;
  }
}
