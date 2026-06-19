class ProjectRagExtractionModeId {
  static const String structuredKnowledge = 'structured_knowledge';
  static const String ragExtraction = 'rag_extraction';
  static const String mixedExtraction = 'mixed_extraction';

  static const List<String> values = <String>[
    structuredKnowledge,
    ragExtraction,
    mixedExtraction,
  ];

  static String labelOf(String modeId) {
    // 中文注释: 模式标识只在 app 层投影为短标签，不把展示文案下沉进共享合同。
    switch (modeId.trim()) {
      case structuredKnowledge:
        return '结构化知识';
      case ragExtraction:
        return '语料提取';
      case mixedExtraction:
        return '混合提取';
      default:
        return modeId.trim();
    }
  }

  static String summaryOf(String modeId) {
    // 中文注释: 每个入口只给一条清晰摘要，避免模式卡片变成说明书。
    switch (modeId.trim()) {
      case structuredKnowledge:
        return '保留给后续的结构化知识提取分支，当前仅作正式合同占位。';
      case ragExtraction:
        return '第一阶段开放的语料提取分支，先支持 txt 构建与项目挂载。';
      case mixedExtraction:
        return '保留给后续的混合提取分支，当前只声明入口，不扩展实现。';
      default:
        return '未识别的提取模式。';
    }
  }

  static bool isImplemented(String modeId) {
    // 中文注释: 第一阶段只让语料提取真正可执行，其他模式保持合同占位。
    return modeId.trim() == ragExtraction;
  }
}
