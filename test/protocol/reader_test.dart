// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

void main() {
  // ignore: no_leading_underscores_for_local_identifiers
  Uint8List _chunk(List<int> bytes) => Uint8List.fromList(bytes);

  group('Reader', () {
    group('read until CR LF', () {
      void checkLine(Reader reader) {
        expect(reader.done, isTrue);

        final reply = reader.consume();
        expect(reply, const TypeMatcher<StringReply>());
        expect(reply.value, [1, 2, 3]);
      }

      test('from an empty chunk', () {
        final reader = Reader(RespToken.string);

        expect(reader.done, isFalse);
        expect(reader.read(_chunk(<int>[]), 0), equals(0));
        expect(reader.done, isFalse);
      });

      test('from one chunk [..., 13, 10]', () {
        final reader = Reader(RespToken.string);

        expect(reader.done, isFalse);
        final end = reader.read(_chunk([1, 2, 3, 13, 10]), 0);
        expect(end, equals(5));

        checkLine(reader);
      });

      test('from one chunk [..., 13, 10, ...] with extra data', () {
        final reader = Reader(RespToken.string);

        expect(reader.done, isFalse);
        final end = reader.read(_chunk([0, 0, 1, 2, 3, 13, 10, 0, 0]), 2);
        expect(end, equals(7));

        checkLine(reader);
      });

      test('from two chunks [...] [..., 13, 10]', () {
        final reader = Reader(RespToken.string);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([1, 2]), 0);
        expect(end, equals(2));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([3, 13, 10]), 0);
        expect(end, equals(3));

        checkLine(reader);
      });

      test('from two chunks [...] [13, 10]', () {
        final reader = Reader(RespToken.string);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([1, 2, 3]), 0);
        expect(end, equals(3));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([13, 10]), 0);
        expect(end, equals(2));

        checkLine(reader);
      });

      test('from two chunks [..., 13] [10]', () {
        final reader = Reader(RespToken.string);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([1, 2, 3, 13]), 0);
        expect(end, equals(4));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([10]), 0);
        expect(end, equals(1));

        checkLine(reader);
      });
    });

    group('read length and payload', () {
      void checkBulk(Reader reader) {
        expect(reader.done, isTrue);

        final reply = reader.consume();
        expect(reply, const TypeMatcher<BulkReply>());
        expect(reply.value, [1, 2, 3]);
      }

      test('from an empty chunk', () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        expect(reader.read(_chunk(<int>[]), 0), equals(0));
        expect(reader.done, isFalse);
      });

      test('from one chunk [..., 13, 10, ..., 13, 10]', () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        final end = reader.read(_chunk([51, 13, 10, 1, 2, 3, 13, 10]), 0);
        expect(end, equals(8));

        checkBulk(reader);
      });

      test('from one chunk [..., 13, 10, ..., 13, 10, ...] with extra data',
          () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        final end =
            reader.read(_chunk([0, 0, 51, 13, 10, 1, 2, 3, 13, 10, 0, 0]), 2);
        expect(end, equals(10));

        checkBulk(reader);
      });

      test('from two chunks [..., 13, 10] [..., 13, 10]', () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([51, 13, 10]), 0);
        expect(end, equals(3));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([1, 2, 3, 13, 10]), 0);
        expect(end, equals(5));

        checkBulk(reader);
      });

      test('from two chunks [..., 13, 10, ...] [13, 10]', () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([51, 13, 10, 1, 2, 3]), 0);
        expect(end, equals(6));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([13, 10]), 0);
        expect(end, equals(2));

        checkBulk(reader);
      });

      test('from two chunks [..., 13, 10, ...] [13, 10, ...] with extra data',
          () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([0, 0, 51, 13, 10, 1, 2, 3]), 2);
        expect(end, equals(8));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([13, 10, 0, 0]), 0);
        expect(end, equals(2));

        checkBulk(reader);
      });

      test('from two chunks [..., 13, 10, ..., 13] [10]', () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([51, 13, 10, 1, 2, 3, 13]), 0);
        expect(end, equals(7));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([10]), 0);
        expect(end, equals(1));

        checkBulk(reader);
      });

      test('from two chunks [..., 13, 10, ..., 13] [10, ...] with extra data',
          () {
        final reader = Reader(RespToken.bulk);

        expect(reader.done, isFalse);
        var end = reader.read(_chunk([0, 0, 51, 13, 10, 1, 2, 3, 13]), 2);
        expect(end, equals(9));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([10, 0, 0]), 0);
        expect(end, equals(1));

        checkBulk(reader);
      });
    });

    group('read length and array', () {
      void checkArray(Reader reader) {
        expect(reader.done, isTrue);

        final reply = reader.consume();
        expect(reply, const TypeMatcher<ArrayReply>());

        final array = (reply as ArrayReply).array;
        expect(array[0].value, [65]);
        expect(array[1].value, [49]);
      }

      test('from an empty chunk', () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        expect(reader.read(_chunk(<int>[]), 0), equals(0));
        expect(reader.done, isFalse);
      });

      test('from one chunk [..., 13, 10, ..., 13, 10]', () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        final end = reader.read(
            _chunk([
              50, 13, 10, // 2
              RespToken.string, 65, 13, 10, // A
              RespToken.integer, 49, 13, 10 // 1
            ]),
            0);
        expect(end, equals(11));

        checkArray(reader);
      });

      test('from one chunk [..., 13, 10, ..., 13, 10, ...] with extra data',
          () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        final end = reader.read(
            _chunk([
              0, 0, // extra
              50, 13, 10, // 2
              RespToken.string, 65, 13, 10, // A
              RespToken.integer, 49, 13, 10, // 1
              0, 0 // extra
            ]),
            2);
        expect(end, equals(13));

        checkArray(reader);
      });

      test('from two chunks [..., 13, 10] [..., 13, 10]', () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        var end = reader.read(
            _chunk([
              50, 13, 10, // 2
              RespToken.string, 65, 13, 10 // A
            ]),
            0);
        expect(end, equals(7));
        expect(reader.done, isFalse);

        end = reader.read(
            _chunk([
              RespToken.integer, 49, 13, 10 // 1
            ]),
            0);
        expect(end, equals(4));

        checkArray(reader);
      });

      test('from two chunks [..., 13, 10, ...] [13, 10]', () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        var end = reader.read(
            _chunk([
              50, 13, 10, // 2
              RespToken.string, 65, 13, 10, // A
              RespToken.integer, 49 // 1
            ]),
            0);
        expect(end, equals(9));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([13, 10]), 0);
        expect(end, equals(2));

        checkArray(reader);
      });

      test('from two chunks [..., 13, 10, ...] [13, 10, ...] with extra data',
          () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        var end = reader.read(
            _chunk([
              0, 0, // extra
              50, 13, 10, // 2
              RespToken.string, 65, 13, 10, // A
              RespToken.integer, 49 // 1
            ]),
            2);
        expect(end, equals(11));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([13, 10, 0, 0]), 0);
        expect(end, equals(2));

        checkArray(reader);
      });

      test('from two chunks [..., 13, 10, ..., 13] [10]', () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        var end = reader.read(
            _chunk([
              50, 13, 10, // 2
              RespToken.string, 65, 13, 10, // A
              RespToken.integer, 49, 13 // 1
            ]),
            0);
        expect(end, equals(10));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([10]), 0);
        expect(end, equals(1));

        checkArray(reader);
      });

      test('from two chunks [..., 13, 10, ..., 13] [10, ...] with extra data',
          () {
        final reader = Reader(RespToken.array);

        expect(reader.done, isFalse);
        var end = reader.read(
            _chunk([
              0, 0, // extra
              50, 13, 10, // 2
              RespToken.string, 65, 13, 10, // A
              RespToken.integer, 49, 13 // 1
            ]),
            2);
        expect(end, equals(12));
        expect(reader.done, isFalse);

        end = reader.read(_chunk([10, 0, 0]), 0);
        expect(end, equals(1));

        checkArray(reader);
      });
    });

    group('read RESP reply', () {
      test('unknow type', () {
        expect(() => Reader(0), throwsA(const TypeMatcher<RedisException>()));
      });

      test('simple string', () {
        final reader = Reader(RespToken.string);
        expect(reader.read(_chunk([65, 66, 67, 13, 10]), 0), equals(5));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<StringReply>());
        expect(reply.value, [65, 66, 67]);
      });

      test('integer', () {
        final reader = Reader(RespToken.integer);
        expect(reader.read(_chunk([49, 50, 51, 13, 10]), 0), equals(5));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<IntReply>());
        expect(reply.value, [49, 50, 51]);
      });

      test('null bulk', () {
        final reader = Reader(RespToken.bulk);
        expect(reader.read(_chunk([45, 49, 13, 10]), 0), equals(4));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<NullReply>());
        expect(reply.value, null);
      });

      test('empty bulk', () {
        final reader = Reader(RespToken.bulk);
        expect(reader.read(_chunk([48, 13, 10, 13, 10]), 0), equals(5));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<BulkReply>());
        expect(reply.value, isEmpty);
      });

      test('bulk', () {
        final reader = Reader(RespToken.bulk);
        expect(
            reader.read(_chunk([51, 13, 10, 1, 2, 3, 13, 10]), 0), equals(8));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<BulkReply>());
        expect(reply.value, [1, 2, 3]);
      });

      test('null array', () {
        final reader = Reader(RespToken.array);
        expect(reader.read(_chunk([45, 49, 13, 10]), 0), equals(4));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<NullReply>());
      });

      test('empty array', () {
        final reader = Reader(RespToken.array);
        expect(reader.read(_chunk([48, 13, 10]), 0), equals(3));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<ArrayReply>());
        expect((reply as ArrayReply).array, isEmpty);
      });

      test('array', () {
        final reader = Reader(RespToken.array);
        expect(
            reader.read(
                _chunk([
                  51, 13, 10, // 3
                  RespToken.string, 65, 13, 10, // A
                  RespToken.integer, 49, 13, 10, // 1
                  RespToken.bulk, 49, 13, 10, 0, 13, 10 // [0]
                ]),
                0),
            equals(18));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<ArrayReply>());

        final array = (reply as ArrayReply).array;
        expect(array, hasLength(3));

        expect(array[0], const TypeMatcher<StringReply>());
        expect(array[0].value, equals([65]));

        expect(array[1], const TypeMatcher<IntReply>());
        expect(array[1].value, equals([49]));

        expect(array[2], const TypeMatcher<BulkReply>());
        expect(array[2].value, equals([0]));
      });

      test('nested array', () {
        final reader = Reader(RespToken.array);
        expect(
            reader.read(
                _chunk([
                  51, 13, 10, // 3
                  RespToken.string, 65, 13, 10, // A
                  RespToken.array, 50, 13, 10, // 2
                  RespToken.string, 66, 13, 10, // B
                  RespToken.integer, 54, 13, 10, // 6
                  RespToken.integer, 55, 13, 10, // 7
                ]),
                0),
            equals(23));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<ArrayReply>());

        final array = (reply as ArrayReply).array;
        expect(array, hasLength(3));

        expect(array[0], const TypeMatcher<StringReply>());
        expect(array[0].value, equals([65]));

        expect(array[1], const TypeMatcher<ArrayReply>());
        final nested = (array[1] as ArrayReply).array;
        expect(nested, hasLength(2));
        expect(nested[0], const TypeMatcher<StringReply>());
        expect(nested[1], const TypeMatcher<IntReply>());
        expect(nested[0].value, equals([66]));
        expect(nested[1].value, equals([54]));

        expect(array[2], const TypeMatcher<IntReply>());
        expect(array[2].value, equals([55]));
      });

      test('error', () {
        final reader = Reader(RespToken.error);
        expect(reader.read(_chunk([69, 82, 82, 13, 10]), 0), equals(5));

        final reply = reader.consume();
        expect(reply, const TypeMatcher<ErrorReply>());
        expect(reply.value, [69, 82, 82]);
      });
    });
  });
}
