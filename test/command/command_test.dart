// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

class _ReverseMapper implements Mapper<String> {
  @override
  String map(covariant StringReply reply, RedisCodec codec) =>
      String.fromCharCodes(reply.bytes.reversed);
}

void main() {
  final codec = RedisCodec();

  group('CommandBase', () {
    test('toString', () {
      final command = Command<String>([]);
      expect(command.toString(), startsWith('CommandBase<String>:'));
    });
  });

  group('Command', () {
    group('line', () {
      test('with non null values', () {
        final command = Command<String>(<Object>['ECHO', 'message']);
        expect(command.line.toList(), equals(['ECHO', 'message']));
      });

      test('with some null values', () {
        final command = Command<String>(['PING', null]);
        expect(command.line.toList(), equals(['PING']));
      });
    });

    group('complete', () {
      test('with value', () {
        final command = Command<String>(<Object>['PING']);

        final reply = StringReply('PONG'.codeUnits);
        command.complete(reply, codec);

        expect(command.future, completion('PONG'));
      });

      test('with void', () {
        final command = Command<void>(<Object>['CMD']);

        final reply = StringReply('PONG'.codeUnits);
        command.complete(reply, codec);

        expect(command.future, completion(isNull));
      });

      test('with a mapper', () {
        final command =
            Command<String>(<Object>['CMD'], mapper: _ReverseMapper());

        final reply = StringReply('PONG'.codeUnits);
        command.complete(reply, codec);

        expect(command.future, completion('GNOP'));
      });
    });

    group('completeError', () {
      test('with value', () {
        final command = Command<String>(<Object>['CMD']);

        final reply = ErrorReply('ERR'.codeUnits);
        command.completeErrorReply(reply, codec);

        expect(command.future, throwsA(const TypeMatcher<RedisException>()));
      });
    });
  });

  group('ReplyMode', () {
    test('toString', () {
      expect(ReplyMode.on.toString(), startsWith('ReplyMode:'));
    });
  });
}
