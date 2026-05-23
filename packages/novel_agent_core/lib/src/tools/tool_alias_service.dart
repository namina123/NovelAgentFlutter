import 'tool_alias_catalog.dart';

class ToolAliasService {
  String canonicalToolName(String toolName) {
    // 中文注释: 工具别名归一化集中在核心层，避免 GUI、CLI 和宿主执行器分别维护兼容表。
    final clean = toolName.trim();
    if (clean.isEmpty) {
      return '';
    }
    return ToolAliasCatalog.aliases[clean] ?? clean;
  }
}
