// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

class _DummyRunner implements CommandRunner {
  @override
  Future<T> run<T>(Command<T> command) => command.future;
}

class _DummyModule extends ModuleBase {
  _DummyModule() : super(_DummyRunner());
}

class _TypedCommands<K> extends ModuleBase {
  _TypedCommands(Client client) : super(client);

  Future<void> set<R>(K key, R value) => run([r'SET', key, value]);

  Future<R?> get<R extends Object>(K key) => run<R>([r'GET', key]);
}

void main() {
  group('ModuleBase', () {
    test('run', () {
      final module = _DummyModule();
      expect(module.run<void>(<Object>['TEST']), isNotNull);
    });

    test('execute', () {
      final module = _DummyModule();
      final command = Command<String>(<Object>['TEST']);
      expect(module.execute(command), equals(command.future));
    });

    test('typed commands', () async {
      final client = await Client.connect('redis://localhost:6379');
      final commands = _TypedCommands<String>(client);

      final key1 = uuid();
      final key2 = uuid();
      final key3 = uuid();

      await commands.set<String>(key1, 'abc');
      await commands.set<int>(key2, 123);
      await commands.set<List<int>>(key3, [1, 2, 3]);

      expect(await commands.get<String>(key1), equals('abc'));
      expect(await commands.get<int>(key2), equals(123));
      expect(await commands.get<List<int>>(key3), equals([1, 2, 3]));

      await client.disconnect();
    });
  });
}
