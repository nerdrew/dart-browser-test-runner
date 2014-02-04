library foo_test;

import 'package:unittest/unittest.dart';
import 'dart:math';

main() {
  test('alway pass', () {
    expect(true, isTrue);
  });

  test('random fail', () {
    expect(new Random().nextBool(), isTrue);
  });
}

