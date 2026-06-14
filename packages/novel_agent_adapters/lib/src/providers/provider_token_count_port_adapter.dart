import 'package:novel_agent_core/novel_agent_core.dart';

class UnavailableProviderTokenCountPort extends ProviderTokenCountPort {
  UnavailableProviderTokenCountPort();

  @override
  Future<ProviderTokenCountResult?> countTokens(
    ProviderTokenCountRequest request,
  ) async {
    // 中文注释: 这里作为当前阶段的默认 stub，只声明“暂不可用”，不伪造 exact count 结果。
    return null;
  }
}
