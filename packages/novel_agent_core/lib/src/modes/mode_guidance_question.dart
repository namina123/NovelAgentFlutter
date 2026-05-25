import '../strategy/mode_stage_option.dart';

class ModeGuidanceQuestion {
  const ModeGuidanceQuestion({
    required this.modeId,
    required this.stageId,
    required this.fieldKey,
    required this.title,
    required this.description,
    required this.helperText,
    required this.allowFreeText,
    required this.progressText,
    this.options = const <ModeStageOption>[],
    this.isReadyToLaunch = false,
  });

  final String modeId;
  final String stageId;
  final String fieldKey;
  final String title;
  final String description;
  final String helperText;
  final bool allowFreeText;
  final String progressText;
  final List<ModeStageOption> options;
  final bool isReadyToLaunch;
}
