import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectStyleBindingResolverService', () {
    test(
      'prefers explicit project style bindings before legacy default flag',
      () {
        final resolver = ProjectStyleBindingResolverService();

        final styleIds = resolver.resolveStyleIds(
          <ProjectStyleBinding>[
            const ProjectStyleBinding(
              id: 'writer-main',
              styleId: 'style.writer',
              defaultForProject: true,
              targetAgentIds: <String>['writer'],
              weight: 120,
            ),
          ],
          availableStyles: const <StyleProfile>[
            StyleProfile(
              id: 'style.legacy',
              displayName: '旧默认风格',
              summary: '旧的默认风格。',
              defaultForProject: true,
            ),
            StyleProfile(
              id: 'style.writer',
              displayName: '作者风格',
              summary: '作者专用风格。',
            ),
          ],
          agentId: 'writer',
        );

        expect(styleIds, <String>['style.writer']);
      },
    );

    test(
      'falls back to style asset default when no explicit binding exists',
      () {
        final resolver = ProjectStyleBindingResolverService();

        final styleIds = resolver.resolveStyleIds(
          const <ProjectStyleBinding>[],
          availableStyles: const <StyleProfile>[
            StyleProfile(
              id: 'style.legacy',
              displayName: '旧默认风格',
              summary: '旧的默认风格。',
              defaultForProject: true,
            ),
          ],
        );

        expect(styleIds, <String>['style.legacy']);
      },
    );
  });
}
