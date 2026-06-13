import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceAttachmentDatabaseOpener', () {
    late Directory tempDirectory;
    late Directory projectRoot;
    late ProjectReferenceAttachmentSqlitePathService pathService;
    late ProjectReferenceAttachmentDatabaseOpener opener;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'project_reference_attachment_database_opener_test_',
      );
      projectRoot = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}project_root',
      )..createSync(recursive: true);
      pathService = const ProjectReferenceAttachmentSqlitePathService();
      opener = ProjectReferenceAttachmentDatabaseOpener(
        pathService: pathService,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('creates database at shortened attachment path', () {
      final database = opener.open(projectRoot.path);
      try {
        database.execute('CREATE TABLE sample (value TEXT NOT NULL)');
        database.execute('INSERT INTO sample (value) VALUES (?)', <Object?>[
          'fresh',
        ]);
      } finally {
        database.dispose();
      }

      final databasePath = pathService.databasePath(projectRoot.path);
      expect(File(databasePath).existsSync(), isTrue);
      expect(
        databasePath.length,
        lessThan(pathService.legacyDatabasePath(projectRoot.path).length),
      );
    });

    test('reuses legacy attachment database contents after path migration', () {
      final legacyPath = pathService.legacyDatabasePath(projectRoot.path);
      final legacyFile = File(legacyPath)..parent.createSync(recursive: true);
      final legacyDatabase = sqlite3.open(legacyFile.path);
      try {
        legacyDatabase.execute('CREATE TABLE sample (value TEXT NOT NULL)');
        legacyDatabase.execute(
          'INSERT INTO sample (value) VALUES (?)',
          <Object?>['legacy'],
        );
      } finally {
        legacyDatabase.dispose();
      }

      final database = opener.open(projectRoot.path);
      try {
        final rows = database.select('SELECT value FROM sample');
        expect(rows.single['value'], 'legacy');
      } finally {
        database.dispose();
      }

      expect(
        File(pathService.databasePath(projectRoot.path)).existsSync(),
        isTrue,
      );
    });
  });
}
