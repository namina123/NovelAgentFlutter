import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CharacterProfileIdentityService', () {
    test('matches id display name alias and historical name', () {
      final service = CharacterProfileIdentityService();
      const profile = CharacterProfile(
        id: 'char.hero',
        displayName: '林昭',
        aliases: <String>['阿昭'],
        nameHistory: <String>['林小昭'],
      );

      expect(service.matchesReference(profile, 'char.hero'), isTrue);
      expect(service.matchesReference(profile, '林昭'), isTrue);
      expect(service.matchesReference(profile, '阿昭'), isTrue);
      expect(service.matchesReference(profile, '林小昭'), isTrue);
      expect(service.matchesReference(profile, '陌生人'), isFalse);
    });

    test('builds generic entity identity without losing stable id', () {
      final service = CharacterProfileIdentityService();
      const profile = CharacterProfile(
        id: 'char.hero',
        displayName: '林昭',
        summary: '主角',
        aliases: <String>['阿昭'],
      );

      final identity = service.toEntityIdentity(profile);

      expect(identity.id, 'char.hero');
      expect(identity.kind, 'character');
      expect(identity.displayName, '林昭');
      expect(identity.aliases, <String>['阿昭']);
    });
  });
}
