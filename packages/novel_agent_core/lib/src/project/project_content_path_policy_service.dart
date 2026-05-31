class ProjectContentPathPolicyService {
  const ProjectContentPathPolicyService();

  static const String premiseRoot = 'premise';
  static const String outlinesRoot = 'outlines';
  static const String chaptersRoot = 'chapters';
  static const String scenesRoot = 'scenes';
  static const String assetsRoot = 'assets';
  static const String tasksRoot = 'tasks';
  static const String analysisRoot = 'analysis';
  static const String exportsRoot = 'exports';

  String defaultWorkspaceFileDirectory() {
    // 中文注释: 通用“新建文件”默认落到章节正文目录，避免 GUI/CLI 再退回已经废弃的 drafts 语义。
    return chaptersRoot;
  }

  String defaultWorkspaceFolderDirectory() {
    // 中文注释: 通用“新建文件夹”优先落到资产根目录，让用户从当前正式可见目录继续扩展，而不是写回旧兼容根。
    return assetsRoot;
  }

  String defaultImportTargetDirectory() {
    // 中文注释: 外部文件导入默认进入 assets 根目录，便于后续再按资源类型整理，不把未知文件直接混入章节目录。
    return assetsRoot;
  }

  String normalizeContentType(String value) {
    // 中文注释: 内容类型归一化集中在 core，确保保存草稿、工具写入和宿主默认目录始终使用同一套语义。
    final clean = value.trim().toLowerCase();
    switch (clean) {
      case '大纲':
        return 'outline';
      case '卷纲':
      case '卷钢':
        return 'volume_outline';
      case '章纲':
        return 'chapter_outline';
      case '草稿':
      case '正文草稿':
      case 'working_draft':
        return 'scene';
      case '场景':
      case 'scene':
        return 'scene';
      case '正文':
      case '正式正文':
      case 'final_chapter':
        return 'chapter';
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
      case '知识库':
        return 'knowledge';
      default:
        return clean.isEmpty ? 'chapter' : clean;
    }
  }

  String directoryForContentType(String contentType) {
    // 中文注释: 内容类型到主目录的映射在这里维持一份，避免 adapters 和 app 各自发明默认归档位置。
    switch (normalizeContentType(contentType)) {
      case 'outline':
        return 'outline';
      case 'volume_outline':
        return 'volume_outlines';
      case 'chapter_outline':
        return 'chapter_outlines';
      case 'chapter':
        return chaptersRoot;
      case 'scene':
        return scenesRoot;
      case 'setting':
        return 'world';
      case 'character':
        return 'assets/characters';
      case 'style':
        return 'styles';
      case 'summary':
        return 'summaries';
      case 'knowledge':
        return 'knowledge';
      default:
        return chaptersRoot;
    }
  }

  String inferContentTypeFromPath(String relativePath) {
    // 中文注释: 从路径反推内容类型时也走同一套正式目录口径，避免兼容层和默认层判断分裂。
    final clean = relativePath.trim().replaceAll('\\', '/');
    if (clean.isEmpty) {
      return 'chapter';
    }
    final parts = clean.split('/');
    final root = parts.first;
    switch (root) {
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
      case 'outline':
        return 'outline';
      case 'volume_outlines':
        return 'volume_outline';
      case 'chapter_outlines':
        return 'chapter_outline';
      case chaptersRoot:
        return 'chapter';
      case scenesRoot:
        return 'scene';
      case 'world':
        return 'setting';
      case 'characters':
        return 'character';
      case 'styles':
        return 'style';
      case 'summaries':
        return 'summary';
      case 'knowledge':
        return 'knowledge';
      default:
        return 'chapter';
    }
  }
}
