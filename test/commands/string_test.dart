// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late Commands<String, String> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('StringCommands', () {
    test('append', () async {
      final key = uuid();
      expect(await commands.append(key, 'a'), equals(1));
      expect(await commands.append(key, 'bc'), equals(3));
    });

    test('bitcount', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Count.
      expect(await commands.bitcount(key1), equals(10));
      expect(await commands.bitcount(key1, 0, 0), equals(3));
      expect(await commands.bitcount(key1, 1, 2), equals(7));
      expect(await commands.bitcount(key1, -1, 2), equals(4));

      // Count in an empty or non existing string.
      final key2 = uuid();
      expect(await commands.bitcount(key2), isZero);
    });

    test('bitfield', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Operate.
      final operations = <BitfieldOperation>[
        const BitfieldOperation(BitfieldCommand.get, 'u8', '0'),
        const BitfieldOperation(BitfieldCommand.set, 'u8', '#1', value: 100),
        const BitfieldOperation(BitfieldCommand.incrby, 'u8', '#1', value: 2),
        const BitfieldOperation(BitfieldCommand.incrby, 'u8', '#2',
            value: 1000, overflow: BitfieldOverflow.wrap),
        const BitfieldOperation(BitfieldCommand.incrby, 'u8', '#2',
            value: 1000, overflow: BitfieldOverflow.sat),
        const BitfieldOperation(BitfieldCommand.incrby, 'u8', '#2',
            value: 1000, overflow: BitfieldOverflow.fail)
      ];

      expect(await commands.bitfield(key1, operations),
          equals([97, 98, 102, 75, 255, null]));

      // Operate on empty or non existing string.
      final key2 = uuid();
      const operation = BitfieldOperation(BitfieldCommand.get, 'u8', '0');
      expect(await commands.bitfield(key2, [operation]), [0]);
    });

    test('bitop', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      await commands.set(key1, 'a');
      await commands.set(key2, 'b');
      await commands.set(key3, 'cd');

      // Operate with one string.
      expect(
          await commands.bitop(BitopOperation.and, key1, key: key2), equals(1));
      expect(
          await commands.bitop(BitopOperation.or, key1, key: key2), equals(1));
      expect(
          await commands.bitop(BitopOperation.xor, key1, key: key2), equals(1));
      expect(
          await commands.bitop(BitopOperation.not, key1, key: key2), equals(1));

      // Operate with some strings.
      expect(await commands.bitop(BitopOperation.and, key1, keys: [key2, key3]),
          equals(2));
      expect(await commands.bitop(BitopOperation.or, key1, keys: [key2, key3]),
          equals(2));
      expect(await commands.bitop(BitopOperation.xor, key1, keys: [key2, key3]),
          equals(2));

      // Operate on an empty or non existing string.
      final key4 = uuid();
      expect(await commands.bitop(BitopOperation.not, key4, key: key4), isZero);
    });

    test('bitpos', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Search.
      expect(await commands.bitpos(key1, 1), equals(1));
      expect(await commands.bitpos(key1, 0, 9), equals(-1));
      expect(await commands.bitpos(key1, 0, 1, 1), equals(8));
      expect(await commands.bitpos(key1, 1, -1, 2), equals(17));

      // Search in an empty or non existing string.
      final key2 = uuid();
      expect(await commands.bitpos(key2, 1), equals(-1));
    });

    test('decr', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, '12');

      // Decrement.
      expect(await commands.decr(key1), equals(11));

      // Decrement an empty or non existing string.
      final key2 = uuid();
      expect(await commands.decr(key2), equals(-1));
    });

    test('decrby', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, '12');

      // Decrement.
      expect(await commands.decrby(key1, 3), equals(9));

      // Decrement an empty or non existing string.
      final key2 = uuid();
      expect(await commands.decrby(key2, 5), equals(-5));
    });

    test('get', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Get.
      expect(await commands.get(key1), equals('abc'));

      // Get an empty or non existing string.
      final key2 = uuid();
      expect(await commands.get(key2), isNull);
    });

    test('getbit', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Get.
      expect(await commands.getbit(key1, 0), equals(0));
      expect(await commands.getbit(key1, 1), equals(1));
      expect(await commands.getbit(key1, 99), equals(0));

      // Get from an empty or non existing string.
      final key2 = uuid();
      expect(await commands.getbit(key2, 0), equals(0));
    });

    test('getrange', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Get.
      expect(await commands.getrange(key1, 0, 1), equals('ab'));
      expect(await commands.getrange(key1, 1, 99), equals('bc'));
      expect(await commands.getrange(key1, -2, -1), equals('bc'));

      // Get from an empty or non existing string.
      final key2 = uuid();
      expect(await commands.getrange(key2, 0, 1), equals(''));
    });

    test('getset', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Get.
      expect(await commands.getset(key1, 'xyz'), equals('abc'));

      // Get from an empty or non existing string.
      final key2 = uuid();
      expect(await commands.getset(key2, '123'), isNull);
    });

    test('incr', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, '11');

      // Increment.
      expect(await commands.incr(key1), equals(12));

      // Increment an empty or non existing string.
      final key2 = uuid();
      expect(await commands.incr(key2), equals(1));
    });

    test('incrby', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, '11');

      // Increment.
      expect(await commands.incrby(key1, 3), equals(14));

      // Increment an empty or non existing string.
      final key2 = uuid();
      expect(await commands.incrby(key2, 5), equals(5));
    });

    test('incrbyfloat', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, '56.73');

      // Increment
      expect(await commands.incrbyfloat(key1, 3.05), closeTo(59.78, 0.001));
      expect(await commands.incrbyfloat(key1, 1e1), closeTo(69.78, 0.001));
      expect(await commands.incrbyfloat(key1, 1e-2), closeTo(69.79, 0.001));

      // Increment an empty or non existing string.
      final key2 = uuid();
      expect(await commands.incrbyfloat(key2, -5.9), closeTo(-5.9, 0.001));
    });

    test('mget', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      await commands.set(key1, 'abc');
      await commands.set(key2, 'def');

      // Get one string.
      expect(await commands.mget(key: key1), equals(['abc']));

      // Get some strings.
      final key3 = uuid();
      expect(await commands.mget(keys: [key1, key2]), equals(['abc', 'def']));
      expect(await commands.mget(keys: [key1, key3, key2]),
          equals(['abc', null, 'def']));
      expect(await commands.mget(key: key3), [null]);
    });

    test('mset', () async {
      // Set one string.
      final key1 = uuid();
      await commands.mset(key: key1, value: 'abc');

      // Set some strings.
      final key2 = uuid();
      final key3 = uuid();
      await commands.mset(map: {key2: 'def', key3: 'xyz'});

      expect(await commands.mget(keys: [key1, key2, key3]),
          equals(['abc', 'def', 'xyz']));
    });

    test('msetnx', () async {
      // Set one string.
      final key1 = uuid();
      expect(await commands.msetnx(key: key1, value: 'abc'), equals(1));

      // Set some strings.
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      expect(await commands.msetnx(map: {key2: 'def', key3: 'xyz'}), equals(1));
      expect(await commands.msetnx(key: key1, value: 'abc'), equals(0));
      expect(await commands.msetnx(map: {key1: 'abc', key4: 'xyz'}), equals(0));
    });

    test('psetex', () async {
      final key = uuid();
      await commands.psetex(key, 5000, 'abc');

      expect(await commands.pttl(key), isNonZero);
      expect(await commands.get(key), equals('abc'));
    });

    test('set', () async {
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      expect(await commands.set(key1, 'abc'), isTrue);
      expect(await commands.set(key2, 'def'), isTrue);
      expect(await commands.set(key1, '123', seconds: 1), isTrue);
      expect(await commands.set(key2, '456', milliseconds: 1000), isTrue);
      expect(await commands.set(key3, 'xyz', mode: SetExistMode.xx), isFalse);
      expect(await commands.set(key3, 'xyz', mode: SetExistMode.nx), isTrue);
    });

    test('setbit', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Set.
      expect(await commands.setbit(key1, 7, 0), equals(1));
      expect(await commands.setbit(key1, 7, 1), equals(0));

      // Set in an empty or non existing string.
      final key2 = uuid();
      expect(await commands.setbit(key2, 12, 1), equals(0));
    });

    test('setex', () async {
      final key = uuid();
      await commands.setex(key, 5, 'abc');

      expect(await commands.pttl(key), isNonZero);
      expect(await commands.get(key), equals('abc'));
    });

    test('setnx', () async {
      final key = uuid();
      expect(await commands.setnx(key, 'abc'), equals(1));
      expect(await commands.setnx(key, 'def'), equals(0));
    });

    test('setrange', () async {
      final key = uuid();
      expect(await commands.setrange(key, 0, 'abc'), equals(3));
      expect(await commands.setrange(key, 1, 'def'), equals(4));
      expect(await commands.setrange(key, 20, 'ghi'), equals(23));
    });

    test('strlen', () async {
      final key = uuid();
      expect(await commands.strlen(key), equals(0));
      await commands.set(key, 'abc');
      expect(await commands.strlen(key), equals(3));
    });

    group('support', () {
      group('BitfieldCommand', () {
        test('toString', () {
          expect(
              BitfieldCommand.get.toString(), startsWith('BitfieldCommand:'));
        });
      });

      group('BitfieldOverflow', () {
        test('toString', () {
          expect(BitfieldOverflow.fail.toString(),
              startsWith('BitfieldOverflow:'));
        });

        group('BitopOperation', () {
          test('toString', () {
            expect(
                BitopOperation.and.toString(), startsWith('BitopOperation:'));
          });
        });

        group('SetExistMode', () {
          test('toString', () {
            expect(SetExistMode.nx.toString(), startsWith('SetExistMode:'));
          });
        });

        group('BitfieldOperation', () {
          test('toString', () {
            const value = BitfieldOperation(null, null, null);
            expect(value.toString(), startsWith('BitfieldOperation:'));
          });
        });
      });
    });
  });
}
