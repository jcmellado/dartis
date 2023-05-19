// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

void main() {
  final codec = RedisCodec();

  /// A convenient matcher.
  final throwRedisException = throwsA(const TypeMatcher<RedisException>());

  group('Transaction', () {
    test('begins and ends', () async {
      final transaction = Transaction();

      expect(transaction.inProgress, isFalse);

      // Begin with the MULTI command.
      transaction.begin(MultiCommand(<Object>['MULTI']));
      expect(transaction.inProgress, isTrue);

      // End.
      transaction.end();
      expect(transaction.inProgress, isFalse);
    });

    test('completes the commands', () async {
      final transaction = Transaction();
      expect(transaction.inProgress, isFalse);

      // MULTI
      transaction.begin(MultiCommand(<Object>['MULTI']));

      // QUEUED PING
      final ping = Command<String>(<Object>['PING']);
      final queued = StringReply('QUEUED'.codeUnits);
      transaction.onReply(ping, queued, codec);

      // QUEUED ECHO message
      final echo = Command<String>(<Object>['ECHO', 'message']);
      transaction.onReply(echo, queued, codec);

      // EXEC
      final exec = ExecCommand(<Object>['EXEC']);
      final reply = ArrayReply(
          [StringReply('PONG'.codeUnits), StringReply('message'.codeUnits)]);
      transaction.onReply(exec, reply, codec);

      expect(ping.future, completion(equals('PONG')));
      expect(echo.future, completion(equals('message')));
      expect(exec.future, completes);
      expect(transaction.inProgress, isFalse);
    });

    test('completes the commands with errors', () async {
      final transaction = Transaction();
      expect(transaction.inProgress, isFalse);

      // MULTI
      transaction.begin(MultiCommand(<Object>['MULTI']));

      // QUEUED PING
      final ping = Command<String>(<Object>['PING']);
      final queued = StringReply('QUEUED'.codeUnits);
      transaction.onReply(ping, queued, codec);

      // QUEUED erroneus LPOP key
      final lpop = Command<String>(<Object>['LPOP', 'key']);
      transaction.onReply(lpop, queued, codec);

      // EXEC
      final exec = ExecCommand(<Object>['EXEC']);
      final reply = ArrayReply(
          [StringReply('PONG'.codeUnits), ErrorReply('ERROR'.codeUnits)]);
      transaction.onReply(exec, reply, codec);

      expect(ping.future, completion(equals('PONG')));
      expect(lpop.future, throwRedisException);
      expect(exec.future, completes);
      expect(transaction.inProgress, isFalse);
    });

    test('discards the commands', () async {
      final transaction = Transaction();
      expect(transaction.inProgress, isFalse);

      // MULTI
      transaction.begin(MultiCommand(<Object>['MULTI']));

      // QUEUED PING
      final ping = Command<String>(<Object>['PING']);
      final queued = StringReply('QUEUED'.codeUnits);
      transaction.onReply(ping, queued, codec);

      // QUEUED ECHO message
      final echo = Command<String>(<Object>['ECHO', 'message']);
      transaction.onReply(echo, queued, codec);

      // DISCARD
      final discard = DiscardCommand(<Object>['DISCARD']);
      final reply = StringReply('OK'.codeUnits);
      transaction.onReply(discard, reply, codec);

      expect(ping.future, throwRedisException);
      expect(echo.future, throwRedisException);
      expect(discard.future, completes);
      expect(transaction.inProgress, isFalse);
    });

    test('aborts because of previous errors', () async {
      final transaction = Transaction();
      expect(transaction.inProgress, isFalse);

      // MULTI
      transaction.begin(MultiCommand(<Object>['MULTI']));

      // ERROR ECHO
      final echo = Command<String>(<Object>['ECHO']);
      final error = ErrorReply('ERROR'.codeUnits);
      transaction.onErrorReply(echo, error, codec);

      // QUEUED PING
      final ping = Command<String>(<Object>['PING']);
      final queued = StringReply('QUEUED'.codeUnits);
      transaction.onReply(ping, queued, codec);

      // EXEC
      final exec = ExecCommand(<Object>['EXEC']);
      final reply = ErrorReply('ERROR'.codeUnits);
      transaction.onErrorReply(exec, reply, codec);

      expect(echo.future, throwRedisException);
      expect(ping.future, throwRedisException);
      expect(exec.future, throwRedisException);
      expect(transaction.inProgress, isFalse);
    });

    test('aborts because some watched keys were modified', () async {
      final transaction = Transaction();
      expect(transaction.inProgress, isFalse);

      // MULTI
      transaction.begin(MultiCommand(<Object>['MULTI']));

      // QUEUED SET key 'abc'
      final set = Command<String>(<Object>['SET', 'key', 'abc']);
      final queued = StringReply('QUEUED'.codeUnits);
      transaction.onReply(set, queued, codec);

      // QUEUED PING
      final ping = Command<String>(<Object>['PING']);
      transaction.onReply(ping, queued, codec);

      // EXEC
      final exec = ExecCommand(<Object>['EXEC']);
      const reply = NullReply();
      transaction.onReply(exec, reply, codec);

      expect(set.future, throwRedisException);
      expect(ping.future, throwRedisException);
      expect(transaction.inProgress, isFalse);
    });

    test('aborts because receives unexpected replies', () async {
      final transaction = Transaction();
      expect(transaction.inProgress, isFalse);

      // MULTI
      transaction.begin(MultiCommand(<Object>['MULTI']));

      // QUEUED PING
      final ping = Command<String>(<Object>['PING']);

      // Try to end with a invalid bulk reply.
      final xxx = BulkReply('XXX'.codeUnits);
      expect(() => transaction.onReply(ping, xxx, codec), throwRedisException);

      // Try to end with a invalid string reply.
      final yyy = StringReply('YYY'.codeUnits);
      expect(() => transaction.onReply(ping, yyy, codec), throwRedisException);

      final queued = StringReply('QUEUED'.codeUnits);
      transaction.onReply(ping, queued, codec);

      // EXEC
      final exec = ExecCommand(<Object>['EXEC']);

      // Try to end with a invalid empty reply.
      const zzz = ArrayReply([]);
      expect(() => transaction.onReply(exec, zzz, codec), throwRedisException);
    });
  });
}
