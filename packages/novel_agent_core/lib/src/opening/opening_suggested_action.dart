import '../common/json_types.dart';

class OpeningSuggestedAction {
  const OpeningSuggestedAction({
    required this.id,
    required this.commandId,
    required this.title,
    required this.description,
    this.payload = const <String, Object?>{},
  });

  final String id;
  final String commandId;
  final String title;
  final String description;
  final JsonMap payload;
}
