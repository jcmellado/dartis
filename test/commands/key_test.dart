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

  group('KeyCommands', () {
    test('del', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      await commands.set(key1, 'abc');
      await commands.set(key2, 'def');
      await commands.set(key3, 'ghi');

      // Remove one key.
      expect(await commands.del(key: key1), equals(1));

      // Remove some keys.
      expect(await commands.del(keys: [key2, key3]), equals(2));

      // Try to remove a non existing key.
      expect(await commands.del(key: key1), equals(0));
      expect(await commands.del(keys: [key2, key3]), equals(0));
    });

    test('dump', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Dump.
      expect(await commands.dump(key1), isNotEmpty);

      // Try to dump a non existing key.
      final key2 = uuid();
      expect(await commands.dump(key2), isNull);
    });

    test('exists', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      await commands.set(key1, 'abc');
      await commands.set(key2, 'def');

      // Check if a keys exists.
      expect(await commands.exists(key: key1), equals(1));

      // Check if some keys exists.
      expect(await commands.exists(keys: [key1, key2]), equals(2));

      // Check non existing keys.
      final key3 = uuid();
      expect(await commands.exists(key: key3), equals(0));
      expect(await commands.exists(keys: [key1, key2, key3]), equals(2));
    });

    test('expire', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Expire.
      expect(await commands.expire(key1, 1), equals(1));

      // Try to expire a non existing key.
      final key2 = uuid();
      expect(await commands.expire(key2, 1), equals(0));
    });

    test('expireat', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Expire.
      expect(await commands.expireat(key1, 0), equals(1));

      // Try to expire a non existing key.
      final key2 = uuid();
      expect(await commands.expireat(key2, 0), equals(0));
    });

    test('keys', () async {
      // Add some values.
      final key = uuid();
      await commands.set(key, 'abc');

      // Search.
      expect(await commands.keys(key), equals([key]));
      expect(await commands.keys('$key*'), isNotEmpty);
      expect(await commands.keys('${key}_'), isEmpty);
    });

    test('migrate', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      await commands.set(key1, 'abc');
      await commands.set(key2, 'def');
      await commands.set(key3, '123');
      await commands.set(key4, '456');

      // Migrate one key.
      expect(await commands.migrate('127.0.0.1', 6380, 0, 1000, key: key1),
          equals('OK'));
      expect(
          await commands.migrate('127.0.0.1', 6380, 0, 1000,
              copy: true, key: key2),
          equals('OK'));
      expect(
          await commands.migrate('127.0.0.1', 6380, 0, 1000,
              copy: true, replace: true, key: key2),
          equals('OK'));

      // Migrate some keys.
      expect(
          await commands
              .migrate('127.0.0.1', 6380, 0, 1000, keys: [key2, key3]),
          equals('OK'));
      expect(
          await commands.migrate('127.0.0.1', 6380, 0, 1000,
              copy: true, keys: [key2, key3]),
          equals('OK'));
      expect(
          await commands.migrate('127.0.0.1', 6380, 0, 1000,
              copy: true, replace: true, keys: [key2, key3]),
          equals('OK'));

      // Try to migrate a non existing key.
      final key5 = uuid();
      expect(await commands.migrate('127.0.0.1', 6380, 0, 1000, key: key5),
          equals('NOKEY'));
    }, skip: 'Requires a second Redis instance.');

    test('move', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Move.
      expect(await commands.move(key1, 1), equals(1));
      expect(await commands.move(key1, 1), equals(0));

      // Try to move a non existing key.
      final key2 = uuid();
      expect(await commands.move(key2, 1), equals(0));
    });

    test('object', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Inpects
      expect(await commands.object(ObjectSubcommand.refcount, key1), isNotNull);
      expect(await commands.object(ObjectSubcommand.encoding, key1), isNotNull);
      expect(await commands.object(ObjectSubcommand.idletime, key1), isNotNull);

      // Only available when maxmemory-policy is set to an LFU policy:
      //expect(
      //    await commands.object(ObjectSubcommand.freq, key: key1),
      // isNotNull);

      // Try to inspects a non existing key.
      final key2 = uuid();
      expect(await commands.object(ObjectSubcommand.encoding, key2), isNull);
    });

    test('objectHelp', () async {
      expect(await commands.objectHelp(), isNotEmpty);
    });

    test('persist', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Set a expiration timeout and then persist.
      await commands.expire(key1, 5000);
      expect(await commands.persist(key1), equals(1));

      // Try to persit and key without an associated timeout.
      expect(await commands.persist(key1), equals(0));

      // Try to persits a non existing key.
      final key2 = uuid();
      expect(await commands.persist(key2), equals(0));
    });

    test('pexpire', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Expire.
      expect(await commands.pexpire(key1, 1000), equals(1));

      // Try to expire a non existing key.
      final key2 = uuid();
      expect(await commands.pexpire(key2, 1000), equals(0));
    });

    test('pexpireat', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Expire.
      expect(await commands.pexpireat(key1, 0), equals(1));

      // Try to expire a non existing key.
      final key2 = uuid();
      expect(await commands.pexpireat(key2, 0), equals(0));
    });

    test('pttl', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Try to get from a non existing key or without associated timeout.
      expect(await commands.pttl(key1), equals(-1));

      final key2 = uuid();
      expect(await commands.pttl(key2), equals(-2));

      // Expire and get.
      await commands.expire(key1, 5);
      expect(await commands.pttl(key1), isNonNegative);
    });

    test('randomkey', () async {
      // Flush all and try to get.
      await commands.flushall();
      expect(await commands.randomkey(), isNull);

      // Add and get.
      final key = uuid();
      await commands.set(key, 'abc');
      expect(await commands.randomkey(), isNotNull);
    }, skip: 'Removes all the key from all the databases.');

    test('rename', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Rename.
      final key2 = uuid();
      await commands.rename(key1, key2);

      expect(await commands.exists(key: key1), isZero);
      expect(await commands.get(key2), equals('abc'));
    });

    test('renamenx', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Rename.
      final key2 = uuid();
      expect(await commands.renamenx(key1, key2), equals(1));

      expect(await commands.exists(key: key1), isZero);
      expect(await commands.get(key2), equals('abc'));

      // Try to overwrite an existing key.
      final key3 = uuid();
      await commands.set(key3, 'xyz');

      expect(await commands.renamenx(key2, key3), isZero);
    });

    test('restore', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Dump and restore.
      final value = (await commands.dump(key1))!;

      final key2 = uuid();
      await commands.restore(key2, 0, value);

      expect(await commands.get(key2), equals('abc'));

      // Dump and replace.
      await commands.restore(key2, 0, value, replace: true);
    });

    test('scan', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      await commands.mset(map: {key1: 'abc', key2: 'def', key3: 'ghi'});

      // Scan.
      var result = await commands.scan(0);
      expect(result.cursor, greaterThanOrEqualTo(0));
      expect(result.keys, isNotEmpty);

      // Scan with a hint.
      result = await commands.scan(0, count: 5);
      expect(result.cursor, greaterThanOrEqualTo(0));
      expect(result.keys, isNotEmpty);

      // Scan with a pattern.
      result = await commands.scan(0, pattern: '$key1*', count: 1000);
      expect(result.cursor, greaterThanOrEqualTo(0));

      // Try to scan a non existing key.
      final key4 = uuid();
      result = await commands.scan(0, pattern: key4, count: 1000);
      expect(result.cursor, greaterThanOrEqualTo(0));
      expect(result.keys, isEmpty);
    });

    test('sort', () async {
      // Add some values.
      final key1 = uuid();
      await commands.rpush(key1, values: ['2', '3', '1']);

      // Sort.
      expect(await commands.sort(key1), equals(['1', '2', '3']));

      // Sort with weights.
      await commands.set('${key1}_w1', '3');
      await commands.set('${key1}_w2', '2');
      await commands.set('${key1}_w3', '1');

      expect(
          await commands.sort(key1, by: '${key1}_w*'), equals(['3', '2', '1']));

      // Sort limiting the results.
      expect(
          await commands.sort(key1, offset: 1, count: 99), equals(['2', '3']));

      // Sort with getters.
      await commands.set('${key1}_g1', 'x');
      await commands.set('${key1}_g2', 'y');
      await commands.set('${key1}_g3', 'z');

      expect(await commands.sort(key1, get: ['${key1}_g*']),
          equals(['x', 'y', 'z']));
      expect(await commands.sort(key1, get: ['${key1}_g*', '${key1}_unkw_*']),
          equals(['x', null, 'y', null, 'z', null]));
      expect(
          await commands.sort(key1, get: ['#', '${key1}_g*', '${key1}_unkw_*']),
          equals(['1', 'x', null, '2', 'y', null, '3', 'z', null]));

      // Sort with an explicit order.
      expect(await commands.sort(key1, order: SortOrder.ascending),
          equals(['1', '2', '3']));
      expect(await commands.sort(key1, order: SortOrder.descending),
          equals(['3', '2', '1']));

      // Sort using an alphabetical order.
      final key2 = uuid();
      await commands.rpush(key2, values: ['b', 'c', 'a']);

      expect(await commands.sort(key2, alpha: true), equals(['a', 'b', 'c']));

      // Try to sort a non existing key.
      final key3 = uuid();
      expect(await commands.sort(key3), isEmpty);
    });

    test('sortStore', () async {
      // Add some values.
      final key1 = uuid();
      await commands.rpush(key1, values: ['2', '3', '1']);

      // Sort and store.
      final key2 = uuid();
      expect(await commands.sortStore(key1, key2), equals(3));

      // Sort with weights.
      await commands.set('${key1}_w1', '3');
      await commands.set('${key1}_w2', '2');
      await commands.set('${key1}_w3', '1');

      expect(await commands.sortStore(key1, key2, by: '${key1}_w*'), equals(3));

      // Sort limiting the results.
      expect(await commands.sortStore(key1, key2, offset: 1, count: 99),
          equals(2));

      // Sort with getters.
      await commands.set('${key1}_g1', 'x');
      await commands.set('${key1}_g2', 'y');
      await commands.set('${key1}_g3', 'z');

      expect(
          await commands.sortStore(key1, key2, get: ['${key1}_g*']), equals(3));
      expect(
          await commands
              .sortStore(key1, key2, get: ['${key1}_g*', '${key1}_unkw_*']),
          equals(6));
      expect(
          await commands.sortStore(key1, key2,
              get: ['#', '${key1}_g*', '${key1}_unkw_*']),
          equals(9));

      // Sort with an explicit order.
      expect(await commands.sortStore(key1, key2, order: SortOrder.ascending),
          equals(3));
      expect(await commands.sortStore(key1, key2, order: SortOrder.descending),
          equals(3));

      // Sort using an alphabetical order.
      final key3 = uuid();
      await commands.rpush(key3, values: ['b', 'c', 'a']);

      expect(await commands.sortStore(key3, key2, alpha: true), equals(3));

      // Try to sort a non existing key.
      final key4 = uuid();
      expect(await commands.sortStore(key4, key2), isZero);
    });

    test('touch', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      await commands.mset(map: {key1: 'abc', key2: 'def', key3: 'ghi'});

      // Touch one key.
      expect(await commands.touch(key: key1), equals(1));

      // Touch some keys.
      expect(await commands.touch(keys: [key2, key3]), equals(2));

      // Try to to touch a non existing key.
      final key4 = uuid();
      expect(await commands.touch(key: key4), equals(0));
    });

    test('ttl', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Try to get from a non existing key or without associated timeout.
      expect(await commands.ttl(key1), equals(-1));

      final key2 = uuid();
      expect(await commands.ttl(key2), equals(-2));

      // Expire and get.
      await commands.expire(key1, 5);
      expect(await commands.ttl(key1), isNonNegative);
    });

    test('type', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      final key4 = uuid();
      final key5 = uuid();

      await commands.set(key1, 'abc');
      await commands.rpush(key2, value: 'abc');
      await commands.sadd(key3, member: 'abc');
      await commands.zadd(key4, score: 1.0, member: 'abc');
      await commands.hset(key5, 'abc', '123');

      // Get.
      expect(await commands.type(key1), equals('string'));
      expect(await commands.type(key2), equals('list'));
      expect(await commands.type(key3), equals('set'));
      expect(await commands.type(key4), equals('zset'));
      expect(await commands.type(key5), equals('hash'));

      // Try to get from non existing key.
      final key6 = uuid();
      expect(await commands.type(key6), equals('none'));
    });

    test('unlink', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();
      await commands.set(key1, 'abc');
      await commands.set(key2, 'def');
      await commands.set(key3, 'ghi');

      // Remove one key.
      expect(await commands.unlink(key: key1), equals(1));

      // Remove some keys.
      expect(await commands.unlink(keys: [key2, key3]), equals(2));

      // Try to remove a non existing key.
      expect(await commands.unlink(key: key1), equals(0));
      expect(await commands.unlink(keys: [key2, key3]), equals(0));
    });

    test('wait', () async {
      // Add some values.
      final key1 = uuid();
      await commands.set(key1, 'abc');

      // Wait.
      expect(await commands.wait(1, 1), greaterThanOrEqualTo(0));
    });

    group('support', () {
      group('SortOrder', () {
        test('toString', () {
          expect(SortOrder.ascending.toString(), startsWith('SortOrder:'));
        });
      });

      group('ObjectSubcommand', () {
        test('toString', () {
          expect(ObjectSubcommand.encoding.toString(),
              startsWith('ObjectSubcommand:'));
        });
      });

      group('KeyScanResult', () {
        test('toString', () {
          const value = KeyScanResult<String>(null, null);
          expect(value.toString(), startsWith('KeyScanResult<String>:'));
        });
      });
    });
  });
}
