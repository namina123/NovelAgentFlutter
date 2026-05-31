import '../common/json_types.dart';
import '../common/value_readers.dart';

class ExpressionConstraintReviewProjection {
  const ExpressionConstraintReviewProjection({
    this.authenticityPassLevel = authenticityDisabled,
    this.reviewFocuses = const <String>[],
    this.continuityWatchItems = const <String>[],
    this.miniRecheckItems = const <String>[],
    this.voiceProtectionNotes = const <String>[],
  });

  static const String authenticityDisabled = 'disabled';
  static const String authenticityLight = 'light';
  static const String authenticityMedium = 'medium';
  static const String authenticityAggressive = 'aggressive';

  final String authenticityPassLevel;
  final List<String> reviewFocuses;
  final List<String> continuityWatchItems;
  final List<String> miniRecheckItems;
  final List<String> voiceProtectionNotes;

  bool get isEmpty =>
      authenticityPassLevel == authenticityDisabled &&
      reviewFocuses.isEmpty &&
      continuityWatchItems.isEmpty &&
      miniRecheckItems.isEmpty &&
      voiceProtectionNotes.isEmpty;

  JsonMap toJson() {
    return <String, Object?>{
      'authenticity_pass_level': authenticityPassLevel,
      'review_focuses': reviewFocuses,
      'continuity_watch_items': continuityWatchItems,
      'mini_recheck_items': miniRecheckItems,
      'voice_protection_notes': voiceProtectionNotes,
    };
  }

  static ExpressionConstraintReviewProjection fromJson(JsonMap raw) {
    return ExpressionConstraintReviewProjection(
      authenticityPassLevel: ValueReaders.stringValue(
        raw['authenticity_pass_level'],
        authenticityDisabled,
      ),
      reviewFocuses: ValueReaders.stringList(raw['review_focuses']),
      continuityWatchItems: ValueReaders.stringList(
        raw['continuity_watch_items'],
      ),
      miniRecheckItems: ValueReaders.stringList(raw['mini_recheck_items']),
      voiceProtectionNotes: ValueReaders.stringList(
        raw['voice_protection_notes'],
      ),
    );
  }
}
