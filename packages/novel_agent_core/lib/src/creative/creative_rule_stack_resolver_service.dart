import '../assets/project_style_binding.dart';
import '../assets/project_style_binding_normalizer_service.dart';
import '../assets/project_style_binding_resolver_service.dart';
import '../assets/style_profile.dart';
import '../assets/style_profile_markdown_parser_service.dart';
import '../assets/style_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../modes/mode_guidance_state.dart';
import 'creative_rule_stack.dart';
import 'expression_constraint_profile.dart';
import 'expression_constraint_profile_normalizer_service.dart';
import 'mode_guidance.dart';
import 'mode_guidance_mapper_service.dart';
import 'mode_guidance_markdown_parser_service.dart';
import 'project_expression_constraint_binding.dart';
import 'project_expression_constraint_binding_normalizer_service.dart';
import 'project_expression_constraint_binding_resolver_service.dart';
import 'project_constitution.dart';
import 'project_constitution_markdown_parser_service.dart';
import 'project_constitution_normalizer_service.dart';

class CreativeRuleStackResolverService {
  CreativeRuleStackResolverService({
    ProjectConstitutionNormalizerService? constitutionNormalizerService,
    ProjectConstitutionMarkdownParserService? constitutionParserService,
    ModeGuidanceMapperService? modeGuidanceMapperService,
    ModeGuidanceMarkdownParserService? modeGuidanceParserService,
    ExpressionConstraintProfileNormalizerService?
    expressionConstraintNormalizerService,
    ProjectExpressionConstraintBindingNormalizerService?
    expressionConstraintBindingNormalizerService,
    ProjectExpressionConstraintBindingResolverService?
    expressionConstraintBindingResolverService,
    StyleProfileNormalizerService? styleNormalizerService,
    StyleProfileMarkdownParserService? styleParserService,
    ProjectStyleBindingNormalizerService? styleBindingNormalizerService,
    ProjectStyleBindingResolverService? styleBindingResolverService,
  }) : _constitutionNormalizerService =
           constitutionNormalizerService ??
           const ProjectConstitutionNormalizerService(),
       _constitutionParserService =
           constitutionParserService ??
           ProjectConstitutionMarkdownParserService(),
       _modeGuidanceMapperService =
           modeGuidanceMapperService ?? ModeGuidanceMapperService(),
       _modeGuidanceParserService =
           modeGuidanceParserService ?? ModeGuidanceMarkdownParserService(),
       _expressionConstraintNormalizerService =
           expressionConstraintNormalizerService ??
           const ExpressionConstraintProfileNormalizerService(),
       _expressionConstraintBindingNormalizerService =
           expressionConstraintBindingNormalizerService ??
           const ProjectExpressionConstraintBindingNormalizerService(),
       _expressionConstraintBindingResolverService =
           expressionConstraintBindingResolverService ??
           const ProjectExpressionConstraintBindingResolverService(),
       _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _styleParserService =
           styleParserService ?? StyleProfileMarkdownParserService(),
       _styleBindingNormalizerService =
           styleBindingNormalizerService ??
           const ProjectStyleBindingNormalizerService(),
       _styleBindingResolverService =
           styleBindingResolverService ??
           const ProjectStyleBindingResolverService();

  final ProjectConstitutionNormalizerService _constitutionNormalizerService;
  final ProjectConstitutionMarkdownParserService _constitutionParserService;
  final ModeGuidanceMapperService _modeGuidanceMapperService;
  final ModeGuidanceMarkdownParserService _modeGuidanceParserService;
  final ExpressionConstraintProfileNormalizerService
  _expressionConstraintNormalizerService;
  final ProjectExpressionConstraintBindingNormalizerService
  _expressionConstraintBindingNormalizerService;
  final ProjectExpressionConstraintBindingResolverService
  _expressionConstraintBindingResolverService;
  final StyleProfileNormalizerService _styleNormalizerService;
  final StyleProfileMarkdownParserService _styleParserService;
  final ProjectStyleBindingNormalizerService _styleBindingNormalizerService;
  final ProjectStyleBindingResolverService _styleBindingResolverService;

