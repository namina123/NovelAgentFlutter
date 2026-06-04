import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'profile_clarification_validation_codes.dart';

class ProfileClarificationOption {
  const ProfileClarificationOption({
    required this.label,
    this.optionId = '',
    this.description = '',
    this.optionPayload = const <String, Object?>{},
  });

  final String label;
  final String optionId;
  final String description;
  final JsonMap optionPayload;

  factory ProfileClarificationOption.fromJson(JsonMap json) {
    return ProfileClarificationOption(
      label: ValueReaders.stringValue(
        json['label'],
        ValueReaders.stringValue(json['title']),
      ).trim(),
      optionId: ValueReaders.stringValue(
        json['option_id'],
        ValueReaders.stringValue(json['id']),
      ).trim(),
      description: ValueReaders.stringValue(
        json['description'],
        ValueReaders.stringValue(json['reason']),
      ).trim(),
      optionPayload: ValueReaders.deepCopyMap(json),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(optionPayload),
      'label': label,
      if (optionId.isNotEmpty) 'option_id': optionId,
      if (description.isNotEmpty) 'description': description,
    };
  }

  List<String> validateBasics() {
    if (label.trim().isEmpty) {
      return const <String>[
        ProfileClarificationValidationCodes.missingOptionLabel,
      ];
    }
    return const <String>[];
  }
}
