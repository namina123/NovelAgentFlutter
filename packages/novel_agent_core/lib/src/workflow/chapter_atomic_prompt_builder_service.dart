import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_definition_service.dart';

class ChapterAtomicPromptBuilderService {
  ChapterAtomicPromptBuilderService({
    required TaskDefinitionService taskDefinitionService,
  }) : _taskDefinitionService = taskDefinitionService;

  final TaskDefinitionService _taskDefinitionService;

  JsonMap normalizeTask(JsonMap task) {
    // 中文注释: 章节原子执行包复用统一任务规范化，再补齐当前领域额外需要的字段。
    final normalized = _taskDefinitionService.normalizeTask(task);
    normalized['chapter'] = ValueReaders.stringValue(normalized['chapter']);
    normalized['goal'] = ValueReaders.stringValue(
      normalized['goal'],
      ValueReaders.stringValue(normalized['brief']),
    );
    normalized['brief'] = ValueReaders.stringValue(normalized['brief']);
    normalized['source_paths'] = ValueReaders.stringList(
      normalized['source_paths'],
    );
    normalized['depends_on'] = ValueReaders.stringList(
      normalized['depends_on'],
    );
    normalized['output_paths'] = ValueReaders.stringList(
      normalized['output_paths'],
    );
    return normalized;
  }

  String taskPrompt(JsonMap task) {
    // 中文注释: 任务查询文本只用于上下文检索，不直接当最终模型提示，所以保持结构化短文本。
    final lines = <String>[
      '任务标题：${ValueReaders.stringValue(task['title'])}',
      '章节：${ValueReaders.stringValue(task['chapter'])}',
      '目标：${ValueReaders.stringValue(task['goal'])}',
    ];
    final brief = ValueReaders.stringValue(task['brief']).trim();
    if (brief.isNotEmpty) {
      lines.add('简述：$brief');
    }
    final sources = ValueReaders.stringList(task['source_paths']);
    if (sources.isNotEmpty) {
      lines.add('来源文件：${sources.join('、')}');
    }
    return lines.join('\n');
  }
}
