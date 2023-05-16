// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:io' show SocketException;

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../fakesocket.dart';
import '../util.dart' show uuid;

void main() {
  group('Client', () {
    test('connect and disconnect', () async {
      final client = await Client.connect('redis://localhost:6379');

      await client.disconnect();
    });

    test('codec', () async {
      final client = await Client.connect('redis://localhost:6379');

      expect(client.codec.encode<List<int>>('abc'), equals([97, 98, 99]));
      expect(client.codec.decode<String>(const StringReply([97, 98, 99])),
          equals('abc'));

      await client.disconnect();
    });

    test('asCommands', () async {
      final client = await Client.connect('redis://localhost:6379');

      final texts = client.asCommands<String, String>();
      final bytes = client.asCommands<String, List<int>>();
      final raw = client.asCommands<List<int>, List<int>>();

      // Set some values and get them.
      final key = uuid();
      await texts.set(key, 'abc');

      expect(await texts.get(key), equals('abc'));
      expect(await bytes.get(key), equals('abc'.codeUnits));
      expect(await raw.get(key.codeUnits), equals('abc'.codeUnits));

      await client.disconnect();
    });

    test('run', () async {
      final client = await Client.connect('redis://localhost:6379');

      final command = Command<String>(<Object>['PING']);
      expect(await client.run<String>(command), equals('PONG'));

      await client.disconnect();
    });

    test('pipeline', () async {
      final client = await Client.connect('redis://localhost:6379')
        ..pipeline();

      // Run some commands.
      client.asCommands<String, String>()
        // ignore: unawaited_futures
        ..ping()
        // ignore: unawaited_futures
        ..ping()
        // ignore: unawaited_futures
        ..ping();

      // Flush.
      final futures = client.flush();

      expect(await Future.wait(futures), equals(['PONG', 'PONG', 'PONG']));

      await client.disconnect();
    });

    test('fire and forget', () async {
      final client = await Client.connect('redis://localhost:6379');
      final commands = client.asCommands<String, String>();

      // Skip.
      await commands.clientReply(ReplyMode.skip);

      expect(await commands.ping(), isNull);
      expect(await commands.ping(), equals('PONG'));

      // Off.
      await commands.clientReply(ReplyMode.off);

      expect(await commands.ping(), isNull);
      expect(await commands.ping(), isNull);
      expect(await commands.ping(), isNull);

      // On.
      await commands.clientReply(ReplyMode.on);

      expect(await commands.ping(), equals('PONG'));

      await client.disconnect();
    });

    test('throws on broken connection', () async {
      // ignore: close_sinks
      final socket = FakeSocket([
        [RespToken.string, 80, 79, 78, 71, 13, 10] // PONG
      ], const SocketException('bad fake connnection'));
      final connection = Connection(socket);
      final client = Client(connection);

      // Check that ping works.
      final ping1 = Command<String>(<Object>['PING']);
      expect(await client.run<String>(ping1), equals('PONG'));

      // We now expect an exception from the connection.
      expect(connection.done, throwsA(isException));

      // Check that ping again will cause an exception.
      final ping2 = Command<String>(<Object>['PING']);
      expect(client.run<String>(ping2), throwsA(isException));
    });
  });
}
