import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../modes/mode_guidance_asset_bundle.dart';
import '../modes/mode_guidance_asset_bundle_builder_service.dart';
import '../modes/mode_guidance_state.dart';
import '../modes/mode_guidance_workspace_path_service.dart';

class LongTaskCheckpointGuidanceRevisitService {
  LongTaskCheckpointGuidanceRevisitService({
    ModeGuidanceAssetBundleBuilderService? assetBundleBuilderService,
    ModeGuidanceWorkspacePathService? workspacePathService,
  }) : _assetBundleBuilderService =
           assetBundleBuilderService ??
           const ModeGuidanceAssetBundleBuilderService(),
       _workspacePathService =
           workspacePathService ?? const ModeGuidanceWorkspacePathService();

  final ModeGuidanceAssetBundleBuilderService _assetBundleBuilderService;
  final ModeGuidanceWorkspacePathService _workspacePathService;

  JsonMap buildPackage({
    required JsonMap checkpointReview,
    required ModeGuidanceState state,
  }) {
    // 中文注释: 该服务只负责把高风险检查点转成“该回看哪些长期约束”的共享包，不读取文件。
    final bundle = _assetBundleBuilderService.build(state);
    final focusDomains = _focusDomains(checkpointReview);
    final items = <JsonMap>[
      _summaryItem(state),
      ..._domainItems(bundle, focusDomains),
    ];
    return <String, Object?>{
      'ok': true,
      'mode_id': state.modeId,
      'summary_path': _workspacePathService.summaryMarkdownPath(state.modeId),
      'summary': _summaryText(state, focusDomains),
      'focus_domains': focusDomains,
      'items': items,
      'recommended_paths': items
          .map((item) => ValueReaders.stringValue(item['path']).trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
    };
  }

  List<String> _focusDomains(JsonMap checkpointReview) {
    final result = <String>[];
    final severities = <String, int>{};
    for (final signal in ValueReaders.mapList(
      checkpointReview['drift_signals'],
    )) {
      final domain = ValueReaders.stringValue(signal['domain']).trim();
      final severity = _severityScore(
        ValueReaders.stringValue(signal['severity']),
      );
      if (domain.isEmpty || severity <= 0) {
        continue;
      }
      final current = severities[domain] ?? 0;
      if (severity > current) {
        severities[domain] = severity;
      }
    }
    final watchText = ValueReaders.stringList(
      checkpointReview['drift_watch_items'],
    ).join(' ');
    if ((severities['style'] ?? 0) > 0 ||
        _mentionsAny(watchText, const <String>['文风', '风格', '语言'])) {
      result.add('style');
    }
    if ((severities['world'] ?? 0) > 0 ||
        _mentionsAny(watchText, const <String>['世界', '规则', '设定'])) {
      result.add('world');
    }
    if ((severities['entity'] ?? 0) > 0 ||
        _mentionsAny(watchText, const <String>['角色', '动机', '身份'])) {
      result.add('entity');
    }
    if (result.isEmpty) {
      return const <String>['style', 'world', 'entity'];
    }
    return result;
  }

  bool _mentionsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  int _severityScore(String severity) {
    switch (severity.trim()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  JsonMap _summaryItem(ModeGuidanceState state) {
    return <String, Object?>{
      'domain': 'summary',
      'title': '长期约束摘要',
      'path': _workspacePathService.summaryMarkdownPath(state.modeId),
      'summary': '先重新确认当前模式已经收束的创作承诺、托管边界与阶段结论。',
      'highlights': _summaryHighlights(state),
    };
  }

  List<String> _summaryHighlights(ModeGuidanceState state) {
    final values = <String>[];
    for (final answer in state.answers) {
      final clean = answer.value.trim();
      if (clean.isNotEmpty) {
        values.add(clean);
      }
      if (values.length >= 3) {
        break;
      }
    }
    return values;
  }

  List<JsonMap> _domainItems(
    ModeGuidanceAssetBundle bundle,
    List<String> focusDomains,
  ) {
    final result = <JsonMap>[];
    if (focusDomains.contains('style')) {
      for (final style in bundle.styleProfiles) {
        result.add(<String, Object?>{
          'domain': 'style',
          'title': style.displayName,
          'path': bundle.markdownPathFor(style.id),
          'summary': style.summary,
          'highlights': style.guardrails,
        });
      }
    }
    if (focusDomains.contains('world')) {
      for (final world in bundle.worldRuleSets) {
        result.add(<String, Object?>{
          'domain': 'world',
          'title': world.displayName,
          'path': bundle.markdownPathFor(world.id),
          'summary': world.summary,
          'highlights': <String>[
            ...world.rules.take(3),
            ...world.forbiddenAssumptions.take(2),
          ],
        });
      }
    }
    if (focusDomains.contains('entity')) {
      for (final entity in bundle.entityIdentities) {
        result.add(<String, Object?>{
          'domain': 'entity',
          'title': entity.displayName,
          'path': bundle.markdownPathFor(entity.id),
          'summary': entity.summary,
          'highlights': <String>[
            ...entity.aliases.take(3),
            ...entity.nameHistory.take(2),
          ],
        });
      }
    }
    return result;
  }

  String _summaryText(ModeGuidanceState state, List<String> focusDomains) {
    final labels = <String>[];
    for (final domain in focusDomains) {
      switch (domain) {
        case 'style':
          labels.add('风格锚点');
          break;
        case 'world':
          labels.add('世界规则');
          break;
        case 'entity':
          labels.add('角色身份');
          break;
      }
    }
    final labelText = labels.isEmpty ? '长期约束' : labels.join('、');
    return '当前检查点建议优先回看 $labelText，并以 ${state.modeId} 的长期摘要为准。';
  }
}
