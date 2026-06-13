import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolSchemaBuilderService', () {
    test('exposes domain and low-level tools in one schema build call', () {
      final service = ToolSchemaBuilderService();

      final schemas = service.buildOpenAiSchemas(<String>[
        'write_project_file',
        'submit_chapter_delivery',
        'request_profile_clarification',
      ]);

      expect(schemas, hasLength(3));
      final names = schemas
          .map(
            (schema) => ValueReaders.stringValue(
              ValueReaders.mapValue(schema['function'])['name'],
            ),
          )
          .toList(growable: false);
      expect(names, <String>[
        'write_project_file',
        'submit_chapter_delivery',
        'request_profile_clarification',
      ]);

      final chapterSchema = schemas[1];
      final clarificationSchema = schemas[2];
      expect(
        ValueReaders.mapValue(
          ValueReaders.mapValue(chapterSchema['function'])['parameters'],
        ),
        isNotEmpty,
      );
      expect(
        ValueReaders.mapValue(
          ValueReaders.mapValue(clarificationSchema['function'])['parameters'],
        ),
        isNotEmpty,
      );
    });

    test(
      'keeps information tool schemas aligned with narrative domain catalog',
      () {
        final service = ToolSchemaBuilderService();
        final domainCatalog = NarrativeDomainToolCatalog();

        final builtSchemas = service.buildOpenAiSchemas(<String>[
          NarrativeDomainToolNames.requestExternalResearch,
          NarrativeDomainToolNames.proposeDesignElement,
        ]);
        final domainSchemas = domainCatalog.buildOpenAiSchemas(<String>[
          NarrativeDomainToolNames.requestExternalResearch,
          NarrativeDomainToolNames.proposeDesignElement,
        ]);

        expect(builtSchemas, hasLength(2));
        expect(builtSchemas, domainSchemas);
      },
    );

    test('call_sub_agent schema documents empty agent_id fallback routing', () {
      final service = ToolSchemaBuilderService();

      final schema = service.buildOpenAiSchemas(<String>[
        'call_sub_agent',
      ]).single;
      final parameters = ValueReaders.mapValue(
        ValueReaders.mapValue(schema['function'])['parameters'],
      );
      final properties = ValueReaders.mapValue(parameters['properties']);
      final agentIdSchema = ValueReaders.mapValue(properties['agent_id']);

      expect(
        ValueReaders.stringValue(agentIdSchema['description']),
        contains('空字符串'),
      );
      expect(
        ValueReaders.stringValue(agentIdSchema['description']),
        contains('自动兜底选取'),
      );
    });

    test(
      'submit_chapter_delivery schema documents continuity handoff fields',
      () {
        final service = ToolSchemaBuilderService();

        final schema = service.buildOpenAiSchemas(<String>[
          'submit_chapter_delivery',
        ]).single;
        final function = ValueReaders.mapValue(schema['function']);
        final parameters = ValueReaders.mapValue(function['parameters']);
        final properties = ValueReaders.mapValue(parameters['properties']);
        final chapterContentSchema = ValueReaders.mapValue(
          properties['chapter_content'],
        );
        final submissionSchema = ValueReaders.mapValue(
          properties['submission'],
        );

        expect(
          ValueReaders.stringValue(function['description']),
          contains('final_state_summary'),
        );
        expect(
          ValueReaders.stringValue(chapterContentSchema['description']),
          contains('承接上一章已落定状态'),
        );
        expect(
          ValueReaders.stringValue(submissionSchema['description']),
          contains('下一章入口'),
        );
      },
    );
  });
}
