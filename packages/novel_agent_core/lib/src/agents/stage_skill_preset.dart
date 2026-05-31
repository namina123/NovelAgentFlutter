class StageSkillPreset {
  const StageSkillPreset({
    required this.skillId,
    this.preloadDetailLevel = 'summary',
    this.referencePaths = const <String>[],
    this.reason = '',
  });

  final String skillId;
  final String preloadDetailLevel;
  final List<String> referencePaths;
  final String reason;
}
