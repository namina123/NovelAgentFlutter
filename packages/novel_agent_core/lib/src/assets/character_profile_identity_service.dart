import '../entity/entity_identity.dart';
import 'character_profile.dart';

class CharacterProfileIdentityService {
  const CharacterProfileIdentityService();

  EntityIdentity toEntityIdentity(CharacterProfile profile) {
    return EntityIdentity(
      id: profile.id,
      kind: 'character',
      displayName: profile.displayName,
      summary: profile.summary,
      aliases: profile.aliases,
      nameHistory: profile.nameHistory,
    );
  }

  bool matchesReference(CharacterProfile profile, String candidate) {
    // 中文注释: 角色引用匹配统一覆盖 id、显示名、别名和历史名，后续改名时上下文与任务引用都还能稳定回收。
    final cleanCandidate = candidate.trim().toLowerCase();
    if (cleanCandidate.isEmpty) {
      return false;
    }
    if (profile.id.trim().toLowerCase() == cleanCandidate) {
      return true;
    }
    if (profile.displayName.trim().toLowerCase() == cleanCandidate) {
      return true;
    }
    for (final alias in profile.aliases) {
      if (alias.trim().toLowerCase() == cleanCandidate) {
        return true;
      }
    }
    for (final historyName in profile.nameHistory) {
      if (historyName.trim().toLowerCase() == cleanCandidate) {
        return true;
      }
    }
    return false;
  }
}
