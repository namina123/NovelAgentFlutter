import 'stage_skill_preset.dart';

class SkillRoutingPolicy {
  const SkillRoutingPolicy({
    required this.stageId,
    required this.presets,
    this.notes = const <String>[],
  });

  final String stageId;
  final List<StageSkillPreset> presets;
  final List<String> notes;
}
