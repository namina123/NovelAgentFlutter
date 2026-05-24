import '../common/json_types.dart';
import 'llm_stream_update.dart';

abstract class LlmGateway {
  Future<JsonMap> requestChat({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  });

  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    // 中文注释: 旧的一次性文本接口保留下来，方便现有轻量用例在升级网关后继续复用。
    final result = await requestChat(
      messages: const <JsonMap>[],
      modelId: modelId,
      options: <String, Object?>{'prompt': prompt},
    );
    final content = result['content']?.toString().trim() ?? '';
    if (content.isEmpty) {
      throw const FormatException('响应中缺少可读文本内容。');
    }
    return content;
  }
}
