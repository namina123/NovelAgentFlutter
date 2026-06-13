import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test('enabledDefinitions hides short collection from default creation list', () {
    const catalog = ProjectTypeCatalogService();

    final enabledIds = catalog
        .enabledDefinitions()
        .map((item) => item.id)
        .toList(growable: false);

    expect(enabledIds, isNot(contains('short_collection')));
    expect(catalog.definitionOf('short_collection').id, 'short_collection');
  });
}