  CreativeRuleStack resolve({
    JsonMap rawStack = const <String, Object?>{},
    JsonMap rawConstitution = const <String, Object?>{},
    String projectConstitutionMarkdown = '',
    ModeGuidanceState? modeGuidanceState,
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    List<Object?> projectExpressionConstraintBindings = const <Object?>[],
    List<Object?> styleProfiles = const <Object?>[],
    List<Object?> projectStyleBindings = const <Object?>[],
    List<Object?> memorySections = const <Object?>[],
    JsonMap projectFileContents = const <String, Object?>{},
    String agentId = '',
    String modeId = '',
    String stageId = '',
  }) {
    // 中文注释: 创作约束栈统一负责把宪法、模式引导和风格绑定解析成同一份共享合同，避免提示层各自拼接。
    if (rawStack.isNotEmpty) {
      return CreativeRuleStack.fromJson(rawStack);
    }
    final constitution = _resolveConstitution(
      rawConstitution: rawConstitution,
      explicitMarkdown: projectConstitutionMarkdown,
      projectFileContents: projectFileContents,
    );
    final modeGuidance = _resolveModeGuidance(
      modeGuidanceState: modeGuidanceState,
      projectFileContents: projectFileContents,
    );
    final allExpressionConstraints = _resolveExpressionConstraintProfiles(
      expressionConstraintProfiles,
    );
    final expressionConstraintBindings = projectExpressionConstraintBindings
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .map(_expressionConstraintBindingNormalizerService.normalize)
        .toList(growable: false);
    final effectiveExpressionConstraints =
        _resolveEffectiveExpressionConstraints(
          allExpressionConstraints,
          bindings: expressionConstraintBindings,
          agentId: agentId,
          modeId: modeId,
          stageId: stageId,
        );
    final allStyles = _resolveStyles(
      styleProfiles: styleProfiles,
      projectFileContents: projectFileContents,
    );
    final bindings = projectStyleBindings
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .map(_styleBindingNormalizerService.normalize)
        .toList(growable: false);
    final effectiveStyles = _resolveEffectiveStyles(
      allStyles,
      bindings: bindings,
      agentId: agentId,
      modeId: modeId,
      stageId: stageId,
    );
    return CreativeRuleStack(
      constitution: constitution,
      modeGuidance: modeGuidance,
      expressionConstraints: effectiveExpressionConstraints,
      expressionConstraintBindings: expressionConstraintBindings,
      styles: effectiveStyles,
      styleBindings: bindings,
      consumedMemorySectionIds: _consumedMemorySectionIds(
        memorySections,
        hasConstitution: constitution != null && !constitution.isEmpty,
        hasModeGuidance: modeGuidance != null && !modeGuidance.isEmpty,
        hasExpressionConstraints: effectiveExpressionConstraints.isNotEmpty,
        hasStyles: effectiveStyles.isNotEmpty,
      ),
      sourcePaths: _sourcePaths(
        constitution: constitution,
        modeGuidance: modeGuidance,
        expressionConstraints: effectiveExpressionConstraints,
        styles: effectiveStyles,
      ),
    );
  }

  ProjectConstitution? _resolveConstitution({
    required JsonMap rawConstitution,
    required String explicitMarkdown,
    required JsonMap projectFileContents,
  }) {
    if (rawConstitution.isNotEmpty) {
      final normalized = _constitutionNormalizerService.normalize(
        rawConstitution,
      );
      return normalized.isEmpty ? null : normalized;
    }
    final markdown = explicitMarkdown.trim().isNotEmpty
        ? explicitMarkdown.trim()
        : _constitutionMarkdownFromFiles(projectFileContents);
    if (markdown.isEmpty) {
      return null;
    }
    final relativePath = _constitutionPathFromFiles(projectFileContents);
    final parsed = _constitutionParserService.parseDocument(
      markdown,
      relativePath: relativePath,
    );
    final normalized = _constitutionNormalizerService.normalize(parsed);
    return normalized.isEmpty ? null : normalized;
  }

