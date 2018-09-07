// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:dartis/dartis.dart';

void main() {
  group('Reply', () {
    group('NullReply', () {
      test('value', () {
        expect(nullReply.value, isNull);
      });
    });

    group('StringReply', () {
      test('value', () {
        const reply = StringReply([65, 66, 67]);

        expect(reply.value, equals([65, 66, 67]));
        expect(reply.bytes, equals([65, 66, 67]));
      });
    });

    group('IntReply', () {
      test('value', () {
        const reply = StringReply([49, 50, 51]);

        expect(reply.value, equals([49, 50, 51]));
        expect(reply.bytes, equals([49, 50, 51]));
      });
    });

    group('BulkReply', () {
      test('value', () {
        const reply = BulkReply([1, 2, 3]);

        expect(reply.value, equals([1, 2, 3]));
        expect(reply.bytes, equals([1, 2, 3]));
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
    });

    group('ErrorReply', () {
      test('value', () {
        const reply = ErrorReply([69, 82, 82]);

        expect(reply.value, equals([69, 82, 82]));
        expect(reply.bytes, equals([69, 82, 82]));
      });
    });
  });
}
