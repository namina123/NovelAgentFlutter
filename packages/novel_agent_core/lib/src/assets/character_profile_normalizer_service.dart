import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'character_profile.dart';

class CharacterProfileNormalizerService {
  const CharacterProfileNormalizerService();

  CharacterProfile normalize(JsonMap raw) {
    // 中文注释: 角色卡的稳定身份由 id 承担，display_name 只负责展示与可变人名，避免以后改名时牵动整条引用链。
    return CharacterProfile(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'] ?? raw['name'],
      ).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      aliases: ValueReaders.stringList(raw['aliases']),
      nameHistory: ValueReaders.stringList(
        raw['name_history'] ?? raw['historical_names'],
      ),
      storyRole: ValueReaders.stringValue(
        raw['story_role'] ?? raw['role'],
      ).trim(),
      traits: ValueReaders.stringList(raw['traits']),
      organizationIds: ValueReaders.stringList(
        raw['organization_ids'] ?? raw['organizations'],
      ),
      sourcePath: ValueReaders.stringValue(raw['source_path']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(CharacterProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'summary': profile.summary,
      'aliases': ValueReaders.deepCopyList(profile.aliases.cast<Object?>()),
      'name_history': ValueReaders.deepCopyList(
        profile.nameHistory.cast<Object?>(),
      ),
      'story_role': profile.storyRole,
      'traits': ValueReaders.deepCopyList(profile.traits.cast<Object?>()),
      'organization_ids': ValueReaders.deepCopyList(
        profile.organizationIds.cast<Object?>(),
      ),
      'source_path': profile.sourcePath,
      'metadata': ValueReaders.deepCopyMap(profile.metadata),
    };
  }
}
