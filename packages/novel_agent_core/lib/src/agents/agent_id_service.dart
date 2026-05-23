class AgentIdService {
  String safeAgentId(String value) {
    // 中文注释: 智能体 id 会进入索引和默认记忆路径，因此这里集中裁掉非法文件名字符。
    var result = value.trim();
    for (final token in const <String>[
      '\\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
      '\n',
      '\r',
      '\t',
      ' ',
    ]) {
      result = result.replaceAll(token, '_');
    }
    if (result.length > 64) {
      result = result.substring(0, 64);
    }
    return result;
  }
}
