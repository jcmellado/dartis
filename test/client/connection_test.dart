// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Completer;
import 'dart:io' show SocketException;

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../fakesocket.dart';

void main() {
  group('Connection', () {
    test('test connectivity with a PING command', () async {
      final connection = await Connection.connect('redis://localhost:6379');

      final completer = Completer<void>();

      // Handler.
      void onData(List<int> data) async {
        // PONG
        expect(data, equals([RespToken.string, 80, 79, 78, 71, 13, 10]));

        // Disconnect and complete the test.
        await connection.disconnect();
        completer.complete();
      }

      // Set the handler and send some raw data.
      connection
        ..listen(onData, null, null)
        ..send([
          RespToken.array, 49, 13, 10, // *1
          RespToken.bulk, 52, 13, 10, 80, 73, 78, 71, 13, 10 // $4 PING
        ]);

      await completer.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw StateError('Timeout'));
    });

    test('test connection done', () async {
      final connection = await Connection.connect('redis://localhost:6379');
      final completer = Completer<void>();

      connection.done.then(completer.complete); // ignore: unawaited_futures
      connection.disconnect(); // ignore: unawaited_futures

      await completer.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw StateError('Timeout'));
    });

    test('attempt to send data after connection was closed', () async {
      final connection = await Connection.connect('redis://localhost:6379');
      final completer = Completer<void>();

      connection.done.then(completer.complete); // ignore: unawaited_futures
      connection.disconnect(); // ignore: unawaited_futures

      await completer.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw StateError('Timeout'));

      expect(
          () => connection.send([
                RespToken.array, 49, 13, 10, // *1
                RespToken.bulk, 52, 13, 10, 80, 73, 78, 71, 13, 10 // $4 PING
              ]),
          throwsA(const TypeMatcher<RedisConnectionClosedException>()));
    });

    test('ping/pong using FakeSocket', () async {
      // ignore: close_sinks
      final socket = FakeSocket([
        [RespToken.string, 80, 79, 78, 71, 13, 10]
      ], null);
      final connection = Connection(socket);

      final onData = Completer<List<int>>();
      // Sends a PING.
      connection
        ..listen(onData.complete, null, null)
        ..send([
          RespToken.array, 49, 13, 10, // *1
          RespToken.bulk, 52, 13, 10, 80, 73, 78, 71, 13, 10 // $4 PING
        ]);

      // Waits for data.
      final data = await onData.future;
      expect(data, equals([RespToken.string, 80, 79, 78, 71, 13, 10])); // PONG

      await connection.disconnect();
    });

    test('broken connection using FakeSocket', () async {
      // ignore: close_sinks
      final socket = FakeSocket([
        [RespToken.string, 80, 79, 78, 71, 13, 10]
      ], const SocketException('bad fake connnection'));
      final connection = Connection(socket);

      final onData = Completer<List<int>>();
      final onError = Completer<Object>();

      // Sends a PING.
      connection
        ..listen(onData.complete, (e, [st]) => onError.complete(e), null)
        ..send([
          RespToken.array, 49, 13, 10, // *1
          RespToken.bulk, 52, 13, 10, 80, 73, 78, 71, 13, 10 // $4 PING
        ]);

      // Waits for data.
      final data = await onData.future;
      expect(data, equals([RespToken.string, 80, 79, 78, 71, 13, 10])); // PONG

      // We now expect an exception from the connection.
      expect(connection.done, throwsA(isException));

      // Try to send something to get an error.
      connection.send([
        RespToken.array, 49, 13, 10, // *1
        RespToken.bulk, 52, 13, 10, 80, 73, 78, 71, 13, 10 // $4 PING
      ]);

      // Ensure that onError happens.
      expect(await onError.future, const TypeMatcher<SocketException>());
    });
  });

  group('RedisUri', () {
    group('parse', () {
      test('some connection strings', () {
        expect(() => RedisUri.parse(''), throwsFormatException);
        expect(() => RedisUri.parse('test'), throwsFormatException);
        expect(() => RedisUri.parse('redis://'), throwsFormatException);
        expect(() => RedisUri.parse('redis://host'), throwsFormatException);
        expect(() => RedisUri.parse('redis://host:'), throwsFormatException);
        expect(() => RedisUri.parse('redis://host:abc'), throwsFormatException);
        expect(() => RedisUri.parse('redis://:123'), throwsFormatException);
        expect(() => RedisUri.parse('host:123'), throwsFormatException);

        final uri = RedisUri.parse('redis://localhost:6379');
        expect(uri.host, equals('localhost'));
        expect(uri.port, equals(6379));
      });
    });
  });
}
