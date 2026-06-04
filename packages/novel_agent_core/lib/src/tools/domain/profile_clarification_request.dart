import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'profile_clarification_option.dart';
import 'profile_clarification_validation_codes.dart';

class ProfileClarificationRequest {
  const ProfileClarificationRequest({
    required this.question,
    this.options = const <ProfileClarificationOption>[],
    this.freeformAllowed = false,
    this.reason = '',
    this.blocking = true,
    this.metadata = const <String, Object?>{},
  });

  final String question;
  final List<ProfileClarificationOption> options;
  final bool freeformAllowed;
  final String reason;
  final bool blocking;
  final JsonMap metadata;

  factory ProfileClarificationRequest.fromJson(JsonMap json) {
    return ProfileClarificationRequest(
      question: ValueReaders.stringValue(json['question']).trim(),
      options: ValueReaders.mapList(
        json['options'],
      ).map(ProfileClarificationOption.fromJson).toList(growable: false),
      freeformAllowed: ValueReaders.boolValue(json['freeform_allowed']),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      blocking: ValueReaders.boolValue(json['blocking'], true),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'question': question,
      'options': options.map((entry) => entry.toJson()).toList(growable: false),
      'freeform_allowed': freeformAllowed,
      'reason': reason,
      'blocking': blocking,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (question.trim().isEmpty) {
      result.add(ProfileClarificationValidationCodes.missingQuestion);
    }
    if (options.isEmpty) {
      result.add(ProfileClarificationValidationCodes.missingOptions);
    }
    if (options.length > 5) {
      result.add(ProfileClarificationValidationCodes.tooManyOptions);
    }
    result.addAll(options.expand((entry) => entry.validateBasics()));
    return result;
  }
}
