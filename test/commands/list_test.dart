// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late ListCommands<String?, String?> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('ListCommands', () {
    test('blpop', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      await commands.rpush(key1, values: ['a', 'b', 'c']);
      await commands.rpush(key2, values: ['d', 'e', 'f']);

      // Pop one element.
      var result = await commands.blpop(key: key1);
      expect(result!.key, equals(key1));
      expect(result.value, equals('a'));
      result = await commands.blpop(key: key1);
      expect(result!.key, equals(key1));
      expect(result.value, equals('b'));

      // Pop some elements.
      result = await commands.blpop(keys: [key1, key2]);
      expect(result!.key, equals(key1));
      expect(result.value, equals('c'));
      result = await commands.blpop(keys: [key1, key2]);
      expect(result!.key, equals(key2));
      expect(result.value, equals('d'));
      result = await commands.blpop(keys: [key1, key2]);
      expect(result!.key, equals(key2));
      expect(result.value, equals('e'));

      // Pop blocking.
      result = await commands.blpop(keys: [key1, key2], timeout: 1);
      expect(result!.key, equals(key2));
      expect(result.value, equals('f'));

      // Try to pop from an empty or non existing list.
      expect(await commands.blpop(key: key2, timeout: 1), isNull);

      final key3 = uuid();
      expect(await commands.blpop(key: key3, timeout: 1), isNull);
    });

    test('brpop', () async {
      // Add some elements.
      final key1 = uuid();
      final key2 = uuid();
      await commands.rpush(key1, values: ['a', 'b', 'c']);
      await commands.rpush(key2, values: ['d', 'e', 'f']);

      // Pop one element.
      var result = await commands.brpop(key: key1);
      expect(result!.key, equals(key1));
      expect(result.value, equals('c'));
      result = await commands.brpop(key: key1);
      expect(result!.key, equals(key1));
      expect(result.value, equals('b'));

      // Pop some elements.
      result = await commands.brpop(keys: [key1, key2]);
      expect(result!.key, equals(key1));
      expect(result.value, equals('a'));
      result = await commands.brpop(keys: [key1, key2]);
      expect(result!.key, equals(key2));
      expect(result.value, equals('f'));
      result = await commands.brpop(keys: [key1, key2]);
      expect(result!.key, equals(key2));
      expect(result.value, equals('e'));

      // Pop blocking.
      result = await commands.brpop(keys: [key1, key2], timeout: 1);
      expect(result!.key, equals(key2));
      expect(result.value, equals('d'));

      // Try to pop from an empty or non existing list.
      expect(await commands.brpop(key: key2, timeout: 1), isNull);

      final key3 = uuid();
      expect(await commands.brpop(key: key3, timeout: 1), isNull);
    });

    test('brpoplpush', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.rpush(key1, values: ['one', 'two', 'three']);

      // Pop and push.
      final key2 = uuid();
      expect(await commands.brpoplpush(key1, key2), equals('three'));
      expect(await commands.brpoplpush(key1, key2), equals('two'));

      // Pop and push blocking.
      expect(await commands.brpoplpush(key1, key2, timeout: 1), equals('one'));

      // Pop and push over the same list.
      expect(await commands.brpoplpush(key2, key2), equals('three'));

      // Try to pop from empty or non existing list.
      expect(await commands.brpoplpush(key1, key2, timeout: 1), isNull);

      final key3 = uuid();
      expect(await commands.brpoplpush(key3, key2, timeout: 1), isNull);
    });

    test('lindex', () async {
      // Add some elements.
      final key = uuid();
      await commands.rpush(key, values: ['one', 'two', 'three']);

      // Get.
      expect(await commands.lindex(key, 0), equals('one'));
      expect(await commands.lindex(key, 1), equals('two'));
      expect(await commands.lindex(key, -1), equals('three'));

      // Try to get from an index out of range.
      expect(await commands.lindex(key, 99), isNull);
    });

    test('linsert', () async {
      // Add some elements.
      final key = uuid();
      await commands.rpush(key, values: ['one', 'two', 'three']);

      // Insert after.
      expect(await commands.linsert(key, InsertPosition.after, 'one', '1.5'),
          equals(4));

      expect(await commands.lindex(key, 1), equals('1.5'));

      // Insert before.
      expect(await commands.linsert(key, InsertPosition.before, 'three', '2.5'),
          equals(5));

      expect(await commands.lindex(key, 3), equals('2.5'));

      // Try to insert after/before non existing elements.
      expect(await commands.linsert(key, InsertPosition.after, 'four', '5'),
          equals(-1));
      expect(await commands.linsert(key, InsertPosition.before, 'zero', '-1'),
          equals(-1));
    });

    test('llen', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.rpush(key1, values: ['one', 'two', 'three']);

      // Get the length.
      expect(await commands.llen(key1), equals(3));
      await commands.rpop(key1);
      expect(await commands.llen(key1), equals(2));
      await commands.rpop(key1);
      expect(await commands.llen(key1), equals(1));

      // Try to get the length of an empty or non existing list.
      await commands.rpop(key1);
      expect(await commands.llen(key1), isZero);

      final key2 = uuid();
      expect(await commands.llen(key2), isZero);
    });

    test('lpop', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.rpush(key1, values: ['one', 'two', 'three']);

      // Pop.
      expect(await commands.lpop(key1), equals('one'));
      expect(await commands.lpop(key1), equals('two'));
      expect(await commands.lpop(key1), equals('three'));

      // Try to pop from an empty or non existing list.
      expect(await commands.lpop(key1), isNull);

      final key2 = uuid();
      expect(await commands.lpop(key2), isNull);
    });

    test('lpush', () async {
      // Push one element.
      final key = uuid();
      expect(await commands.lpush(key, value: 'one'), equals(1));

      // Push some elements.
      expect(await commands.lpush(key, values: ['two', 'three']), equals(3));
    });

    test('lpushx', () async {
      // Try to push into non existing list.
      final key = uuid();
      expect(await commands.lpushx(key, 'one'), isZero);

      // Push.
      await commands.rpush(key, value: 'two');

      expect(await commands.lpushx(key, 'three'), equals(2));
    });

    test('lrange', () async {
      // Add some elements.
      final key = uuid();
      await commands.rpush(key, values: ['one', 'two', 'three']);

      // Get.
      expect(await commands.lrange(key, 0, 0), equals(['one']));
      expect(await commands.lrange(key, -2, -1), equals(['two', 'three']));
      expect(await commands.lrange(key, 2, 5), equals(['three']));
      expect(await commands.lrange(key, 999, 1000), isEmpty);
    });

    test('lrem', () async {
      // Add some elements.
      final key = uuid();
      await commands
          .rpush(key, values: ['one', 'two', 'two', 'three', 'three', 'three']);

      // Remove.
      expect(await commands.lrem(key, 1, 'one'), equals(1));
      expect(await commands.lrem(key, 2, 'two'), equals(2));
      expect(await commands.lrem(key, 5, 'three'), equals(3));
      expect(await commands.lrem(key, 1, 'four'), equals(0));
    });

    test('lset', () async {
      // Add some elements.
      final key = uuid();
      await commands.rpush(key, values: ['one', 'two', 'three']);

      // Set.
      await commands.lset(key, 0, '1');
      await commands.lset(key, 1, '2');
      await commands.lset(key, -1, '3');

      expect(await commands.lindex(key, 0), equals('1'));
      expect(await commands.lindex(key, 1), equals('2'));
      expect(await commands.lindex(key, 2), equals('3'));
    });

    test('ltrim', () async {
      // Add some elements.
      final key = uuid();
      await commands.rpush(key, values: ['one', 'two', 'three']);

      // Trim.
      await commands.ltrim(key, 0, 1);
      expect(await commands.lrange(key, 0, 999), equals(['one', 'two']));
      await commands.ltrim(key, -1, 5);
      expect(await commands.lrange(key, 0, 999), equals(['two']));
    });

    test('rpop', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.rpush(key1, values: ['one', 'two', 'three']);

      // Pop.
      expect(await commands.rpop(key1), equals('three'));
      expect(await commands.rpop(key1), equals('two'));
      expect(await commands.rpop(key1), equals('one'));

      // Try to pop from an empty or non existing list.
      expect(await commands.rpop(key1), isNull);

      final key2 = uuid();
      expect(await commands.rpop(key2), isNull);
    });

    test('rpoplpush', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.rpush(key1, values: ['one', 'two', 'three']);

      // Pop and push.
      final key2 = uuid();
      expect(await commands.rpoplpush(key1, key2), equals('three'));
      expect(await commands.rpoplpush(key1, key2), equals('two'));
      expect(await commands.rpoplpush(key1, key2), equals('one'));

      // Pop and push over the same list.
      expect(await commands.rpoplpush(key2, key2), equals('three'));

      // Try to pop from and empty or non existing list.
      expect(await commands.rpoplpush(key1, key2), isNull);

      final key3 = uuid();
      expect(await commands.rpoplpush(key3, key2), isNull);
    });

    test('rpush', () async {
      // Push one element.
      final key = uuid();
      expect(await commands.rpush(key, value: 'one'), equals(1));

      // Push some elements.
      expect(await commands.rpush(key, values: ['two', 'three']), equals(3));
    });

    test('rpushx', () async {
      // Try to push into non existing list.
      final key = uuid();
      expect(await commands.rpushx(key, 'one'), isZero);

      // Push.
      await commands.rpush(key, value: 'two');

      expect(await commands.rpushx(key, 'three'), equals(2));
    });

    group('support', () {
      group('InsertPosition', () {
        test('toString', () {
          expect(
              InsertPosition.after.toString(), startsWith('InsertPosition:'));
        });
      });

      group('ListPopResult', () {
        test('toString', () {
          const value = ListPopResult<String?, String?>(null, null);
          expect(
              value.toString(), startsWith('ListPopResult<String?, String?>:'));
        });
      });
    });
  });
}
