// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Completer;

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

void main() {
  group('Terminal', () {
    test('test connectivity with a PING command', () async {
      final terminal = await Terminal.connect('redis://localhost:6379');

      final completer = Completer<void>();

      // Handler.
      void onData(List<int> data) async {
        // PONG
        expect(data, equals([RespToken.string, 80, 79, 78, 71, 13, 10]));

        // Disconnect and complete the test.
        await terminal.disconnect();
        completer.complete();
      }

      // Set the handler and send some raw data.
      terminal.stream.listen(onData);

      terminal.run(<int>[80, 73, 78, 71, 13, 10]); // PING

      await completer.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw StateError('Timeout'));
    });
  });
}
