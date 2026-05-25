import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'organization_profile.dart';

class OrganizationProfileNormalizerService {
  const OrganizationProfileNormalizerService();

  OrganizationProfile normalize(JsonMap raw) {
    return OrganizationProfile(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'] ?? raw['name'],
      ).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      aliases: ValueReaders.stringList(raw['aliases']),
      nameHistory: ValueReaders.stringList(
        raw['name_history'] ?? raw['historical_names'],
      ),
      organizationType: ValueReaders.stringValue(
        raw['organization_type'] ?? raw['type'],
      ).trim(),
      memberCharacterIds: ValueReaders.stringList(
        raw['member_character_ids'] ?? raw['members'],
      ),
      sourcePath: ValueReaders.stringValue(raw['source_path']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(OrganizationProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'summary': profile.summary,
      'aliases': ValueReaders.deepCopyList(profile.aliases.cast<Object?>()),
      'name_history': ValueReaders.deepCopyList(
        profile.nameHistory.cast<Object?>(),
      ),
      'organization_type': profile.organizationType,
      'member_character_ids': ValueReaders.deepCopyList(
        profile.memberCharacterIds.cast<Object?>(),
      ),
      'source_path': profile.sourcePath,
      'metadata': ValueReaders.deepCopyMap(profile.metadata),
    };
  }
}
