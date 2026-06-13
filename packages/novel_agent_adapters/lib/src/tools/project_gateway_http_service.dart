import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectGatewayHttpService {
  ProjectGatewayHttpService({HttpClient Function()? httpClientFactory})
    : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final HttpClient Function() _httpClientFactory;

  Future<GatewayHttpFetchResult> fetchText({
    required String url,
    String method = 'GET',
    JsonMap headers = const <String, Object?>{},
    String body = '',
    int maxChars = 24000,
  }) async {
    // 中文注释: 联网抓取只负责把远程文本安全拉回本地，不参与上层工具结果拼装和提示文案。
    final uri = Uri.parse(url);
    final client = _httpClientFactory()
      ..connectionTimeout = const Duration(seconds: 20)
      ..userAgent = 'NovelAgentFlutter/0.1';
    try {
      final request = await client.openUrl(method.toUpperCase(), uri);
      for (final entry in headers.entries) {
        final key = entry.key.trim();
        if (key.isEmpty || entry.value == null) {
          continue;
        }
        request.headers.set(key, entry.value.toString());
      }
      if (body.isNotEmpty) {
        request.add(utf8.encode(body));
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final normalizedMaxChars = maxChars < 1000 ? 1000 : maxChars;
      final truncated = responseBody.length > normalizedMaxChars;
      final safeContent = truncated
          ? responseBody.substring(0, normalizedMaxChars)
          : responseBody;
      return GatewayHttpFetchResult(
        statusCode: response.statusCode,
        contentType: response.headers.contentType?.mimeType ?? '',
        body: safeContent,
        truncated: truncated,
      );
    } finally {
      client.close(force: true);
    }
  }

  List<JsonMap> parseSearchResults(String html, {required int limit}) {
    // 中文注释: 搜索结果先做轻量 HTML 提取，返回标题/链接/摘要，足够支撑工具链继续规划和引用。
    final results = <JsonMap>[];
    final titlePattern = RegExp(
      r'<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)</a>',
      caseSensitive: false,
    );
    final snippetPattern = RegExp(
      r'<a[^>]*class="result__snippet"[^>]*>([\s\S]*?)</a>|<div[^>]*class="result__snippet"[^>]*>([\s\S]*?)</div>',
      caseSensitive: false,
    );
    final titleMatches = titlePattern.allMatches(html).toList(growable: false);
    final snippetMatches = snippetPattern
        .allMatches(html)
        .toList(growable: false);
    for (var index = 0; index < titleMatches.length; index++) {
      final titleMatch = titleMatches[index];
      final url = _decodeHtml(titleMatch.group(1) ?? '').trim();
      final title = _stripHtml(titleMatch.group(2) ?? '').trim();
      final snippetMatch = index < snippetMatches.length
          ? snippetMatches[index]
          : null;
      final snippet = _stripHtml(
        snippetMatch?.group(1) ?? snippetMatch?.group(2) ?? '',
      ).trim();
      if (title.isEmpty || url.isEmpty) {
        continue;
      }
      results.add(<String, Object?>{
        'title': title,
        'url': url,
        'snippet': snippet,
      });
      if (results.length >= limit) {
        break;
      }
    }
    if (results.length < limit) {
      results.addAll(
        _parseGenericSearchResults(
          html,
          limit: limit - results.length,
          seenUrls: results
              .map((entry) => ValueReaders.stringValue(entry['url']))
              .toSet(),
        ),
      );
    }
    return results;
  }

  List<JsonMap> _parseGenericSearchResults(
    String html, {
    required int limit,
    required Set<String> seenUrls,
  }) {
    final results = <JsonMap>[];
    final anchorPattern = RegExp(
      r'<a[^>]*href="([^"]+)"[^>]*>([\s\S]{0,240}?)</a>',
      caseSensitive: false,
    );
    for (final match in anchorPattern.allMatches(html)) {
      final url = _decodeHtml(match.group(1) ?? '').trim();
      final title = _stripHtml(match.group(2) ?? '').trim();
      if (title.isEmpty ||
          !url.startsWith('http') ||
          seenUrls.contains(url) ||
          _isSearchEngineNavigationUrl(url)) {
        continue;
      }
      seenUrls.add(url);
      results.add(<String, Object?>{'title': title, 'url': url, 'snippet': ''});
      if (results.length >= limit) {
        break;
      }
    }
    return results;
  }

  bool _isSearchEngineNavigationUrl(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';
    return host.contains('duckduckgo.com') ||
        host.contains('bing.com') ||
        host.contains('baidu.com') ||
        url.contains('/settings') ||
        url.contains('/account');
  }

  String _stripHtml(String value) {
    // 中文注释: 搜索摘要展示前统一去标签和压缩空白，避免工具消息把 HTML 噪音直接回灌给模型。
    final withoutTags = value.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _decodeHtml(withoutTags).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _decodeHtml(String value) {
    // 中文注释: 常见 HTML 实体在这里做最小解码，保证标题摘要的可读性，不引入额外解析依赖。
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }
}

class GatewayHttpFetchResult {
  const GatewayHttpFetchResult({
    required this.statusCode,
    required this.contentType,
    required this.body,
    required this.truncated,
  });

  final int statusCode;
  final String contentType;
  final String body;
  final bool truncated;
}
