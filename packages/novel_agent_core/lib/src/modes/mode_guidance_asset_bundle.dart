import '../assets/character_profile.dart';
import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';
import '../entity/entity_identity.dart';
import '../inspiration/inspiration_premise.dart';

class ModeGuidanceAssetBundle {
  const ModeGuidanceAssetBundle({
    required this.modeId,
    this.premises = const <InspirationPremise>[],
    this.styleProfiles = const <StyleProfile>[],
    this.worldRuleSets = const <WorldRuleSet>[],
    this.characterProfiles = const <CharacterProfile>[],
    this.entityIdentities = const <EntityIdentity>[],
    this.markdownPathsByAssetId = const <String, String>{},
  });

  final String modeId;
  final List<InspirationPremise> premises;
  final List<StyleProfile> styleProfiles;
  final List<WorldRuleSet> worldRuleSets;
  final List<CharacterProfile> characterProfiles;
  final List<EntityIdentity> entityIdentities;
  final Map<String, String> markdownPathsByAssetId;

  String markdownPathFor(String assetId) {
    return markdownPathsByAssetId[assetId] ?? '';
  }
}
