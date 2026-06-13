import 'package:flutter_test/flutter_test.dart';

import 'test_font_loader.dart';

Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await GoldenTestFontLoader.ensureLoaded();
  await testMain();
}
