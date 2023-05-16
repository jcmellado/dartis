// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Completer;

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

void main() {
  group('Monitor', () {
    test('test connectivity with a MONITOR command', () async {
      final monitor = await Monitor.connect('redis://localhost:6379');

      final completer = Completer<void>();

      // Handler.
      void onData(List<int> data) async {
        // OK
        expect(data, equals([RespToken.string, 79, 75, 13, 10]));

        // Disconnect and complete the test.
        await monitor.disconnect();
        completer.complete();
      }

      // Set the handler and start the monitor mode.
      monitor.stream.listen(onData);

      monitor.start();

      await completer.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw StateError('Timeout'));
    });
  });
}
