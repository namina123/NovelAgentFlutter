import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSubstrateDatabaseOpener', () {
    late Directory tempDirectory;
    late Directory substrateRoot;
    late ReferenceSubstratePathService pathService;
    late ReferenceSubstrateDatabaseOpener opener;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'reference_substrate_database_opener_test_',
      );
      substrateRoot = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}substrate',
      )..createSync(recursive: true);
      pathService = const ReferenceSubstratePathService();
      opener = ReferenceSubstrateDatabaseOpener(pathService: pathService);
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('creates database at shortened evidence path', () {
      final database = opener.open(substrateRoot.path);
      try {
        database.execute('CREATE TABLE sample (value TEXT NOT NULL)');
        database.execute('INSERT INTO sample (value) VALUES (?)', <Object?>[
          'fresh',
        ]);
      } finally {
        database.dispose();
      }

      final databasePath = pathService.databasePath(substrateRoot.path);
      expect(File(databasePath).existsSync(), isTrue);
      expect(
        databasePath.length,
        lessThan(pathService.legacyDatabasePath(substrateRoot.path).length),
      );
    });

    test('reuses legacy database contents after path migration', () {
      final legacyPath = pathService.legacyDatabasePath(substrateRoot.path);
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

      final database = opener.open(substrateRoot.path);
      try {
        final rows = database.select('SELECT value FROM sample');
        expect(rows.single['value'], 'legacy');
      } finally {
        database.dispose();
      }

      expect(
        File(pathService.databasePath(substrateRoot.path)).existsSync(),
        isTrue,
      );
    });
  });
}
