// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late HashCommands<String, String> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('HashCommands', () {
    test('hdel', () async {
      // Add some fields.
      final key1 = uuid();
      await commands
          .hmset(key1, hash: {'name': 'Bob', 'age': '29', 'gender': 'male'});

      // Remove one field.
      expect(await commands.hdel(key1, field: 'name'), equals(1));

      // Remove some fields.
      expect(await commands.hdel(key1, fields: ['age', 'gender']), equals(2));

      // Try to remove a non existing field.
      final key2 = uuid();
      expect(await commands.hdel(key1, field: key2), isZero);

      // Try to remove from an empty or non existing hash.
      final key3 = uuid();
      expect(await commands.hdel(key3, field: 'name'), isZero);
    });

    test('hexists', () async {
      // Add some fields.
      final key1 = uuid();
      await commands.hmset(key1, hash: {'name': 'Bob', 'age': '29'});

      // Check if some fields exist.
      expect(await commands.hexists(key1, 'name'), equals(1));
      expect(await commands.hexists(key1, 'age'), equals(1));
      expect(await commands.hexists(key1, 'gender'), equals(0));

      // Try to check in an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hexists(key2, 'name'), isZero);
    });

    test('hget', () async {
      // Add some fields.
      final key1 = uuid();
      await commands.hmset(key1, hash: {'name': 'Bob', 'age': '29'});

      // Get some fields.
      expect(await commands.hget(key1, 'name'), equals('Bob'));
      expect(await commands.hget(key1, 'age'), equals('29'));

      // Try to get a non existing field.
      final key2 = uuid();
      expect(await commands.hget(key1, key2), isNull);

      // Try to get from an empty or non existing hash.
      final key3 = uuid();
      expect(await commands.hget(key3, 'name'), isNull);
    });

    test('hgetall', () async {
      // Add some fields.
      final key1 = uuid();
      await commands.hmset(key1, hash: {'name': 'Bob', 'age': '29'});

      // Get all fields.
      expect(
          await commands.hgetall(key1),
          allOf(hasLength(2), containsPair('name', 'Bob'),
              containsPair('age', '29')));

      // Try to get from an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hgetall(key2), isEmpty);
    });

    test('hincrby', () async {
      // Adds some fields
      final key1 = uuid();
      await commands.hset(key1, 'age', '29');

      // Increment.
      expect(await commands.hincrby(key1, 'age', 5), equals(34));
      expect(await commands.hincrby(key1, 'age', -7), equals(27));
      expect(await commands.hincrby(key1, 'sons', 2), equals(2));

      // Try to increment in an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hincrby(key2, 'age', 38), equals(38));
    });

    test('hincrbyfloat', () async {
      // Add some fields.
      final key1 = uuid();
      await commands.hset(key1, 'height', '1.8');

      // Increment.
      expect(await commands.hincrbyfloat(key1, 'height', 0.5), equals(2.3));
      expect(await commands.hincrbyfloat(key1, 'height', -0.7),
          closeTo(1.6, 0.001));
      expect(await commands.hincrbyfloat(key1, 'width', 79.0), equals(79.0));

      // Try to increment in an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hincrbyfloat(key2, 'height', 1.74), equals(1.74));
    });

    test('hkeys', () async {
      // Add some fields.
      final key1 = uuid();
      await commands
          .hmset(key1, hash: {'name': 'Bob', 'age': '29', 'gender': 'male'});

      // Get all keys.
      expect(await commands.hkeys(key1),
          unorderedEquals(<String>['name', 'age', 'gender']));

      // Try to get all keys of an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hkeys(key2), isEmpty);
    });

    test('hlen', () async {
      // Add some fields.
      final key1 = uuid();
      await commands
          .hmset(key1, hash: {'name': 'Bob', 'age': '29', 'gender': 'male'});

      // Get the length.
      expect(await commands.hlen(key1), equals(3));

      // Try to get the length of an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hlen(key2), isZero);
    });

    test('hmget', () async {
      // Add some fields.
      final key1 = uuid();
      await commands
          .hmset(key1, hash: {'name': 'Bob', 'age': '29', 'gender': 'male'});

      // Get one field.
      expect(await commands.hmget(key1, field: 'name'), equals(['Bob']));

      // Get some fields.
      expect(await commands.hmget(key1, fields: ['age', 'gender']),
          unorderedEquals(<String>['29', 'male']));

      // Try to get a non existing field.
      expect(await commands.hmget(key1, field: 'sons'), equals([null]));

      // Try to get a non existing key.
      expect(() => commands.hmget('notakey'),
          throwsA(const TypeMatcher<RedisException>()));

      // Try to get from an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hmget(key2, field: 'name'), equals([null]));
    });

    test('hmset', () async {
      final key = uuid();

      // Set one value.
      await commands.hmset(key, field: 'name', value: 'Bob');
      expect(await commands.hget(key, 'name'), equals('Bob'));

      // Set some values.
      await commands.hmset(key, hash: {'age': '29', 'gender': 'male'});
      expect(await commands.hmget(key, fields: ['age', 'gender']),
          unorderedEquals(<String>['29', 'male']));
    });

    test('hscan', () async {
      // Add some fields.
      final key1 = uuid();
      await commands
          .hmset(key1, hash: {'name': 'Bob', 'age': '29', 'gender': 'male'});

      // Scan.
      var result = await commands.hscan(key1, 0);
      expect(result!.cursor, equals(0));
      expect(result.fields, hasLength(3));
      expect(
          result.fields,
          allOf(containsPair('name', 'Bob'), containsPair('age', '29'),
              containsPair('gender', 'male')));

      // Scan with a hint.
      result = await commands.hscan(key1, 0, count: 5);
      expect(result!.cursor, isZero);
      expect(result.fields, hasLength(3));

      // Scan with a pattern.
      result = await commands.hscan(key1, 0, pattern: 'a*');
      expect(result!.cursor, isZero);
      expect(result.fields, hasLength(1));

      // Try to scan an empty or non existing hash.
      final key2 = uuid();
      result = await commands.hscan(key2, 0);
      expect(result!.cursor, isZero);
      expect(result.fields, isEmpty);
    });

    test('hset', () async {
      final key = uuid();

      // Set.
      expect(await commands.hset(key, 'name', 'Bob'), equals(1));

      // Update.
      expect(await commands.hset(key, 'name', 'Joe'), isZero);
    });

    test('hsetnx', () async {
      final key = uuid();

      // Set.
      expect(await commands.hsetnx(key, 'name', 'Bob'), equals(1));

      // Update.
      expect(await commands.hsetnx(key, 'name', 'Joe'), equals(0));
    });

    test('hstrlen', () async {
      // Add some fields.
      final key1 = uuid();
      await commands.hmset(key1, hash: {'name': 'Bob', 'age': '29'});

      // Get the length of a field.
      expect(await commands.hstrlen(key1, 'name'), equals(3));
      expect(await commands.hstrlen(key1, 'age'), equals(2));

      // Try to get the length of a non existing field.
      final key2 = uuid();
      expect(await commands.hstrlen(key1, key2), isZero);

      // Try to get the length of an empty or non existing hash.
      final key3 = uuid();
      expect(await commands.hstrlen(key3, 'name'), isZero);
    });

    test('hvals', () async {
      // Add some fields.
      final key1 = uuid();
      await commands
          .hmset(key1, hash: {'name': 'Bob', 'age': '29', 'gender': 'male'});

      // Get all values.
      expect(await commands.hvals(key1),
          unorderedEquals(<String>['Bob', '29', 'male']));

      // Try to get all values of an empty or non existing hash.
      final key2 = uuid();
      expect(await commands.hvals(key2), isEmpty);
    });

    group('support', () {
      group('HashScanResult', () {
        test('toString', () {
          const value = HashScanResult<String, String>(0, {});
          expect(
              value.toString(), startsWith('HashScanResult<String, String>:'));
        });
      });
    });
  });
}
