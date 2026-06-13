import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test('real network binding leaves HttpOverrides disabled', () {
    expect(HttpOverrides.current, isNull);
  });
}
