import '../agents/agent_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'frontmatter_yaml_writer_service.dart';

class AgentMarkdownPackageRendererService {
  AgentMarkdownPackageRendererService({
    AgentProfileNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ?? AgentProfileNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final AgentProfileNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String renderPackage(JsonMap agent) {
    // 中文注释: 智能体包渲染统一输出 AGENT.md，保证导入和导出都回到项目标准包结构。
    final normalized = _normalizerService.normalizeAgentProfile(agent);
    final body = ValueReaders.stringValue(
      normalized['operating_manual_markdown'],
      ValueReaders.stringValue(normalized['system_prompt']),
    ).trim();
    final frontmatter = <String, Object?>{
      'id': normalized['id'],
      'name': normalized['name'],
      'description': normalized['description'],
      'version': normalized['version'],
      'role': normalized['role'],
      'objective': normalized['objective'],
      'kpis': normalized['kpis'],
      'can_do': normalized['can_do'],
      'must_not_do': normalized['must_not_do'],
      'knowledge_sources': normalized['knowledge_sources'],
      'required_capabilities': normalized['required_capabilities'],
      'optional_capabilities': normalized['optional_capabilities'],
      'output_schema_path': normalized['output_schema_path'],
      'output_schema': normalized['output_schema'],
      'preferred_output': normalized['preferred_output'],
      'short_term_memory_policy': normalized['short_term_memory_policy'],
      'long_term_memory_paths': normalized['long_term_memory_paths'],
      'reflection_mode': normalized['reflection_mode'],
      'resource_hints': normalized['resource_hints'],
      'source': normalized['source'],
      'source_scope': normalized['source_scope'],
      'enabled_by_default': normalized['enabled_by_default'],
      'builtin_preset': normalized['builtin_preset'],
      'customizable': normalized['customizable'],
      'stages': normalized['stages'],
      'skills': normalized['skills'],
      'skill_groups': normalized['skill_groups'],
      'memory_path': normalized['memory_path'],
      'provider_profile': normalized['provider_profile'],
      'thinking_supported': normalized['thinking_supported'],
      'thinking_enabled': normalized['thinking_enabled'],
      'thinking_effort': normalized['thinking_effort'],
      'temperature': normalized['temperature'],
      'top_p': normalized['top_p'],
      'top_k': normalized['top_k'],
    };
    final markdownBody = body.isEmpty
        ? '# ${ValueReaders.stringValue(normalized["name"], ValueReaders.stringValue(normalized["id"]))}\n\n请补充这个智能体的操作手册。\n'
        : body;
    return '---\n${_yamlWriterService.write(frontmatter)}\n---\n\n$markdownBody\n';
  }
}
