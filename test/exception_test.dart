// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

void main() {
  group('RedisException', () {
    test('toString', () {
      const exception = RedisException(null);

      expect(exception.toString(), startsWith('RedisException:'));
    });
  });
}
