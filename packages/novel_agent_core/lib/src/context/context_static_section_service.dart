import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_prompt_contract.dart';

class ContextStaticSectionService {
  ContextStaticSectionService({
    required ProjectPromptContract projectPromptContract,
  }) : _projectPromptContract = projectPromptContract;

  final ProjectPromptContract _projectPromptContract;

  List<JsonMap> buildStaticSections({
    required JsonMap project,
    required List<Object?> projectFiles,
    required String sessionContext,
    required String currentFileBody,
    required String currentFilePath,
    required String intent,
    required JsonMap agent,
    required List<Object?> optionalAgents,
  }) {
    // 中文注释: 静态片段只负责项目概况、边界和当前打开文件等高优先信息，不碰动态检索。
    final sections = <JsonMap>[
      <String, Object?>{
        'id': 'project_overview',
        'title': '项目概况',
        'priority': 100,
        'pinned': true,
        'content': projectOverview(project, intent),
      },
    ];
    sections.add(<String, Object?>{
      'id': 'agent_boundary',
      'title': '智能体边界',
      'priority': 96,
      'pinned': true,
      'content': agentBoundary(agent, optionalAgents),
    });
    if (projectFiles.isNotEmpty) {
      sections.add(<String, Object?>{
        'id': 'project_tree',
        'title': '项目目录',
        'priority': 92,
        'pinned': true,
        'content': projectTreeSummary(projectFiles),
      });
    }
    if (sessionContext.trim().isNotEmpty) {
      sections.add(<String, Object?>{
        'id': 'session_context',
        'title': '会话上下文',
        'priority': 94,
        'pinned': true,
        'content': sessionContext,
      });
    }
    if (currentFileBody.trim().isNotEmpty) {
      sections.add(<String, Object?>{
        'id': 'current_file',
        'title': '当前打开文件',
        'source': currentFilePath,
        'priority': 90,
        'pinned': true,
        'content': currentFileBody,
      });
    }
    return sections;
  }

  String projectOverview(JsonMap project, String intent) {
    // 中文注释: 项目概况由 prompt contract 统一生成，避免 context 与系统提示描述漂移。
    if (project.isEmpty) {
      return '当前没有打开项目。';
    }
    return _projectPromptContract.sessionInfo(project, intent);
  }

  String agentBoundary(JsonMap agent, List<Object?> optionalAgents) {
    // 中文注释: 智能体边界文本复用 project prompt contract，保持和系统提示中的边界表述一致。
    final mappedAgents = optionalAgents
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    return _projectPromptContract.agentBoundary(
      agent,
      optionalAgents: mappedAgents,
      maxAgents: 8,
    );
  }

  String projectTreeSummary(List<Object?> files) {
    // 中文注释: 文件树摘要由项目提示契约统一渲染，确保上下文和 prompt 看到同一目录映射。
    final mappedFiles = files
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    return _projectPromptContract.projectTreeSummary(
      mappedFiles,
      maxLines: 100,
    );
  }
}
