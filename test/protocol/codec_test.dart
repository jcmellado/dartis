// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

/// A encoder that encodes a [DateTime] to a list of bytes.
class _DateTimeEncoder extends Encoder<DateTime> {
  @override
  List<int> convert(DateTime value, RedisCodec codec) =>
      utf8.encode(value.toString());
}

/// A decoder that decodes a server reply to a [DateTime].
class _DateTimeDecoder extends Decoder<SingleReply, DateTime> {
  @override
  DateTime convert(SingleReply value, RedisCodec codec) =>
      DateTime.parse(utf8.decode(value.bytes));
}

/// A encoder that encodes a [DateTime] to a list of bytes.
class _IsoDateTimeEncoder extends Encoder<DateTime> {
  @override
  List<int> convert(DateTime value, RedisCodec codec) =>
      utf8.encode(value.toIso8601String());
}

/// A decoder that always returns 999.
class _Int999Decoder extends Decoder<SingleReply, int> {
  @override
  int convert(SingleReply value, RedisCodec codec) => 999;
}

void main() {
  /// Converts an [array] of lists of bytes to a list of replies.
  List<Reply> replies(List<List<int>> array) =>
      array.map(StringReply.new).toList();

  group('RedisCodec', () {
    final codec = RedisCodec();
    final encode = codec.encode;
    final decode = codec.decode;

    group('register', () {
      test('new encoder', () {
        final codec = RedisCodec();

        // Try to encode a DateTime instance.
        expect(() => codec.encode<List<int>>(DateTime.now()),
            throwsA(const TypeMatcher<RedisException>()));

        // Register the encoder.
        codec.register(encoder: _DateTimeEncoder());

        // Try to encode again.
        expect(
            codec.encode<List<int>>(DateTime.utc(2018)),
            equals([
              50, 48, 49, 56, 45, 48, 49, 45, 48, 49, 32, 48, 48, 58, 48, 48,
              58, 48, 48, 46, 48, 48, 48, 90 // 2018-01-01-01 00:00:00.000Z
            ]));
      });

      test('new decoder', () {
        final codec = RedisCodec();

        // Try to decode to a DateTime instance.
        expect(() => codec.decode<DateTime>(<int>[]),
            throwsA(const TypeMatcher<RedisException>()));

        // Register the decoder.
        codec.register(decoder: _DateTimeDecoder());

        // Try to decode again.
        expect(
            codec.decode<DateTime>(const BulkReply([
              50, 48, 49, 56, 45, 48, 49, 45, 48, 49, 32, 48, 48, 58, 48, 48,
              58, 48, 48, 46, 48, 48, 48, 90 // 2018-01-01-01 00:00:00.000Z
            ])),
            equals(DateTime.utc(2018)));
      });

      test('overwrite encoder', () {
        // Register an encoder and encode.
        final codec = RedisCodec()..register(encoder: _DateTimeEncoder());

        expect(
            codec.encode<List<int>>(DateTime.utc(2018)),
            equals([
              50, 48, 49, 56, 45, 48, 49, 45, 48, 49, 32, 48, 48, 58, 48, 48,
              58, 48, 48, 46, 48, 48, 48, 90 // 2018-01-01-01 00:00:00.000Z
            ]));

        // Register the new encoder and encode again.
        codec.register(encoder: _IsoDateTimeEncoder());

        expect(
            codec.encode<List<int>>(DateTime.utc(2018)),
            equals([
              50, 48, 49, 56, 45, 48, 49, 45, 48, 49, 84, 48, 48, 58, 48, 48,
              58, 48, 48, 46, 48, 48, 48, 90 // 2018-01-01-01T00:00:00.000Z
            ]));
      });

      test('overwrite decoder', () {
        final codec = RedisCodec();
        expect(codec.decode<int>(const IntReply([49, 50, 51])), equals(123));

        // Register the new decoder and decode again.
        codec.register(decoder: _Int999Decoder());

        expect(codec.decode<int>(const IntReply([49, 50, 51])), equals(999));
      });
    });

    group('encode', () {
      test('String to List<int>', () {
        expect(encode<List<int>>(''), equals(<int>[]));
        expect(encode<List<int>>('ABC'), equals([65, 66, 67]));
        expect(encode<List<int>>('漢語'), equals([230, 188, 162, 232, 170, 158]));
      });

      test('int to List<int>', () {
        expect(encode<List<int>>(1), equals([49]));
        expect(encode<List<int>>(25), equals([50, 53]));
        expect(encode<List<int>>(-7), equals([45, 55]));
      });

      test('double to List<int>', () {
        expect(encode<List<int>>(1.0), equals([49, 46, 48]));
        expect(encode<List<int>>(25.89), equals([50, 53, 46, 56, 57]));
        expect(encode<List<int>>(-6.03), equals([45, 54, 46, 48, 51]));
        expect(encode<List<int>>(5.1e3), equals([53, 49, 48, 48, 46, 48]));
        expect(encode<List<int>>(0.1e-2), equals([48, 46, 48, 48, 49]));
        expect(encode<List<int>>(double.infinity), equals([43, 105, 110, 102]));
        expect(encode<List<int>>(double.negativeInfinity),
            equals([45, 105, 110, 102]));
        expect(() => encode<List<int>>(double.nan),
            throwsA(const TypeMatcher<RedisException>()));
      });

      test('List<int> to List<int>', () {
        expect(encode<List<int>>(<int>[]), equals(<int>[]));
        expect(encode<List<int>>([1]), equals([1]));
        expect(encode<List<int>>([1, 2, 3]), equals([1, 2, 3]));
      });
    });

    group('decode', () {
      test('List<int> to String', () {
        expect(decode<String>(const StringReply(<int>[])), equals(''));
        expect(decode<String>(const StringReply([65, 66, 67])), equals('ABC'));
        expect(
            decode<String>(const StringReply([230, 188, 162, 232, 170, 158])),
            equals('漢語'));
      });

      test('List<int> to int', () {
        expect(
            () => decode<int>(const IntReply(<int>[])), throwsFormatException);
        expect(decode<int>(const IntReply([49])), equals(1));
        expect(decode<int>(const IntReply([50, 53])), equals(25));
        expect(decode<int>(const IntReply([45, 55])), equals(-7));
      });

      test('List<int> to double', () {
        expect(
            () => decode<int>(const BulkReply(<int>[])), throwsFormatException);
        expect(decode<double>(const BulkReply([49, 46, 48])), equals(1.0));
        expect(decode<double>(const BulkReply([50, 53, 46, 56, 57])),
            equals(25.89));
        expect(decode<double>(const BulkReply([45, 54, 46, 48, 51])),
            equals(-6.03));
        expect(decode<double>(const BulkReply([53, 49, 48, 48, 46, 48])),
            equals(5.1e3));
        expect(decode<double>(const BulkReply([48, 46, 48, 48, 49])),
            equals(0.1e-2));
        expect(decode<double>(const BulkReply([43, 105, 110, 102])),
            equals(double.infinity));
        expect(decode<double>(const BulkReply([45, 105, 110, 102])),
            equals(double.negativeInfinity));
      });

      test('List<int> to List<int>', () {
        expect(decode<List<int>>(const BulkReply(<int>[])), equals(<int>[]));
        expect(decode<List<int>>(const BulkReply([1])), equals(<int>[1]));
        expect(decode<List<int>>(const BulkReply([1, 2, 3])),
            equals(<int>[1, 2, 3]));
      });

      test('List<Reply> to List<String>', () {
        expect(
            decode<List<String>>(ArrayReply(replies([]))), equals(<String>[]));
        expect(
            decode<List<String>>(ArrayReply(replies([
              [65, 66, 67]
            ]))),
            equals(['ABC']));
        expect(
            decode<List<String>>(ArrayReply(replies([
              [230, 188, 162],
              [232, 170, 158]
            ]))),
            equals(['漢', '語']));
      });

      test('List<Reply> to List<int>', () {
        expect(decode<List<int>>(ArrayReply(replies([]))), equals(<String>[]));
        expect(
            decode<List<int>>(ArrayReply(replies([
              [49]
            ]))),
            equals([1]));
        expect(
            decode<List<int>>(ArrayReply(replies([
              [50, 53],
              [45, 55]
            ]))),
            equals([25, -7]));
      });

      test('List<Reply> to List<double>', () {
        expect(
            decode<List<double>>(ArrayReply(replies([]))), equals(<double>[]));
        expect(
            decode<List<double>>(ArrayReply(replies([
              [49, 46, 48]
            ]))),
            equals([1.0]));
        expect(
            decode<List<double>>(ArrayReply(replies([
              [50, 53, 46, 56, 57],
              [45, 54, 46, 48, 51],
              [53, 49, 48, 48, 46, 48],
              [48, 46, 48, 48, 49],
              [43, 105, 110, 102],
              [45, 105, 110, 102]
            ]))),
            equals([
              25.89,
              -6.03,
              5.1e3,
              0.1e-2,
              double.infinity,
              double.negativeInfinity
            ]));
      });
    });
  });

  //TODO: add tests for:
  // Decode:
  // - decode<String|int|List<int>...>(null) => throw Exception
  // - decode<String?|int?|List<int>?>(null) => ok
  // - decode<List<int?>>([null]) => ok
  // - decode<List<int|String|...>>([null]) => not ok
  // - decode<List<List<int>>([]) => ok
}
