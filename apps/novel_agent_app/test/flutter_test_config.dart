import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  await testMain();
}
