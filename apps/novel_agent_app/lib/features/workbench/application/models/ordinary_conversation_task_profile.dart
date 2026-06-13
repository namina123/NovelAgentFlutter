class OrdinaryConversationTaskProfile {
  const OrdinaryConversationTaskProfile({
    required this.taskType,
    required this.intent,
  });

  final String taskType;
  final String intent;

  bool get isPlanning => taskType == 'planning';
}
