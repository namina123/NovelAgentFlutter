import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectNarrativeArtifactPathPolicyService', () {
    const service = ProjectNarrativeArtifactPathPolicyService();

    test('distinguishes chapter, sample, and scene narrative paths', () {
      expect(service.isFormalChapterPath('chapters/第01章.md'), isTrue);
      expect(service.isSamplePath('samples/第01章_seed_to_full.md'), isTrue);
      expect(service.isScenePath('scenes/第01章_场景.md'), isTrue);

      expect(
        service.isNarrativeDeliveryPath('chapters/第01章.md'),
        isTrue,
      );
      expect(
        service.isNarrativeDeliveryPath('samples/第01章_seed_to_full.md'),
        isTrue,
      );
      expect(
        service.isNarrativeDeliveryPath('scenes/第01章_场景.md'),
        isFalse,
      );

      expect(
        service.isChapterLikePath('scenes/第01章_场景.md'),
        isTrue,
      );
      expect(
        service.isChapterLikePath(
          'samples/第01章_seed_to_full.md',
          includeSamples: false,
        ),
        isFalse,
      );
    });
  });
}
