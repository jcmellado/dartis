// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import '../command.dart';
import '../exception.dart';
import '../protocol.dart';

/// A transaction.
class Transaction {
  /// Queued commands.
  final List<Command<Object?>> _queued = [];

  /// Whether this transaction is in progress.
  bool _inProgress = false;

  /// Returns the "in progress" flag.
  bool get inProgress => _inProgress;

  /// Starts this transaction.
  void begin(Command<Object?> command) {
    _inProgress = command is MultiCommand;
  }

  /// Ends this transaction.
  void end() {
    _queued.clear();
    _inProgress = false;
  }

  /// Completes a [command] with a [reply] in the context of this transaction.
  void onReply(Command<Object?> command, Reply reply, RedisCodec codec) {
    assert(_inProgress);
    assert(command is! MultiCommand);

    if (command is ExecCommand) {
      _exec(command, reply, codec);
    } else if (command is DiscardCommand) {
      _discard(command, reply, codec);
    } else {
      _enqueue(command, reply, codec);
    }
  }

  /// Completes a [command] with an error [reply] in the context of
  /// this transaction.
  void onErrorReply(
      Command<Object?> command, ErrorReply reply, RedisCodec codec) {
    assert(_inProgress);

    // Failed EXEC command?
    if (command is ExecCommand) {
      _abort(reply, codec);
    }

    command.completeErrorReply(reply, codec);
  }

  /// Completes all commands in the transaction with [error].
  void onError(Object error, StackTrace? stackTrace) {
    assert(_inProgress);

    for (final command in _queued) {
      command.completeError(error);
    }

    end();
  }

  /// Completes all the queued commands.
  void _exec(Command command, Reply reply, RedisCodec codec) {
    // Redis server replies a null value when some watched keys are modified.
    if (reply.value == null) {
      _discard(command, reply, codec);
    } else {
      _dequeue(command, reply as ArrayReply, codec);
    }
  }

  /// Completes all the queued commands with an error.
  void _discard(Command command, Reply reply, RedisCodec codec) {
    final error = ErrorReply('Transaction discarded.'.codeUnits);

    for (final command in _queued) {
      command.completeErrorReply(error, codec);
    }

    command.complete(reply, codec);

    end();
  }

  /// Completes all the queued commands with the given error [reply].
  void _abort(ErrorReply reply, RedisCodec codec) {
    for (final command in _queued) {
      command.completeErrorReply(reply, codec);
    }

    end();
  }

  /// Enqueues a [command].
  void _enqueue(Command<Object?> command, Reply reply, RedisCodec codec) {
    if (reply is! StringReply) {
      throw RedisException(
          'Expected "StringReply", but "${reply.runtimeType}" found instead.');
    }

    final value = codec.decode<String>(reply);
    if (value != 'QUEUED') {
      throw RedisException(
          'Expected "QUEUED" reply, but "$value" found instead.');
    }

    // Enqueue the command.
    _queued.add(command);
  }

  /// Completes the queued commands with the array of replies in [reply].
  void _dequeue(Command command, ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    if (array.length != _queued.length) {
      throw RedisException('''Expected ${_queued.length} replies,'''
          ''' but "${array.length}" found instead.''');
    }

    // Completes the queued commands.
    _dequeueAll(array, codec);

    command.complete(reply, codec);

    end();
  }

  /// Completes the queued commands.
  void _dequeueAll(List<Reply> array, RedisCodec codec) {
    for (var i = 0; i < _queued.length; i++) {
      final command = _queued[i];
      final reply = array[i];

      if (reply is ErrorReply) {
        command.completeErrorReply(reply, codec);
      } else {
        command.complete(reply, codec);
      }
    }
  }
}
