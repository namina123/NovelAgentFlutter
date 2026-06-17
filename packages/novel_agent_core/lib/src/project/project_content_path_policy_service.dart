class ProjectContentPathPolicyService {
  const ProjectContentPathPolicyService();

  static const String premiseRoot = 'premise';
  static const String outlinesRoot = 'outlines';
  static const String chaptersRoot = 'chapters';
  static const String samplesRoot = 'samples';
  static const String scenesRoot = 'scenes';
  static const String assetsRoot = 'assets';
  static const String knowledgeRoot = 'knowledge';
  static const String researchRoot = 'research';
  static const String analysisRoot = 'analysis';
  static const String sourcesRoot = 'sources';
  static const String inheritedChapterRoot = 'chapters/inherited';
  static const String tasksRoot = 'tasks';
  static const String exportsRoot = 'exports';

  String defaultWorkspaceFileDirectory() {
    // 中文注释: 通用新建文件继续落到章节正文目录，确保 GUI/CLI 的默认出口一致。
    return chaptersRoot;
  }

  String defaultWorkspaceFolderDirectory() {
    // 中文注释: 通用新建文件夹优先进入资产根目录，避免把用户的正式内容又引回旧兼容根。
    return assetsRoot;
  }

  String defaultImportTargetDirectory() {
    // 中文注释: 外部导入默认进入资产根目录，后续可再按资源类型分流，不把未知文件直接混入正文。
    return assetsRoot;
  }

  String normalizeContentType(String value) {
    // 中文注释: 内容类型归一化集中在 core，保证路径策略、标签投影和工具写入使用同一套语义。
    final clean = value.trim().toLowerCase();
    switch (clean) {
      case '大纲':
        return 'outline';
      case '卷纲':
      case '卷钢':
        return 'volume_outline';
      case '章纲':
        return 'chapter_outline';
      case '正文':
      case '正式正文':
      case '正文章节':
      case 'narrative_chapter':
      case 'formal_chapter':
        return 'chapter';
      case '样章':
      case '样章正文':
      case 'sample_chapter':
      case 'sample':
        return 'sample';
      case '场景':
      case 'scene':
      case 'working_draft':
      case '正文草稿':
      case '草稿':
        return 'scene';
      case '设定':
      case 'world':
        return 'setting';
      case '角色':
        return 'character';
      case '风格':
        return 'style';
      case '摘要':
      case '概括':
        return 'summary';
      case '分析':
      case 'analysis':
      case '提取':
      case 'extraction':
      case 'extraction_output':
        return 'analysis';
      case '知识库':
      case '知识':
      case '研究':
      case 'information':
      case 'research':
      case 'research_note':
      case 'research_notes':
      case 'knowledge_card':
      case 'design_element':
      case 'reference_work':
        return 'knowledge';
      case '原文归档':
      case 'source_original':
        return 'source_original';
      case '派生续写':
      case 'derived_continuation_narrative':
        return 'derived_continuation_narrative';
      case '派生同人':
      case 'derived_fanfic_narrative':
        return 'derived_fanfic_narrative';
      default:
        return clean.isEmpty ? 'chapter' : clean;
    }
  }

  String directoryForContentType(String contentType) {
    // 中文注释: 内容类型到主目录的映射只在这里定一次，避免 adapters/app 各自拼默认归档位置。
    switch (normalizeContentType(contentType)) {
      case 'outline':
        return 'outlines/story';
      case 'volume_outline':
        return 'outlines/volumes';
      case 'chapter_outline':
        return 'outlines/chapters';
      case 'chapter':
        return chaptersRoot;
      case 'sample':
        return samplesRoot;
      case 'scene':
        return scenesRoot;
      case 'setting':
        return 'assets/world';
      case 'character':
        return 'assets/characters';
      case 'style':
        return 'assets/styles';
      case 'summary':
        return 'summaries';
      case 'analysis':
        return analysisRoot;
      case 'knowledge':
        return knowledgeRoot;
      case 'source_original':
        return '$sourcesRoot/original';
      case 'derived_continuation_narrative':
        return '$inheritedChapterRoot/continuation';
      case 'derived_fanfic_narrative':
        return '$inheritedChapterRoot/fanfic';
      default:
        return chaptersRoot;
    }
  }

  String inferContentTypeFromPath(String relativePath) {
    // 中文注释: 从路径反推内容类型时同样走正式目录口径，避免兼容层和默认层判断分裂。
    final clean = relativePath.trim().replaceAll('\\', '/');
    if (clean.isEmpty) {
      return 'chapter';
    }
    final parts = clean.split('/');
    final root = parts.first;
    switch (root) {
      case sourcesRoot:
        if (parts.length > 1 && parts[1] == 'original') {
          return 'source_original';
        }
        return 'source_original';
      case 'chapters':
        if (parts.length > 2 && parts[1] == 'inherited') {
          final route = parts[2].toLowerCase();
          if (route.startsWith('fanfic')) {
            return 'derived_fanfic_narrative';
          }
          if (route.startsWith('continuation')) {
            return 'derived_continuation_narrative';
          }
        }
        return 'chapter';
      case 'assets':
        final second = parts.length > 1 ? parts[1] : '';
        switch (second) {
          case 'characters':
            return 'character';
          case 'world':
            return 'setting';
          case 'styles':
            return 'style';
        }
        return 'chapter';
      case knowledgeRoot:
      case researchRoot:
        return 'knowledge';
      case 'outlines':
        final second = parts.length > 1 ? parts[1] : '';
        switch (second) {
          case 'story':
            return 'outline';
          case 'volumes':
            return 'volume_outline';
          case 'chapters':
            return 'chapter_outline';
        }
        return 'chapter';
      case 'outline':
        return 'outline';
      case 'volume_outlines':
        return 'volume_outline';
      case 'chapter_outlines':
        return 'chapter_outline';
      case scenesRoot:
        return 'scene';
      case samplesRoot:
        return 'sample';
      case 'world':
        return 'setting';
      case 'characters':
        return 'character';
      case 'styles':
        return 'style';
      case 'summaries':
        return 'summary';
      case analysisRoot:
        return 'analysis';
      case '.novel_agent':
        if (parts.length > 2 && parts[1] == 'information') {
          final second = parts[2];
          switch (second) {
            case 'knowledge_cards':
            case 'design_elements':
            case 'research_notes':
            case 'reference_works':
              return 'knowledge';
          }
        }
        return 'analysis';
      default:
        return 'chapter';
    }
  }
}
