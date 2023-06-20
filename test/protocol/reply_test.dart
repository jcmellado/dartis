// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

void main() {
  group('Reply', () {
    group('NullReply', () {
      test('value', () {
        expect(nullReply.value, isNull);
      });

      test('toString', () {
        expect(nullReply.toString(), startsWith('NullReply:'));
      });
    });

    group('StringReply', () {
      test('value', () {
        const reply = StringReply([65, 66, 67]);

        expect(reply.value, equals([65, 66, 67]));
        expect(reply.bytes, equals([65, 66, 67]));
      });

      test('toString', () {
        const reply = StringReply([]);

        expect(reply.toString(), startsWith('StringReply:'));
      });
    });

    group('IntReply', () {
      test('value', () {
        const reply = IntReply([49, 50, 51]);

        expect(reply.value, equals([49, 50, 51]));
        expect(reply.bytes, equals([49, 50, 51]));
      });

      test('toString', () {
        const reply = IntReply([48]);

        expect(reply.toString(), startsWith('IntReply:'));
      });
    });

    group('BulkReply', () {
      test('value', () {
        const reply = BulkReply([1, 2, 3]);

        expect(reply.value, equals([1, 2, 3]));
        expect(reply.bytes, equals([1, 2, 3]));
      });

      test('toString', () {
        const reply = BulkReply([]);

        expect(reply.toString(), startsWith('BulkReply:'));
      });
    });

    group('ArrayReply', () {
      test('value', () {
        const one = StringReply([65, 66, 67]);
        const two = IntReply([49, 50, 51]);
        const three = BulkReply([1, 2, 3]);
        const reply = ArrayReply(<Reply>[one, two, three]);

        final replies = reply.array;
        expect(
            replies.map((reply) => reply.value).toList(),
            equals([
              [65, 66, 67],
              [49, 50, 51],
              [1, 2, 3]
            ]));
        expect(
            reply.array.map((reply) => reply.value).toList(),
            equals([
              [65, 66, 67],
              [49, 50, 51],
              [1, 2, 3]
            ]));
      });

      test('toString', () {
        const reply = ArrayReply([]);

        expect(reply.toString(), startsWith('ArrayReply:'));
      });
    });

    group('ErrorReply', () {
      test('value', () {
        const reply = ErrorReply([69, 82, 82]);

        expect(reply.value, equals([69, 82, 82]));
        expect(reply.bytes, equals([69, 82, 82]));
      });

      test('toString', () {
        const reply = ErrorReply([]);

        expect(reply.toString(), startsWith('ErrorReply:'));
      });
    });
  });
}
