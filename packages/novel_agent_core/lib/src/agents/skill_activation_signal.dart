import '../common/json_types.dart';

class SkillActivationSignal {
  const SkillActivationSignal({
    required this.stageId,
    required this.intent,
    required this.taskType,
    required this.projectType,
    required this.userPrompt,
    this.mode = '',
    this.flags = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String stageId;
  final String intent;
  final String taskType;
  final String projectType;
  final String userPrompt;
  final String mode;
  final List<String> flags;
  final JsonMap metadata;

  bool hasFlag(String flag) {
    // 中文注释: 触发信号的判断集中在模型对象内，避免上层到处手写 contains。
    return flags.contains(flag);
  }
}
