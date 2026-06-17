import 'dart:convert';

import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_interface_template_seed.dart';

class ProviderInterfaceTemplateService {
  ProviderInterfaceTemplateService.fromJsonString(String source)
    : _catalog = ValueReaders.mapValue(jsonDecode(source));

  ProviderInterfaceTemplateService.fromDocument(JsonMap document)
    : _catalog = ValueReaders.deepCopyMap(document);

  factory ProviderInterfaceTemplateService.seeded() {
    // 中文注释: 接口模板目录只负责“接口入口模板”事实，不再混入模型 offering 与运行默认值。
    return ProviderInterfaceTemplateService.fromJsonString(
      providerInterfaceTemplateSeed,
    );
  }

  final JsonMap _catalog;

  List<JsonMap> templates({String query = '', String baseUrl = ''}) {
    final scored = <JsonMap>[];
    for (final raw in ValueReaders.mapList(_catalog['templates'])) {
      final score = _templateScore(raw, query, baseUrl);
      if (query.trim().isEmpty && baseUrl.trim().isEmpty) {
        final item = ValueReaders.deepCopyMap(raw);
        item['score'] = 1;
        scored.add(item);
        continue;
      }
      if (score <= 0) {
        continue;
      }
      final item = ValueReaders.deepCopyMap(raw);
      item['score'] = score;
      scored.add(item);
    }
    scored.sort((a, b) {
      return ValueReaders.intValue(
        b['score'],
      ).compareTo(ValueReaders.intValue(a['score']));
    });
    return scored.map(ValueReaders.deepCopyMap).toList(growable: false);
  }

  JsonMap templateById(String templateId) {
    final clean = templateId.trim();
    if (clean.isEmpty) {
      return <String, Object?>{};
    }
    for (final template in ValueReaders.mapList(_catalog['templates'])) {
      if (ValueReaders.stringValue(template['id']) == clean) {
        return ValueReaders.deepCopyMap(template);
      }
    }
    return <String, Object?>{};
  }

  JsonMap bestTemplateMatch({String query = '', String baseUrl = ''}) {
    var best = <String, Object?>{};
    var bestScore = 0;
    for (final template in ValueReaders.mapList(_catalog['templates'])) {
      final score = _templateScore(template, query, baseUrl);
      if (score > bestScore) {
        best = ValueReaders.deepCopyMap(template);
        bestScore = score;
      }
    }
    return best;
  }

  int _templateScore(JsonMap template, String query, String baseUrl) {
    var score = 0;
    final queryText = query.trim().toLowerCase();
    final urlText = baseUrl.trim().toLowerCase();
    if (queryText.isNotEmpty) {
      score = _max(
        score,
        _textScore(ValueReaders.stringValue(template['label']), queryText),
      );
      score = _max(
        score,
        _textScore(ValueReaders.stringValue(template['provider_id']), queryText),
      );
      score = _max(
        score,
        _textScore(ValueReaders.stringValue(template['id']), queryText),
      );
      score = _max(
        score,
        _textScore(ValueReaders.stringValue(template['protocol']), queryText),
      );
      for (final alias in ValueReaders.objectList(template['aliases'])) {
        score = _max(
          score,
          _textScore(ValueReaders.stringValue(alias), queryText),
        );
      }
      final protocol = ValueReaders.stringValue(template['protocol']).trim().toLowerCase();
      final asksForNative = queryText.contains('native');
      final asksForCompatible = queryText.contains('compatible') ||
          queryText.contains('openai') ||
          queryText.contains('chat');
      if (asksForNative && protocol == 'gemini_native') {
        score = _max(score, 160);
      }
      if (asksForCompatible && protocol == 'openai_compatible') {
        score = _max(score, 150);
      }
      if (queryText.contains('anthropic') && protocol == 'anthropic_compatible') {
        score = _max(score, 150);
      }
    }
    if (urlText.isNotEmpty) {
      for (final hint in ValueReaders.objectList(template['base_url_hints'])) {
        final cleanHint = ValueReaders.stringValue(hint).trim().toLowerCase();
        if (cleanHint.isNotEmpty && urlText.contains(cleanHint)) {
          // 中文注释: URL 命中时更具体的路径 hint 应优先于宽泛根域名，避免 /anthropic 被 api 根地址模板抢走。
          score = _max(score, 120 + cleanHint.length);
        }
      }
    }
    if (queryText.isEmpty && urlText.isEmpty) {
      return 1;
    }
    return score;
  }

  int _textScore(String value, String query) {
    final haystack = value.trim().toLowerCase();
    if (haystack.isEmpty || query.isEmpty) {
      return 0;
    }
    if (haystack == query) {
      return 140;
    }
    if (haystack.startsWith(query)) {
      return 110;
    }
    if (haystack.contains(query)) {
      return 80;
    }
    final compactHaystack = haystack.replaceAll(RegExp(r'[-_/ .]'), '');
    final compactQuery = query.replaceAll(RegExp(r'[-_/ .]'), '');
    if (compactQuery.isNotEmpty && compactHaystack.contains(compactQuery)) {
      return 70;
    }
    return 0;
  }

  int _max(int left, int right) {
    return left > right ? left : right;
  }
}
