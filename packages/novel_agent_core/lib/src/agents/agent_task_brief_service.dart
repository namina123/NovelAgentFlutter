import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentTaskBriefService {
  String roleText(JsonMap agent) {
    // 中文注释: 任务匹配和摘要渲染都只需要一段低成本可搜索文本，这里统一拼装。
    return <String>[
      ValueReaders.stringValue(agent['id']),
      ValueReaders.stringValue(agent['name']),
      ValueReaders.stringValue(agent['role']),
      ValueReaders.stringValue(agent['description']),
    ].join(' ').toLowerCase();
  }

  String taskTextForAgent(JsonMap agent, String intent, String excerpt) {
    // 中文注释: 子智能体拿到的任务必须足够明确，不能再把“看看这个”式含糊输入传下去。
    final text = roleText(agent);
    if (text.contains('资料') || text.contains('research')) {
      return '只围绕摘录定位需要读取的设定、风格、摘要或知识库片段，并列出建议读取路径。摘录：$excerpt';
    }
    if (text.contains('文风') || text.contains('prose')) {
      return '基于摘录检查语言节奏、对白质感、AI 腔和风格一致性，只给修改建议。摘录：$excerpt';
    }
    if (text.contains('读者') || text.contains('reader')) {
      return '从读者体验判断悬念、爽点、疑惑和继续阅读动机。摘录：$excerpt';
    }
    if (text.contains('设定') || text.contains('continuity')) {
      return '检查设定、角色状态、时间线和规则连续性风险。摘录：$excerpt';
    }
    if (text.contains('剧情') || text.contains('plot') || intent == 'outline') {
      return '检查结构、冲突升级、转折和伏笔安排。摘录：$excerpt';
    }
    if (text.contains('作者') || text.contains('writer')) {
      return '在给定约束内产出正文或修订草案，不擅自改写项目文件。摘录：$excerpt';
    }
    return '根据你的职责处理本轮任务，并返回简洁可合并的建议。摘录：$excerpt';
  }

  String expectedOutputForAgent(JsonMap agent, String intent) {
    // 中文注释: 期望产物会被主智能体和后续验收逻辑复用，因此单独抽成纯规则方法。
    final text = roleText(agent);
    if (text.contains('资料') || text.contains('research')) {
      return '相关资料路径和摘录清单';
    }
    if (text.contains('文风') || text.contains('prose')) {
      return '文风审稿建议';
    }
    if (text.contains('读者') || text.contains('reader')) {
      return '读者反馈';
    }
    if (text.contains('设定') || text.contains('continuity')) {
      return '连续性风险清单';
    }
    if (text.contains('剧情') || text.contains('plot') || intent == 'outline') {
      return '结构与剧情建议';
    }
    if (text.contains('作者') || text.contains('writer')) {
      return '草稿或修订片段';
    }
    return '可合并建议';
  }

  String shortPreview(String value, int maxChars) {
    // 中文注释: 协作摘要只保留一行短预览，避免把系统提示和调试视图撑爆。
    final clean = value.trim().replaceAll('\n', ' ');
    if (maxChars <= 0) {
      return '';
    }
    if (clean.length <= maxChars) {
      return clean;
    }
    return '${clean.substring(0, maxChars)}...';
  }
}
