import '../assets/character_profile_identity_service.dart';
import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';
import '../entity/entity_identity.dart';
import '../inspiration/inspiration_premise.dart';
import '../inspiration/inspiration_projection.dart';
import '../inspiration/inspiration_projection_service.dart';
import 'mode_guidance_asset_bundle.dart';
import 'mode_guidance_inspiration_record_mapper_service.dart';
import 'mode_guidance_state.dart';

class ModeGuidanceAssetBundleBuilderService {
  const ModeGuidanceAssetBundleBuilderService({
    ModeGuidanceInspirationRecordMapperService? inspirationRecordMapperService,
    InspirationProjectionService? inspirationProjectionService,
    CharacterProfileIdentityService? characterProfileIdentityService,
  }) : _inspirationRecordMapperService =
           inspirationRecordMapperService ??
           const ModeGuidanceInspirationRecordMapperService(),
       _inspirationProjectionService =
           inspirationProjectionService ?? const InspirationProjectionService(),
       _characterProfileIdentityService =
           characterProfileIdentityService ??
           const CharacterProfileIdentityService();

  final ModeGuidanceInspirationRecordMapperService
  _inspirationRecordMapperService;
  final InspirationProjectionService _inspirationProjectionService;
  final CharacterProfileIdentityService _characterProfileIdentityService;

  ModeGuidanceAssetBundle build(ModeGuidanceState state) {
    // 中文注释: 这里先把 mode guidance 状态转成共享灵感记录，再投影为 premise/style/world/characters，
    // 这样后续一般小说、长任务或拆书后的二次创作都能复用同一条收束链。
    final record = _inspirationRecordMapperService.map(state);
    final projection = _inspirationProjectionService.build(record);
    final entities = projection.characterProfiles
        .map(_characterProfileIdentityService.toEntityIdentity)
        .toList(growable: false);
    final markdownPaths = _markdownPathsFor(state.modeId, projection, entities);
    return ModeGuidanceAssetBundle(
      modeId: state.modeId,
      premises: projection.premises,
      styleProfiles: projection.styleProfiles,
      worldRuleSets: projection.worldRuleSets,
      characterProfiles: projection.characterProfiles,
      entityIdentities: entities,
      markdownPathsByAssetId: markdownPaths,
    );
  }

  Map<String, String> _markdownPathsFor(
    String modeId,
    InspirationProjection projection,
    List<EntityIdentity> entities,
  ) {
    final markdownPaths = <String, String>{};
    _assignPremisePaths(modeId, projection.premises, markdownPaths);
    _assignStylePaths(modeId, projection.styleProfiles, markdownPaths);
    _assignWorldPaths(modeId, projection.worldRuleSets, markdownPaths);
    _assignEntityPaths(modeId, entities, markdownPaths);
    return markdownPaths;
  }

  void _assignPremisePaths(
    String modeId,
    List<InspirationPremise> premises,
    Map<String, String> markdownPaths,
  ) {
    for (var index = 0; index < premises.length; index++) {
      markdownPaths[premises[index].id] = switch (modeId) {
        'seed_autopilot_novel' => 'premise/seed_autopilot_premise.md',
        'full_outline_consensus' => 'premise/full_outline_consensus_premise.md',
        _ => 'premise/${_safeModeId(modeId)}_premise_${index + 1}.md',
      };
    }
  }

  void _assignStylePaths(
    String modeId,
    List<StyleProfile> styles,
    Map<String, String> markdownPaths,
  ) {
    for (var index = 0; index < styles.length; index++) {
      markdownPaths[styles[index].id] = switch (modeId) {
        'seed_autopilot_novel' => 'styles/seed_autopilot_style.md',
        'full_outline_consensus' => 'styles/full_outline_consensus_style.md',
        _ => 'styles/${_safeModeId(modeId)}_style_${index + 1}.md',
      };
    }
  }

  void _assignWorldPaths(
    String modeId,
    List<WorldRuleSet> worlds,
    Map<String, String> markdownPaths,
  ) {
    for (var index = 0; index < worlds.length; index++) {
      markdownPaths[worlds[index].id] = switch (modeId) {
        'seed_autopilot_novel' => 'world/seed_autopilot_world_anchor.md',
        'full_outline_consensus' =>
          'world/full_outline_consensus_world_anchor.md',
        _ => 'world/${_safeModeId(modeId)}_world_${index + 1}.md',
      };
    }
  }

  void _assignEntityPaths(
    String modeId,
    List<EntityIdentity> entities,
    Map<String, String> markdownPaths,
  ) {
    for (var index = 0; index < entities.length; index++) {
      markdownPaths[entities[index].id] = switch (modeId) {
        'seed_autopilot_novel' =>
          'assets/characters/seed_autopilot_protagonist.md',
        'full_outline_consensus' =>
          'assets/characters/full_outline_consensus_core_roles.md',
        _ =>
          'assets/characters/${_safeModeId(modeId)}_character_${index + 1}.md',
      };
    }
  }

  String _safeModeId(String modeId) {
    return modeId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
  }
}