  ModeGuidance? _resolveModeGuidance({
    required ModeGuidanceState? modeGuidanceState,
    required JsonMap projectFileContents,
  }) {
    if (modeGuidanceState != null) {
      return _modeGuidanceMapperService.fromState(
        modeGuidanceState,
        sourcePath: 'tracking/modes/${modeGuidanceState.modeId}/guidance.md',
      );
    }
    for (final entry in projectFileContents.entries) {
      final path = entry.key.replaceAll('\\', '/').trim();
      final match = RegExp(
        r'^tracking/modes/([^/]+)/guidance\.md$',
      ).firstMatch(path);
      if (match == null) {
        continue;
      }
      final content = ValueReaders.stringValue(entry.value).trim();
      if (content.isEmpty) {
        continue;
      }
      final parsed = _modeGuidanceParserService.parseDocument(
        content,
        modeId: match.group(1)!.trim(),
        relativePath: path,
      );
      return ModeGuidance(
        modeId: ValueReaders.stringValue(parsed['mode_id']),
        title: ValueReaders.stringValue(parsed['title']),
        summary: ValueReaders.stringValue(parsed['summary']),
        currentStageTitle: ValueReaders.stringValue(
          parsed['current_stage_title'],
        ),
        confirmedFacts: ValueReaders.stringList(parsed['confirmed_facts']),
        boundaries: ValueReaders.stringList(parsed['boundaries']),
        sourcePath: ValueReaders.stringValue(parsed['source_path']),
        metadata: ValueReaders.deepCopyMap(
          ValueReaders.mapValue(parsed['metadata']),
        ),
      );
    }
    return null;
  }

  List<ExpressionConstraintProfile> _resolveExpressionConstraintProfiles(
    List<Object?> expressionConstraintProfiles,
  ) {
    final result = <ExpressionConstraintProfile>[];
    for (final rawProfile in expressionConstraintProfiles.map(
      ValueReaders.mapValue,
    )) {
      if (rawProfile.isEmpty) {
        continue;
      }
      final normalized = _expressionConstraintNormalizerService.normalize(
        rawProfile,
      );
      if (normalized.id.trim().isEmpty) {
        continue;
      }
      result.add(normalized);
    }
    result.sort((left, right) => left.displayName.compareTo(right.displayName));
    return result;
  }

  List<StyleProfile> _resolveStyles({
    required List<Object?> styleProfiles,
    required JsonMap projectFileContents,
  }) {
    final result = <StyleProfile>[];
    for (final rawStyle in styleProfiles.map(ValueReaders.mapValue)) {
      if (rawStyle.isEmpty) {
        continue;
      }
      final normalized = _styleNormalizerService.normalize(rawStyle);
      if (normalized.id.trim().isEmpty) {
        continue;
      }
      result.add(normalized);
    }
    if (result.isNotEmpty) {
      return result;
    }
    for (final entry in projectFileContents.entries) {
      final path = entry.key.replaceAll('\\', '/').trim();
      if (!_isStylePath(path)) {
        continue;
      }
      final content = ValueReaders.stringValue(entry.value).trim();
      if (content.isEmpty) {
        continue;
      }
      final parsed = _styleParserService.parseDocument(
        content,
        fallbackId: _fallbackIdFromPath(path),
        relativePath: path,
      );
      final normalized = _styleNormalizerService.normalize(parsed);
      if (normalized.id.trim().isEmpty) {
        continue;
      }
      if (result.every((style) => style.id != normalized.id)) {
        result.add(normalized);
      }
    }
    result.sort((left, right) {
      if (left.defaultForProject != right.defaultForProject) {
        return left.defaultForProject ? -1 : 1;
      }
      return left.displayName.compareTo(right.displayName);
    });
    return result;
  }

  List<ExpressionConstraintProfile> _resolveEffectiveExpressionConstraints(
    List<ExpressionConstraintProfile> availableProfiles, {
    required List<ProjectExpressionConstraintBinding> bindings,
    required String agentId,
    required String modeId,
    required String stageId,
  }) {
    if (availableProfiles.isEmpty) {
      return const <ExpressionConstraintProfile>[];
    }
    final resolvedIds = _expressionConstraintBindingResolverService
        .resolveProfileIds(
          bindings,
          availableProfiles: availableProfiles,
          agentId: agentId,
          modeId: modeId,
          stageId: stageId,
        );
    final selected = <ExpressionConstraintProfile>[];
    for (final id in resolvedIds) {
      for (final profile in availableProfiles) {
        if (profile.id == id) {
          selected.add(profile);
          break;
        }
      }
    }
    return selected;
  }

