import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Provider token count port adapter', () {
    test(
      'unavailable stub returns null instead of fabricating exact count',
      () async {
        // 中文注释: 当前阶段没有 provider 精算能力时，adapter 只能明确返回 null，不伪造 exact count。
        final port = UnavailableProviderTokenCountPort();
        final result = await port.countTokens(
          ProviderTokenCountRequest(
            providerId: 'openai',
            modelId: 'gpt-4.1',
            request: ChatRequest.textPrompt(
              prompt: '测试 token 计数',
              modelId: 'gpt-4.1',
            ),
          ),
        );

        expect(result, isNull);
      },
    );
  });
}
