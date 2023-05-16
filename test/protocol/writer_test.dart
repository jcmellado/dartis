// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

void main() {
  final codec = RedisCodec();
  final writer = Writer();

  group('Writer', () {
    group('write', () {
      test('empty command line', () {
        final line = <Object>[];
        final bytes = writer.write(line, codec);
        expect(bytes, equals([RespToken.array, 48, 13, 10])); // *0
      });

      test('command', () {
        final line = <Object>['GET', 'key'];
        final bytes = writer.write(line, codec);
        expect(
            bytes,
            equals([
              RespToken.array, 50, 13, 10, // *2
              RespToken.bulk, 51, 13, 10, 71, 69, 84, 13, 10, // $3 GET
              RespToken.bulk, 51, 13, 10, 107, 101, 121, 13, 10 // $3 key
            ]));
      });
    });

    group('writeAll', () {
      test('empty list of commands', () {
        final lines = <List<Object>>[];
        final bytes = writer.writeAll(lines, codec);
        expect(bytes, equals(<int>[]));
      });

      test('list of commands', () {
        final one = <Object>['GET', 'key'];
        final two = <Object>['HSET', 'key', 'field', 123];
        final bytes = writer.writeAll(<List<Object>>[one, two], codec);
        expect(
            bytes,
            equals([
              RespToken.array, 50, 13, 10, // *2
              RespToken.bulk, 51, 13, 10, 71, 69, 84, 13, 10, // $3 GET
              RespToken.bulk, 51, 13, 10, 107, 101, 121, 13, 10, // $3 key
              RespToken.array, 52, 13, 10, // *4
              RespToken.bulk, 52, 13, 10, 72, 83, 69, 84, 13, 10, // $4 HSET
              RespToken.bulk, 51, 13, 10, 107, 101, 121, 13, 10, // $3 key
              RespToken.bulk, 53, 13, 10, 102, 105, 101, 108, 100, 13,
              10, // $5 field
              RespToken.bulk, 51, 13, 10, 49, 50, 51, 13, 10 // $3 123
            ]));
      });
    });
  });
}
