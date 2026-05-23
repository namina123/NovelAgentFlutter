import '../common/value_readers.dart';
import 'agent_task_brief_service.dart';

class AgentSelectionService {
  AgentSelectionService({AgentTaskBriefService? taskBriefService})
    : _taskBriefService = taskBriefService ?? AgentTaskBriefService();

  final AgentTaskBriefService _taskBriefService;

  String selectAgentIdForTask(String task, List<Object?> availableAgents) {
    // 中文注释: 当模型没显式给出 agent_id 时，这里用弱规则兜底，保证协作链还能往前走。
    final text = task.toLowerCase();
    const rules = <Map<String, String>>[
      <String, String>{'needle': '大纲', 'role_hint': 'outline'},
      <String, String>{'needle': '结构', 'role_hint': 'outline'},
      <String, String>{'needle': '剧情', 'role_hint': 'plot'},
      <String, String>{'needle': '润色', 'role_hint': 'prose'},
      <String, String>{'needle': '文风', 'role_hint': 'prose'},
      <String, String>{'needle': '审核', 'role_hint': 'review'},
      <String, String>{'needle': '连续性', 'role_hint': 'continuity'},
      <String, String>{'needle': '读者', 'role_hint': 'reader'},
      <String, String>{'needle': '资料', 'role_hint': 'research'},
      <String, String>{'needle': '设定', 'role_hint': 'continuity'},
    ];
    for (final rule in rules) {
      final needle = rule['needle']!;
      if (!text.contains(needle)) {
        continue;
      }
      for (final rawAgent in availableAgents) {
        final agent = ValueReaders.mapValue(rawAgent);
        final role = _taskBriefService.roleText(agent);
        if (role.contains(needle) || role.contains(rule['role_hint']!)) {
          return ValueReaders.stringValue(agent['id']);
        }
      }
    }
    for (final rawAgent in availableAgents) {
      final agent = ValueReaders.mapValue(rawAgent);
      final id = ValueReaders.stringValue(agent['id']).trim();
      if (id.isNotEmpty) {
        return id;
      }
    }
    return '';
  }
}
