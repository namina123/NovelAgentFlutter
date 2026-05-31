import 'character_profile.dart';
import 'character_stage_state_record.dart';

class CharacterStateUpdatePlan {
  const CharacterStateUpdatePlan({
    required this.profile,
    required this.latestState,
  });

  final CharacterProfile profile;
  final CharacterStageStateRecord latestState;
}
