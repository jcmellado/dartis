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

  group('ConnectionCommands', () {
    test('auth', () async {
      await commands.auth('foobared');
    }, skip: 'Requires a password-protected Redis server.');

    test('echo', () async {
      expect(await commands.echo('test'), equals('test'));
    });

    test('ping', () async {
      expect(await commands.ping(), equals('PONG'));
      expect(await commands.ping('test'), equals('test'));
    });

    test('quit', () async {
      await commands.quit();
    });

    test('select', () async {
      final key = uuid();

      // Set value in database 0.
      await commands.select(0);
      await commands.set(key, 'test');

      // Select database 1 and check that the value does not exists now.
      await commands.select(1);
      expect(await commands.exists(key: key), equals(0));

      // Select database 0 and check that the value exists again.
      await commands.select(0);
      expect(await commands.exists(key: key), equals(1));
    });

    test('swapdb', () async {
      final key = uuid();

      // Set value in database 0
      await commands.select(0);
      await commands.set(key, 'test');

      // Swap and check that the value now does not exists in database 0.
      await commands.swapdb(0, 1);
      expect(await commands.exists(key: key), equals(0));

      // Swap and check that the value exists again in database 0.
      await commands.swapdb(0, 1);
      expect(await commands.exists(key: key), equals(1));
    }, skip: 'Swaps the current database.');
  });
}
