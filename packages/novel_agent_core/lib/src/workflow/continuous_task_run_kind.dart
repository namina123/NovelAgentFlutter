abstract final class ContinuousTaskRunKinds {
  static const String chapterQueue = 'chapter_queue';
  static const String conversationLoop = 'conversation_loop';
  static const String batchPipeline = 'batch_pipeline';
  static const String researchSweep = 'research_sweep';

  static const List<String> values = <String>[
    chapterQueue,
    conversationLoop,
    batchPipeline,
    researchSweep,
  ];

  static bool contains(String candidate) {
    // 中文注释: run kind 只表达推进形态，不承担 watchdog / supervisor 具体调度策略；这里先用稳定枚举避免后续合同漂移。
    return values.contains(candidate.trim());
  }
}
