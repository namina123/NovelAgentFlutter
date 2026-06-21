import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../system_proxy_resolver.dart';
import 'rag_retrieval_provider_contracts.dart';

/// 远程 embedding POST 的可注入合同，便于单测用假实现替换真实网络。
typedef EmbeddingHttpPost = Future<JsonMap> Function({
  required Uri requestUri,
  required String apiKey,
  required JsonMap body,
  required Duration timeout,
});

/// 远程 OpenAI 兼容 embedding provider：POST {baseUrl}/v1/embeddings，解析 data[].embedding。
///
/// 中文注释: 这是首个真正可用的 embedding provider，复用 SystemProxyResolver 的代理处理，
/// 与"测试连接"保持同一套联网口径；本地 ONNX provider 作为可选项另行接入。
class RemoteOpenAiCompatibleEmbeddingProvider implements EmbeddingProviderPort {
  RemoteOpenAiCompatibleEmbeddingProvider({
    required String providerId,
    required String baseUrl,
    required String apiKey,
    required String modelId,
    EmbeddingHttpPost? post,
    Duration timeout = const Duration(seconds: 30),
  }) : _providerId = providerId,
       _baseUrl = baseUrl,
       _apiKey = apiKey,
       _modelId = modelId,
       _post = post ?? systemProxyEmbeddingHttpPost,
       _timeout = timeout;

  final String _providerId;
  final String _baseUrl;
  final String _apiKey;
  final String _modelId;
  final EmbeddingHttpPost _post;
  final Duration _timeout;

  @override
  String get providerId => _providerId;

  @override
  String get providerKind => RagRetrievalProviderKinds.remoteOpenAiCompatible;

  @override
  bool get isLocal => false;

  @override
  bool get isRemote => true;

  @override
  Future<List<List<num>>> embedTexts(List<String> texts) async {
    if (texts.isEmpty) {
      return const <List<num>>[];
    }
    final response = await _post(
      requestUri: _embeddingsEndpoint(),
      apiKey: _apiKey,
      body: <String, Object?>{'model': _modelId, 'input': texts},
      timeout: _timeout,
    );
    final data = ValueReaders.objectList(response['data']);
    final result = <List<num>>[];
    for (final item in data) {
      final embedding = ValueReaders.mapValue(item)['embedding'];
      if (embedding is! List) {
        continue;
      }
      result.add(
        embedding
            .map((entry) => (entry as num).toDouble())
            .toList(growable: false),
      );
    }
    return result;
  }

  @override
  JsonMap describeCapabilities() {
    return <String, Object?>{
      'provider_kind': providerKind,
      'is_local': false,
      'is_remote': true,
      'model_id': _modelId,
      'base_url': _baseUrl,
    };
  }

  Uri _embeddingsEndpoint() {
    // 中文注释: 兼容 baseUrl 是否带 /v1 后缀，统一落到 .../v1/embeddings。
    final raw = _baseUrl.trim();
    final root = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    final path = root.endsWith('/v1') ? '$root/embeddings' : '$root/v1/embeddings';
    return Uri.parse(path);
  }
}

/// 默认的代理感知 embedding POST：复用 SystemProxyResolver，与网关/测试连接同一代理口径。
Future<JsonMap> systemProxyEmbeddingHttpPost({
  required Uri requestUri,
  required String apiKey,
  required JsonMap body,
  required Duration timeout,
}) async {
  final resolver = const SystemProxyResolver();
  final proxy = await resolver.resolveFor(requestUri);
  final client = HttpClient()..connectionTimeout = timeout;
  client.findProxy = (_) => proxy;
  try {
    final request = await client.postUrl(requestUri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close().timeout(timeout);
    final payload = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'embedding 请求失败：HTTP ${response.statusCode} ${_preview(payload)}',
      );
    }
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('embedding 响应不是 JSON 对象：${_preview(payload)}');
    }
    return decoded;
  } finally {
    client.close(force: true);
  }
}

String _preview(String value) {
  final normalized = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
  return normalized.length <= 160 ? normalized : normalized.substring(0, 160);
}
