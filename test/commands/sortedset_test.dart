// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late SortedSetCommands<String?, String?> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('SortedSetCommands', () {
    test('bzpopmax', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0});
      await commands.zadd(key2, set: {'c': 3.0});

      // Pop from one sorted set.
      var result = await commands.bzpopmax(key: key1);
      expect(result!.key, equals(key1));
      expect(result.member!.key, equals('b'));
      expect(result.member!.value, equals(2.0));

      result = await commands.bzpopmax(key: key1);
      expect(result!.key, equals(key1));
      expect(result.member!.key, equals('a'));
      expect(result.member!.value, equals(1.0));

      // Pop from some sorted sets.
      result = await commands.bzpopmax(keys: [key1, key2]);
      expect(result!.key, equals(key2));
      expect(result.member!.key, equals('c'));
      expect(result.member!.value, equals(3.0));

      // Pop blocking.
      expect(await commands.bzpopmax(key: key1, timeout: 1), isNull);

      // Try to pop from an empty or non existing sorted set.
      final key3 = uuid();
      expect(await commands.bzpopmax(key: key3, timeout: 1), isNull);
    });

    test('bzpopmin', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0});
      await commands.zadd(key2, set: {'c': 3.0});

      // Pop from one sorted set.
      var result = await commands.bzpopmin(key: key1);
      expect(result, isNotNull);
      expect(result!.key, equals(key1));
      expect(result.member!.key, equals('a'));
      expect(result.member!.value, equals(1.0));

      result = await commands.bzpopmin(key: key1);
      expect(result, isNotNull);
      expect(result!.key, equals(key1));
      expect(result.member!.key, equals('b'));
      expect(result.member!.value, equals(2.0));

      // Pop from one from some sorted sets.
      result = await commands.bzpopmin(keys: [key1, key2]);
      expect(result, isNotNull);
      expect(result!.key, equals(key2));
      expect(result.member!.key, equals('c'));
      expect(result.member!.value, equals(3.0));

      // Pop blocking.
      expect(await commands.bzpopmin(key: key1, timeout: 1), isNull);

      // Try to pop from an empty or non existing sorted set.
      final key3 = uuid();
      expect(await commands.bzpopmin(key: key3, timeout: 1), isNull);
    });

    test('zadd', () async {
      // Add one element.
      final key = uuid();
      expect(await commands.zadd(key, score: 1.0, member: 'a'), equals(1));

      // Add some elements.
      expect(await commands.zadd(key, set: {'a': 1.0, 'b': 2.0, 'c': 3.0}),
          equals(2));

      // Add no existing.
      expect(
          await commands.zadd(key,
              mode: SortedSetExistMode.nx, set: {'a': 1.0, 'd': 4.0}),
          equals(1));

      // Add existing.
      expect(
          await commands.zadd(key,
              mode: SortedSetExistMode.xx, set: {'a': 1.0, 'e': 5.0}),
          equals(0));

      // Add returning added and changed elements.
      expect(
          await commands.zadd(key, changed: true, set: {'a': -1.0, 'f': 6.0}),
          equals(2));
    });

    test('zaddIncr', () async {
      // Add and increment.
      final key = uuid();
      expect(await commands.zaddIncr(key, 1.0, 'a'), equals(1.0));
      expect(await commands.zaddIncr(key, 2.0, 'a'), equals(3.0));

      // Add and increment non existing.
      expect(
          await commands.zaddIncr(key, 2.0, 'a', mode: SortedSetExistMode.nx),
          isNull);

      // Add and increment existing.
      expect(
          await commands.zaddIncr(key, 1.0, 'b', mode: SortedSetExistMode.xx),
          isNull);
    });

    test('zcard', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(await commands.zcard(key1), equals(3));

      // Try to get from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zcard(key2), isZero);
    });

    test('zcount', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Counts
      expect(await commands.zcount(key1, '1.0', '3.0'), equals(3));
      expect(await commands.zcount(key1, '2.0', '2.0'), equals(1));
      expect(await commands.zcount(key1, '(-2.0', '2.0'), equals(2));
      expect(await commands.zcount(key1, '2.5', '(3.5'), equals(1));
      expect(await commands.zcount(key1, '-inf', '+inf'), equals(3));

      // Try to count an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zcount(key2, '1.0', '999.0'), isZero);
    });

    test('zincrby', () async {
      final key = uuid();
      expect(await commands.zincrby(key, 1.0, 'a'), equals(1.0));
      expect(await commands.zincrby(key, 2.0, 'a'), equals(3.0));
    });

    test('zinterstore', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});
      await commands.zadd(key2, set: {'b': 8.0});

      // Compute and store.
      final key3 = uuid();
      expect(await commands.zinterstore(key3, [key1, key2]), equals(1));
      expect(await commands.zscore(key3, 'b'), equals(10.0));

      // Compute and store with weights.
      expect(
          await commands.zinterstore(key3, [key1, key2], weights: [3.0, 5.0]),
          equals(1));
      expect(await commands.zscore(key3, 'b'), equals(46.0));

      // Compute and store with aggregation.
      expect(
          await commands.zinterstore(key3, [key1, key2],
              weights: [3.0, 5.0], mode: AggregateMode.sum),
          equals(1));
      expect(await commands.zscore(key3, 'b'), equals(46.0));
      expect(
          await commands.zinterstore(key3, [key1, key2],
              weights: [3.0, 5.0], mode: AggregateMode.min),
          equals(1));
      expect(await commands.zscore(key3, 'b'), equals(6.0));
      expect(
          await commands.zinterstore(key3, [key1, key2],
              weights: [3.0, 5.0], mode: AggregateMode.max),
          equals(1));
      expect(await commands.zscore(key3, 'b'), equals(40.0));
    });

    test('zlexcount', () async {
      // Add some elements.
      final key = uuid();
      await commands.zadd(key, set: {'a': 1.0, 'b': 1.0, 'c': 1.0});

      // Count.
      expect(await commands.zlexcount(key, '-', '+'), equals(3));
      expect(await commands.zlexcount(key, '[a', '[b'), equals(2));
      expect(await commands.zlexcount(key, '(b', '[c'), equals(1));
      expect(await commands.zlexcount(key, '(c', '+'), equals(0));
    });

    test('zpopmax', () async {
      // Add some elements.
      final key = uuid();
      await commands.zadd(key, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Pop.
      expect(await commands.zpopmax(key), containsPair('c', 3.0));
      expect(await commands.zpopmax(key, count: 2),
          allOf(containsPair('a', 1.0), containsPair('b', 2.0)));
      expect(await commands.zpopmax(key), isEmpty);
    });

    test('zpopmin', () async {
      // Add some elements.
      final key = uuid();
      await commands.zadd(key, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Pop.
      expect(await commands.zpopmin(key), containsPair('a', 1.0));
      expect(await commands.zpopmin(key, count: 2),
          allOf(containsPair('b', 2.0), containsPair('c', 3.0)));
      expect(await commands.zpopmin(key), isEmpty);
    });

    test('zrange', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(
          await commands.zrange(key1, 0, 2),
          allOf(containsPair('a', null), containsPair('b', null),
              containsPair('c', null)));
      expect(await commands.zrange(key1, 1, 2),
          allOf(containsPair('b', null), containsPair('c', null)));

      // Get with scores.
      expect(
          await commands.zrange(key1, 0, 2, withScores: true),
          allOf(containsPair('a', 1.0), containsPair('b', 2.0),
              containsPair('c', 3.0)));
      expect(await commands.zrange(key1, 1, 2, withScores: true),
          allOf(containsPair('b', 2.0), containsPair('c', 3.0)));

      // Try to get from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zrange(key2, 0, 99), isEmpty);
    });

    test('zrangebylex', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(await commands.zrangebylex(key1, '[a', '[c]'),
          equals(<String>['a', 'b', 'c']));
      expect(await commands.zrangebylex(key1, '[b', '+'),
          equals(<String>['b', 'c']));

      // Get limiting the results.
      expect(await commands.zrangebylex(key1, '[a', '[c', offset: 1, count: 2),
          equals(<String>['b', 'c']));

      // Try to get from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zrangebylex(key2, '-', '+'), isEmpty);
    });

    test('zrangebyscore', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(
          await commands.zrangebyscore(key1, '-inf', '+inf'),
          allOf(containsPair('a', null), containsPair('b', null),
              containsPair('c', null)));
      expect(await commands.zrangebyscore(key1, '2.0', '99.0'),
          allOf(containsPair('b', null), containsPair('c', null)));

      // Get with scores.
      expect(
          await commands.zrangebyscore(key1, '-inf', '+inf', withScores: true),
          allOf(containsPair('a', 1.0), containsPair('b', 2.0),
              containsPair('c', 3.0)));
      expect(
          await commands.zrangebyscore(key1, '2.0', ' 99.0', withScores: true),
          allOf(containsPair('b', 2.0), containsPair('c', 3.0)));

      // Get limiting the results.
      expect(
          await commands.zrangebyscore(key1, '0.0', '99.0',
              offset: 1, count: 2),
          allOf(containsPair('b', null), containsPair('c', null)));

      // Try to get from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zrangebyscore(key2, '0.0', '1.0'), isEmpty);
    });

    test('zrank', () async {
      // Add some elements.
      final key = uuid();
      await commands.zadd(key, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(await commands.zrank(key, 'a'), equals(0));
      expect(await commands.zrank(key, 'b'), equals(1));
      expect(await commands.zrank(key, 'c'), equals(2));
      expect(await commands.zrank(key, 'x'), isNull);
    });

    test('zrem', () async {
      // Adds some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Remove.
      expect(await commands.zrem(key1, member: 'a'), equals(1));
      expect(await commands.zrem(key1, members: ['b', 'c', 'd']), equals(2));

      // Try to remove from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zrem(key2, member: 'x'), 0);
    });

    test('zremrangebylex', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Remove.
      expect(await commands.zremrangebylex(key1, '[a', '(b'), equals(1));
      expect(await commands.zremrangebylex(key1, '-', '+'), equals(2));

      // Try to remove from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zremrangebylex(key2, '-', '+'), 0);
    });

    test('zremrangebyrank', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Remove.
      expect(await commands.zremrangebyrank(key1, 0, 0), equals(1));
      expect(await commands.zremrangebyrank(key1, 0, 99), equals(2));

      // Try to remove from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zremrangebyrank(key2, 0, 99), 0);
    });

    test('zremrangebyscore', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Remove.
      expect(await commands.zremrangebyscore(key1, '1.0', '1.0'), equals(1));
      expect(await commands.zremrangebyscore(key1, '0.0', '(99.0'), equals(2));
      expect(await commands.zremrangebyscore(key1, '-inf', '+inf'), equals(0));

      // Try to remove from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zremrangebyscore(key2, '0.0', '99.0'), 0);
    });

    test('zrevrange', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(
          await commands.zrevrange(key1, 0, 2),
          allOf(hasLength(3), containsPair('a', null), containsPair('b', null),
              containsPair('c', null)));
      expect(
          await commands.zrevrange(key1, 1, 2),
          allOf(
              hasLength(2), containsPair('a', null), containsPair('b', null)));

      // Get with scores.
      expect(
          await commands.zrevrange(key1, 0, 2, withScores: true),
          allOf(hasLength(3), containsPair('a', 1.0), containsPair('b', 2.0),
              containsPair('c', 3.0)));
      expect(await commands.zrevrange(key1, 1, 2, withScores: true),
          allOf(hasLength(2), containsPair('a', 1.0), containsPair('b', 2.0)));

      // Try to get from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zrevrange(key2, 0, 99), isEmpty);
    });

    test('zrevrangebylex', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(await commands.zrevrangebylex(key1, '[c]', '[a'),
          equals(<String>['c', 'b', 'a']));
      expect(await commands.zrevrangebylex(key1, '+', '[b'),
          equals(<String>['c', 'b']));

      // Get limiting the results.
      expect(
          await commands.zrevrangebylex(key1, '[c', '[a', offset: 1, count: 2),
          equals(<String>['b', 'a']));

      // Try to get from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zrevrangebylex(key2, '+', '-'), isEmpty);
    });

    test('zrevrangebyscore', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(
          await commands.zrevrangebyscore(key1, '+inf', '-inf'),
          allOf(hasLength(3), containsPair('a', null), containsPair('b', null),
              containsPair('c', null)));
      expect(
          await commands.zrevrangebyscore(key1, '99.0', '2.0'),
          allOf(
              hasLength(2), containsPair('b', null), containsPair('c', null)));

      // Get with scores.
      expect(
          await commands.zrevrangebyscore(key1, '+inf', '-inf',
              withScores: true),
          allOf(hasLength(3), containsPair('a', 1.0), containsPair('b', 2.0),
              containsPair('c', 3.0)));
      expect(
          await commands.zrevrangebyscore(key1, '99.0', '2.0',
              withScores: true),
          allOf(hasLength(2), containsPair('b', 2.0), containsPair('c', 3.0)));

      // Get limiting the results.
      expect(
          await commands.zrevrangebyscore(key1, '99.0', '0.0',
              offset: 1, count: 2),
          allOf(
              hasLength(2), containsPair('a', null), containsPair('b', null)));

      // Try to get from an empty or non existing sorted set.
      final key2 = uuid();
      expect(await commands.zrevrangebyscore(key2, '1.0', '0.0'), isEmpty);
    });

    test('zrevrank', () async {
      // Add some elements.
      final key = uuid();
      await commands.zadd(key, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(await commands.zrevrank(key, 'a'), equals(2));
      expect(await commands.zrevrank(key, 'b'), equals(1));
      expect(await commands.zrevrank(key, 'c'), equals(0));
      expect(await commands.zrevrank(key, 'x'), isNull);
    });

    test('zscan', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Scan.
      var result = await commands.zscan(key1, 0);
      expect(result.cursor, equals(0));
      expect(result.members, hasLength(3));
      expect(
          result.members,
          allOf(containsPair('a', 1.0), containsPair('b', 2.0),
              containsPair('c', 3.0)));

      // Scan with a hint.
      result = await commands.zscan(key1, 0, count: 5);
      expect(result.cursor, isZero);
      expect(result.members, hasLength(3));

      // Scan with a pattern.
      result = await commands.zscan(key1, 0, pattern: 'a*');
      expect(result.cursor, isZero);
      expect(result.members, hasLength(1));

      // Try to scan an empty or not existing sorted set.
      final key2 = uuid();
      result = await commands.zscan(key2, 0);
      expect(result.cursor, isZero);
      expect(result.members, isEmpty);
    });

    test('zscore', () async {
      // Add some elements.
      final key = uuid();
      await commands.zadd(key, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});

      // Get.
      expect(await commands.zscore(key, 'a'), equals(1.0));
      expect(await commands.zscore(key, 'b'), equals(2.0));
      expect(await commands.zscore(key, 'c'), equals(3.0));
      expect(await commands.zscore(key, 'x'), isNull);
    });

    test('zunionstore', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      await commands.zadd(key1, set: {'a': 1.0, 'b': 2.0, 'c': 3.0});
      await commands.zadd(key2, set: {'b': 8.0});

      // Compute and store.
      final key3 = uuid();
      expect(await commands.zunionstore(key3, [key1, key2]), equals(3));
      expect(await commands.zscore(key3, 'a'), equals(1.0));
      expect(await commands.zscore(key3, 'b'), equals(10.0));
      expect(await commands.zscore(key3, 'c'), equals(3.0));

      // Compute and store with weights.
      expect(
          await commands.zunionstore(key3, [key1, key2], weights: [3.0, 5.0]),
          equals(3));
      expect(await commands.zscore(key3, 'a'), equals(3.0));
      expect(await commands.zscore(key3, 'b'), equals(46.0));
      expect(await commands.zscore(key3, 'c'), equals(9.0));

      // Compute and store with aggregation.
      expect(
          await commands.zunionstore(key3, [key1, key2],
              weights: [3.0, 5.0], mode: AggregateMode.sum),
          equals(3));
      expect(await commands.zscore(key3, 'a'), equals(3.0));
      expect(await commands.zscore(key3, 'b'), equals(46.0));
      expect(await commands.zscore(key3, 'c'), equals(9.0));

      expect(
          await commands.zunionstore(key3, [key1, key2],
              weights: [3.0, 5.0], mode: AggregateMode.min),
          equals(3));
      expect(await commands.zscore(key3, 'a'), equals(3.0));
      expect(await commands.zscore(key3, 'b'), equals(6.0));
      expect(await commands.zscore(key3, 'c'), equals(9.0));

      expect(
          await commands.zunionstore(key3, [key1, key2],
              weights: [3.0, 5.0], mode: AggregateMode.max),
          equals(3));
      expect(await commands.zscore(key3, 'a'), equals(3.0));
      expect(await commands.zscore(key3, 'b'), equals(40.0));
      expect(await commands.zscore(key3, 'c'), equals(9.0));
    });

    group('support', () {
      group('SortedSetExistMode', () {
        test('toString', () {
          expect(SortedSetExistMode.nx.toString(),
              startsWith('SortedSetExistMode:'));
        });
      });

      group('AggregateMode', () {
        test('toString', () {
          expect(AggregateMode.max.toString(), startsWith('AggregateMode:'));
        });
      });

      group('SortedSetPopResult', () {
        test('toString', () {
          const value = SortedSetPopResult<String?, String>(null, null);
          expect(value.toString(),
              startsWith('SortedSetPopResult<String?, String>:'));
        });
      });

      group('SortedSetScanResult', () {
        test('toString', () {
          const value = SortedSetScanResult<String>(null, null);
          expect(value.toString(), startsWith('SortedSetScanResult<String>:'));
        });
      });
    });
  });
}
