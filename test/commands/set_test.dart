// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late SetCommands<String, String> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('SetCommands', () {
    test('sadd', () async {
      // Add one element.
      final key = uuid();
      expect(await commands.sadd(key, member: 'a'), equals(1));
      expect(await commands.sadd(key, member: 'a'), equals(0));

      // Add some elements.
      expect(await commands.sadd(key, members: ['b', 'c']), equals(2));
      expect(await commands.sadd(key, members: ['a', 'd', 'c']), equals(1));
    });

    test('scard', () async {
      // Adds some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Get.
      expect(await commands.scard(key1), equals(3));

      // Try to get the cardinality of an empty or non existing set.
      final key2 = uuid();
      expect(await commands.scard(key2), equals(0));
    });

    test('sdiff', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);
      await commands.sadd(key2, members: ['b']);
      await commands.sadd(key3, members: ['x', 'y', 'z']);
      await commands.sadd(key4, members: ['a', 'b', 'c']);

      // Compute.
      expect(
          await commands.sdiff(key1), unorderedEquals(<String>['a', 'b', 'c']));
      expect(await commands.sdiff(key1, keys: [key2]),
          unorderedEquals(<String>['a', 'c']));
      expect(await commands.sdiff(key1, keys: [key3]),
          unorderedEquals(<String>['a', 'b', 'c']));
      expect(
          await commands.sdiff(key1, keys: [key2, key4]), equals(<String>[]));
    });

    test('sdiffstore', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      final key5 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);
      await commands.sadd(key2, members: ['b']);
      await commands.sadd(key3, members: ['x', 'y', 'z']);
      await commands.sadd(key4, members: ['a', 'b', 'c']);

      // Compute and store.
      expect(await commands.sdiffstore(key5, key1), equals(3));
      expect(await commands.sdiffstore(key5, key1, keys: [key2]), equals(2));
      expect(await commands.sdiffstore(key5, key1, keys: [key3]), equals(3));
      expect(
          await commands.sdiffstore(key5, key1, keys: [key2, key4]), equals(0));
    });

    test('sinter', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);
      await commands.sadd(key2, members: ['a', 'c']);
      await commands.sadd(key3, members: ['b', 'c']);
      await commands.sadd(key4, members: ['x', 'y', 'z']);

      // Compute.
      expect(await commands.sinter(key1),
          unorderedEquals(<String>['a', 'b', 'c']));
      expect(await commands.sinter(key1, keys: [key2]),
          unorderedEquals(<String>['a', 'c']));
      expect(await commands.sinter(key1, keys: [key2, key3]),
          unorderedEquals(<String>['c']));
      expect(await commands.sinter(key1, keys: [key4]), equals(<String>[]));
    });

    test('sinterstore', () async {
      // Adds some elements.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      final key5 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);
      await commands.sadd(key2, members: ['a', 'c']);
      await commands.sadd(key3, members: ['b', 'c']);
      await commands.sadd(key4, members: ['x', 'y', 'z']);

      // Compute and store.
      expect(await commands.sinterstore(key5, key1), equals(3));
      expect(await commands.sinterstore(key5, key1, keys: [key2]), equals(2));
      expect(await commands.sinterstore(key5, key1, keys: [key2, key3]),
          equals(1));
      expect(await commands.sinterstore(key5, key1, keys: [key4]), equals(0));
    });

    test('sismember', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Check.
      expect(await commands.sismember(key1, 'b'), equals(1));

      // Try to check an empty or non existing set.
      expect(await commands.sismember(key1, 'x'), equals(0));

      final key2 = uuid();
      expect(await commands.sismember(key2, 'a'), equals(0));
    });

    test('smembers', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Get.
      expect(await commands.smembers(key1),
          unorderedEquals(<String>['a', 'b', 'c']));

      // Try to get from an empty or non existing set.
      final key2 = uuid();
      expect(await commands.smembers(key2), equals(<String>[]));
    });

    test('smove', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Move.
      final key2 = uuid();
      expect(await commands.smove(key1, key2, 'a'), equals(1));
      expect(await commands.smove(key1, key2, 'd'), equals(0));

      // Try to move from an empty or non existing set.
      final key3 = uuid();
      expect(await commands.smove(key3, key2, 'a'), equals(0));
    });

    test('spop', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Pop.
      expect(await commands.spop(key1), isNotNull);
      expect(await commands.spop(key1), isNotNull);
      expect(await commands.spop(key1), isNotNull);
      expect(await commands.spop(key1), isNull);

      // Try to pop from an empty or non existing set.
      final key2 = uuid();
      expect(await commands.spop(key2), isNull);
    });

    test('spopCount', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Pop.
      expect(await commands.spopCount(key1, 1), hasLength(1));
      expect(await commands.spopCount(key1, 2), hasLength(2));
      expect(await commands.spopCount(key1, 1), isEmpty);

      // Try to pop from an empty or non existing set.
      final key2 = uuid();
      expect(await commands.spopCount(key2, 1), isEmpty);
    });

    test('srandmember', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Get
      expect(await commands.srandmember(key1), isNotNull);

      // Try to get from an empty or non existing set.
      final key2 = uuid();
      expect(await commands.srandmember(key2), isNull);
    });

    test('srandmemberCount', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Get
      expect(await commands.srandmemberCount(key1, 1), hasLength(1));
      expect(await commands.srandmemberCount(key1, 2), hasLength(2));

      // Try to get from an empty or non existing set.
      final key2 = uuid();
      expect(await commands.srandmemberCount(key2, 1), isEmpty);
    });

    test('srem', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Remove.
      expect(await commands.srem(key1, member: 'a'), equals(1));
      expect(await commands.srem(key1, members: ['b', 'x', 'c']), equals(2));

      // Try to remove from an empty or non existing set.
      final key2 = uuid();
      expect(await commands.srem(key2, member: 'x'), isZero);
    });

    test('sscan', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);

      // Scan.
      var result = await commands.sscan(key1, 0);
      expect(result.cursor, greaterThanOrEqualTo(0));
      expect(result.members, unorderedEquals(<String>['a', 'b', 'c']));

      // Scan with a hint.
      result = await commands.sscan(key1, 0, count: 5);
      expect(result.cursor, greaterThanOrEqualTo(0));
      expect(result.members, unorderedEquals(<String>['a', 'b', 'c']));

      // Scan with a pattern.
      result = await commands.sscan(key1, 0, pattern: 'a*');
      expect(result.cursor, greaterThanOrEqualTo(0));
      expect(result.members, equals(<String>['a']));

      // Try to scan a non existing set.
      final key2 = uuid();
      result = await commands.sscan(key2, 0);
      expect(result.cursor, greaterThanOrEqualTo(0));
      expect(result.members, isEmpty);
    });

    test('sunion', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);
      await commands.sadd(key2, members: ['a', 'b']);
      await commands.sadd(key3, members: ['1', '2']);

      // Compute.
      expect(await commands.sunion(key1),
          unorderedEquals(<String>['a', 'b', 'c']));
      expect(await commands.sunion(key1, keys: [key2]),
          unorderedEquals(<String>['a', 'b', 'c']));
      expect(await commands.sunion(key1, keys: [key2, key3]),
          unorderedEquals(<String>['a', 'b', 'c', '1', '2']));
    });

    test('sunionstore', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      await commands.sadd(key1, members: ['a', 'b', 'c']);
      await commands.sadd(key2, members: ['a', 'b']);
      await commands.sadd(key3, members: ['1', '2']);

      // Compute and store.
      expect(await commands.sunionstore(key4, key1), equals(3));
      expect(await commands.sunionstore(key4, key1, keys: [key2]), equals(3));
      expect(await commands.sunionstore(key4, key1, keys: [key2, key3]),
          equals(5));
    });

    group('support', () {
      group('SetScanResult', () {
        test('toString', () {
          const value = SetScanResult<String>(null, null);
          expect(value.toString(), startsWith('SetScanResult<String>:'));
        });
      });
    });
  });
}
