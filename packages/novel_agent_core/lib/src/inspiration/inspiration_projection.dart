import '../assets/character_profile.dart';
import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';
import 'inspiration_premise.dart';

class InspirationProjection {
  const InspirationProjection({
    required this.inspirationId,
    this.premises = const <InspirationPremise>[],
    this.styleProfiles = const <StyleProfile>[],
    this.worldRuleSets = const <WorldRuleSet>[],
    this.characterProfiles = const <CharacterProfile>[],
  });

  final String inspirationId;
  final List<InspirationPremise> premises;
  final List<StyleProfile> styleProfiles;
  final List<WorldRuleSet> worldRuleSets;
  final List<CharacterProfile> characterProfiles;
}
