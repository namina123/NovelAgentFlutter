import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentGroupValidatorService {
  JsonMap validate(JsonMap group) {
    final errors = <String>[];
    final warnings = <String>[];
    final id = ValueReaders.stringValue(group['id']).trim();
    final name = ValueReaders.stringValue(group['name']).trim();
    final description = ValueReaders.stringValue(group['description']).trim();
    final version = ValueReaders.stringValue(group['version'], '1').trim();
    final orchestration = ValueReaders.stringValue(
      group['orchestration'],
      'supervised',
    ).trim();
    final agents = ValueReaders.stringList(group['agents']);
    if (id.isEmpty) {
      errors.add('智能体组缺少 id。');
    }
    if (name.isEmpty) {
      errors.add('智能体组缺少 name。');
    }
    if (description.isEmpty) {
      errors.add('智能体组缺少 description。');
    }
    if (version.isEmpty) {
      errors.add('智能体组缺少 version。');
    }
    if (orchestration.isEmpty) {
      errors.add('智能体组缺少 orchestration。');
    }
    if (agents.isEmpty) {
      warnings.add('建议至少声明一个 agent，避免空智能体组进入 proposal 流程。');
    }
    return <String, Object?>{
      'ok': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }
}