  List<StyleProfile> _resolveEffectiveStyles(
    List<StyleProfile> availableStyles, {
    required List<ProjectStyleBinding> bindings,
    required String agentId,
    required String modeId,
    required String stageId,
  }) {
    if (availableStyles.isEmpty) {
      return const <StyleProfile>[];
    }
    final resolvedIds = _styleBindingResolverService.resolveStyleIds(
      bindings,
      availableStyles: availableStyles,
      agentId: agentId,
      modeId: modeId,
      stageId: stageId,
    );
    final selected = <StyleProfile>[];
    if (resolvedIds.isNotEmpty) {
      for (final id in resolvedIds) {
        for (final style in availableStyles) {
          if (style.id == id) {
            selected.add(style);
            break;
          }
        }
      }
      return selected;
    }
    if (availableStyles.length == 1) {
      return <StyleProfile>[availableStyles.first];
    }
    return availableStyles
        .where((style) => style.defaultForProject)
        .toList(growable: false);
  }

  List<String> _consumedMemorySectionIds(
    List<Object?> memorySections, {
    required bool hasConstitution,
    required bool hasModeGuidance,
    required bool hasExpressionConstraints,
    required bool hasStyles,
  }) {
    final result = <String>[];
    for (final rawSection in memorySections) {
      final section = ValueReaders.mapValue(rawSection);
      final id = ValueReaders.stringValue(section['id']).trim();
      final layer = ValueReaders.stringValue(section['creative_layer']).trim();
      if (id.isEmpty || layer.isEmpty) {
        continue;
      }
      final shouldConsume =
          (layer == 'constitution' && hasConstitution) ||
          (layer == 'mode_guidance' && hasModeGuidance) ||
          (layer == 'expression_constraint' && hasExpressionConstraints) ||
          (layer == 'style' && hasStyles);
      if (!shouldConsume) {
        continue;
      }
      if (!result.contains(id)) {
        result.add(id);
      }
    }
    return result;
  }

  List<String> _sourcePaths({
    required ProjectConstitution? constitution,
    required ModeGuidance? modeGuidance,
    required List<ExpressionConstraintProfile> expressionConstraints,
    required List<StyleProfile> styles,
  }) {
    final result = <String>[];
    void addPath(String path) {
      final clean = path.trim();
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }

    if (constitution != null) {
      addPath(constitution.sourcePath);
    }
    if (modeGuidance != null) {
      addPath(modeGuidance.sourcePath);
    }
    for (final profile in expressionConstraints) {
      addPath(ValueReaders.stringValue(profile.metadata['source_path']));
    }
    for (final style in styles) {
      addPath(style.sourcePath);
    }
    return result;
  }

  String _constitutionMarkdownFromFiles(JsonMap projectFileContents) {
    final path = _constitutionPathFromFiles(projectFileContents);
    if (path.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(projectFileContents[path]).trim();
  }

  String _constitutionPathFromFiles(JsonMap projectFileContents) {
    const candidates = <String>[
      'specs/project_spec.md',
      'specs/constitution.md',
      'premise/project_constitution.md',
      'premise/constitution.md',
    ];
    for (final candidate in candidates) {
      if (ValueReaders.stringValue(
        projectFileContents[candidate],
      ).trim().isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }

  bool _isStylePath(String path) {
    final lower = path.toLowerCase();
    if (!(lower.startsWith('styles/') || lower.startsWith('assets/styles/'))) {
      return false;
    }
    return lower.endsWith('.style.md') || lower.endsWith('.md');
  }

  String _fallbackIdFromPath(String path) {
    var name = path.split('/').last;
    if (name.toLowerCase().endsWith('.style.md')) {
      name = name.substring(0, name.length - '.style.md'.length);
    } else if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }
}
