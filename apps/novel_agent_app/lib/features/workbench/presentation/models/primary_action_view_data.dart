import 'package:novel_agent_core/novel_agent_core.dart';

class PrimaryActionViewData {
  const PrimaryActionViewData({
    required this.id,
    required this.title,
    required this.description,
    this.commandId = '',
    this.payload = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String description;
  final String commandId;
  final JsonMap payload;
}
