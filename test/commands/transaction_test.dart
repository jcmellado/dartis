// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late Commands<String, String> commands;

  /// A convenient matcher.
  final throwRedisException = throwsA(const TypeMatcher<RedisException>());

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('TransactionCommands', () {
    test('an empty transaction', () async {
      await commands.multi();
      await commands.exec();
    });

    test('a transaction with some commands', () async {
      await commands.multi();

      expect(commands.ping(), completion(equals('PONG')));
      expect(commands.ping(), completion(equals('PONG')));

      await commands.exec();
    });

    test('a secuence of transactions', () async {
      final key = uuid();

      await commands.multi();
      expect(commands.set(key, 'abc'), completes);
      await commands.exec();

      await commands.multi();
      expect(commands.get(key), completion(equals('abc')));
      await commands.exec();
    });

    test('a transaction with one failing command', () async {
      // Set the value of a key.
      final key = uuid();
      await commands.set(key, 'abc');

      await commands.multi();

      expect(commands.ping(), completion(equals('PONG')));
      // Try to get the value of the key as it were a list.
      expect(commands.lpop(key), throwRedisException);
      expect(commands.ping(), completion(equals('PONG')));

      await commands.exec();
    });

    test('a transaction aborted', () async {
      await commands.multi();

      expect(commands.ping(), throwRedisException);
      // Try to echo a null value.
      expect(commands.echo(null), throwRedisException);
      expect(commands.ping(), throwRedisException);

      expect(commands.exec(), throwRedisException);
    });

    test('a transaction discarded', () async {
      await commands.multi();

      expect(commands.ping(), throwRedisException);
      expect(commands.ping(), throwRedisException);

      await commands.discard();
    });

    test('a transaction aborted by some watched keys', () async {
      final key = uuid();
      await commands.set(key, 'a');

      // Watch a key and start a new transaction.
      await commands.watch(key: key);
      await commands.multi();

      // Modify the watched key in other connection.
      final client2 = await Client.connect('redis://localhost:6379');
      final commands2 = client2.asCommands<String, String>();
      await commands2.set(key, 'b');
      await client2.disconnect();

      // Try to get the modified key.
      expect(commands.get(key), throwRedisException);
      await commands.exec();
    });

    test('a transaction with some watched and then unwatched keys', () async {
      final key = uuid();
      await commands.set(key, 'a');

      // Watch the key.
      await commands.watch(key: key);

      // Modify the watched key in other connection.
      final client2 = await Client.connect('redis://localhost:6379');
      final commands2 = client2.asCommands<String, String>();
      await commands2.set(key, 'b');
      await client2.disconnect();

      // Unwatch the key and try to get the modified value.
      expect(commands.unwatch(), completes);
      await commands.multi();
      expect(commands.get(key), completion(equals('b')));
      await commands.exec();
    });

    test('a transaction with server reply off', () async {
      await commands.clientReply(ReplyMode.off);

      await commands.multi();
      expect(commands.ping(), completion(isNull));
      expect(commands.ping(), completion(isNull));
      await commands.exec();
    });

    test('calling multiple times to MULTI', () async {
      await commands.multi();
      expect(commands.multi(), throwRedisException);
    });

    test('calling EXEC before than MULTI', () async {
      expect(commands.exec(), throwRedisException);
    });

    test('calling DISCARD before than MULTI', () async {
      expect(commands.discard(), throwRedisException);
    });
  });
}
