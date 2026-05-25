import 'mode_stage_option.dart';

class ModeStageDefinition {
  const ModeStageDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.fieldKey,
    this.helperText = '',
    this.allowFreeText = true,
    this.options = const <ModeStageOption>[],
  });

  final String id;
  final String title;
  final String description;
  final String fieldKey;
  final String helperText;
  final bool allowFreeText;
  final List<ModeStageOption> options;
}
