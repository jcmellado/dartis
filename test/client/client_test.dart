// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:io' show InternetAddress, SocketException;

import 'package:dartis/dartis.dart';
import 'package:test/test.dart';

import '../fakesocket.dart';
import '../util.dart' show uuid;

void main() {
  group('Client', () {
    test('connect and disconnect', () async {
      final Client client = await Client.connect('redis://localhost:6379');

      await client.disconnect();
    });

    test('codec', () async {
      final Client client = await Client.connect('redis://localhost:6379');

      expect(client.codec.encode<List<int>>('abc'), equals([97, 98, 99]));
      expect(client.codec.decode<String>(const StringReply([97, 98, 99])),
          equals('abc'));

      await client.disconnect();
    });

    test('asCommands', () async {
      final Client client = await Client.connect('redis://localhost:6379');

      final Commands<String, String> texts = 
        client.asCommands<String, String>();
      final Commands<String, List<int>> bytes = 
        client.asCommands<String, List<int>>();
      final Commands<List<int>, List<int>> raw = 
        client.asCommands<List<int>, List<int>>();

      // Set some values and get them.
      final String key = uuid();
      await texts.set(key, 'abc');

      expect(await texts.get(key), equals('abc'));
      expect(await bytes.get(key), equals('abc'.codeUnits));
      expect(await raw.get(key.codeUnits), equals('abc'.codeUnits));

      await client.disconnect();
    });

    test('run', () async {
      final Client client = await Client.connect('redis://localhost:6379');

      final Command<String> command = Command<String>(<Object>['PING']);
      expect(await client.run<String>(command), equals('PONG'));

      await client.disconnect();
    });

    test('pipeline', () async {
      final Client client = await Client.connect('redis://localhost:6379')
        ..pipeline();

      // Run some commands.
      // ignore: unawaited_futures
      client.asCommands<String, String>()..ping()..ping()..ping();

      // Flush.
      final List<Future<Object?>> futures = client.flush();

      expect(
        await Future.wait<Object?>(futures), 
          equals(['PONG', 'PONG', 'PONG']));

      await client.disconnect();
    });

    test('fire and forget', () async {
      final Client client = await Client.connect('redis://localhost:6379');
      final Commands<String, String> commands = 
        client.asCommands<String, String>();

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
      final InternetAddress address = InternetAddress('127.0.0.1');
      final InternetAddress remoteAddress = InternetAddress('127.0.0.1');
      // ignore: close_sinks
      final FakeSocket socket = FakeSocket([
        [RespToken.string, 80, 79, 78, 71, 13, 10] // PONG        
      ], const SocketException('bad fake connnection'),
        address: address,
        remoteAddress: remoteAddress
      );
      final Connection connection = Connection(socket);
      final Client client = Client(connection);

      // Check that ping works.
      final Command<String> ping1 = Command<String>(<Object>['PING']);
      expect(await client.run<String>(ping1), equals('PONG'));

      // We now expect an exception from the connection.
      expect(connection.done, throwsA(isException));

      // Check that ping again will cause an exception.
      final Command<String> ping2 = Command<String>(<Object>['PING']);
      expect(client.run<String>(ping2), throwsA(isException));
    });
  });
}
