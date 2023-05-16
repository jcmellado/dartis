// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

class _Mapper implements Mapper<List<Reply>> {
  @override
  List<Reply> map(covariant ArrayReply reply, RedisCodec codec) => reply.array;
}

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

  group('ScriptingCommands', () {
    test('eval', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      await commands.mset(map: {key1: 'a', key2: 'b'});

      // Evaluate.
      await commands.eval<void>('return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}',
          keys: [key1, key2], args: ['first', 'second']);

      // Evaluate with a mapper.
      final results = await commands.eval<List<Reply>>(
          'return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}',
          keys: [key1, key2],
          args: ['first', 'second'],
          mapper: _Mapper());

      expect(results[0].value, equals(key1.codeUnits));
      expect(results[1].value, equals(key2.codeUnits));
      expect(results[2].value, equals('first'.codeUnits));
      expect(results[3].value, equals('second'.codeUnits));
    });

    test('evalsha', () async {
      // Add some values.
      final key1 = uuid();
      final key2 = uuid();
      await commands.mset(map: {key1: 'a', key2: 'b'});

      // Flush and evaluate.
      await commands.scriptFlush();

      final sha1 =
          await commands.scriptLoad('return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}');

      await commands
          .evalsha<void>(sha1, keys: [key1, key2], args: ['first', 'second']);

      // Evaluate with a mapper.
      final results = await commands.evalsha<List<Reply>>(sha1,
          keys: [key1, key2], args: ['first', 'second'], mapper: _Mapper());

      expect(results[0].value, equals(key1.codeUnits));
      expect(results[1].value, equals(key2.codeUnits));
      expect(results[2].value, equals('first'.codeUnits));
      expect(results[3].value, equals('second'.codeUnits));
    });

    test('scriptDebug', () async {
      await commands.scriptDebug(ScriptDebugMode.yes);
      await commands.scriptDebug(ScriptDebugMode.sync);
      await commands.scriptDebug(ScriptDebugMode.no);
    });

    test('scriptExists', () async {
      // Flush, load and check.
      await commands.scriptFlush();

      final sha1 =
          await commands.scriptLoad('return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}');
      final sha2 =
          await commands.scriptLoad('return redis.call("set",KEYS[1],"bar")');

      expect(await commands.scriptExists(sha1: sha1), equals([1]));
      expect(await commands.scriptExists(sha1s: [sha1, sha2]), equals([1, 1]));

      // Flush and try to check not existing scripts.
      await commands.scriptFlush();

      expect(await commands.scriptExists(sha1: sha1), equals([0]));
      expect(await commands.scriptExists(sha1s: [sha1, sha2]), equals([0, 0]));
    });

    test('scriptFlush', () async {
      await commands.scriptFlush();
    });

    test('scriptKill', () async {
      await commands.scriptKill();
    }, skip: 'Kills the current Lua script running in the server.');

    test('scriptLoad', () async {
      await commands.scriptFlush();

      final sha1 =
          await commands.scriptLoad('return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}');

      expect(await commands.scriptExists(sha1: sha1), equals([1]));
    });

    group('support', () {
      group('ScriptDebugMode', () {
        test('toString', () {
          expect(ScriptDebugMode.no.toString(), startsWith('ScriptDebugMode:'));
        });
      });
    });
  });
}
