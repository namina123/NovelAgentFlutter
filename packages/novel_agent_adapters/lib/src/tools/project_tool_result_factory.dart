import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectToolResultFactory {
  JsonMap success(
    String displayText, {
    JsonMap data = const <String, Object?>{},
  }) {
    // 中文注释: 项目工具结果统一在这里补齐 display_text 和 changed_paths，避免每个执行器各自拼格式。
    return <String, Object?>{
      'ok': true,
      'display_text': displayText,
      'changed_paths': ValueReaders.stringList(data['changed_paths']),
      ...data,
    };
  }

  JsonMap error(String message, {JsonMap data = const <String, Object?>{}}) {
    // 中文注释: 错误结果格式统一后，工具循环和 UI/CLI 才能稳定展示失败原因。
    return <String, Object?>{
      'ok': false,
      'error': message,
      'display_text': message,
      'changed_paths': ValueReaders.stringList(data['changed_paths']),
      ...data,
    };
  }

  JsonMap notExecuted(
    String message, {
    JsonMap data = const <String, Object?>{},
  }) {
    // 中文注释: 已识别但暂未执行的工具要和真正失败区分开，避免主循环被误判成硬错误。
    return <String, Object?>{
      'ok': false,
      'not_executed': true,
      'error': message,
      'display_text': message,
      'changed_paths': ValueReaders.stringList(data['changed_paths']),
      ...data,
    };
  }
}
