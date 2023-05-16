// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Completer, Future;

import '../exception.dart';
import '../protocol.dart';

/// A mapper for processing the results of the commands.
// ignore: one_member_abstracts
abstract class Mapper<T> {
  /// Maps a Redis server [reply] to an object of type [T].
  T map(Reply reply, RedisCodec codec);
}

/// A Redis command that completes with a value of type [T].
abstract class Command<T> {
  /// Creates a [Command] instance for a given command [line] and an
  /// optional [mapper] for processing of the results.
  factory Command(Iterable<Object?> line, {Mapper<T>? mapper}) =>
      CommandBase<T>(line, mapper: mapper);

  /// Returns the original command [line] used to create this command.
  Iterable<Object> get line;

  /// Returns the [future] that is completed by this command.
  Future<T> get future;

  /// Completes this command with the given [reply].
  void complete(Reply reply, RedisCodec codec);

  /// Completes this command with the given error [reply].
  void completeErrorReply(ErrorReply reply, RedisCodec codec);

  /// Completes this command with an error, typically due to socket errors.
  void completeError(Object error, [StackTrace? stackTrace]);
}

/// Base class for implementing commands.
class CommandBase<T> implements Command<T> {
  final Completer<T> _completer = Completer<T>();

  /// The original command line.
  final Iterable<Object> _line;

  /// The optional mapper.
  final Mapper<T>? _mapper;

  /// Creates a [CommandBase] instancefor a given command [line] and an
  /// optional [mapper] for processing of the results.
  ///
  /// Null values are removed from the given command line.
  CommandBase(Iterable<Object?> line, {Mapper<T>? mapper})
      : _line = line.where((value) => value != null).map((value) => value!),
        _mapper = mapper;

  @override
  Iterable<Object> get line => _line;

  @override
  Future<T> get future => _completer.future;

  @override
  void complete(Reply reply, RedisCodec codec) {
    final value = _complete(reply, codec);

    _completer.complete(value);
  }

  @override
  void completeErrorReply(ErrorReply reply, RedisCodec codec) {
    final value = codec.decode<String>(reply);

    _completer.completeError(RedisException(value));
  }

  @override
  void completeError(Object error, [StackTrace? stackTrace]) =>
      _completer.completeError(error, stackTrace);

  /// Completes this command with the value in the given [reply].
  T? _complete(Reply reply, RedisCodec codec) {
    if (T.toString() == 'void') {
      return null;
    }
    if (reply is NullReply) {
      return null;
    }

    if (_mapper == null) {
      return codec.decode<T>(reply);
    }

    return _mapper!.map(reply, codec);
  }

  @override
  String toString() => '''CommandBase<$T>: {line=$_line,'''
      ''' done=${_completer.isCompleted}, mapper=$_mapper}''';
}

/// The MULTI command.
class MultiCommand extends CommandBase<void> {
  /// Creates a [MultiCommand] instance.
  MultiCommand(Iterable<Object> line) : super(line);
}

/// The EXEC command.
class ExecCommand extends CommandBase<void> {
  /// Creates a [ExecCommand] instance.
  ExecCommand(Iterable<Object> line) : super(line);
}

/// The DISCARD command.
class DiscardCommand extends CommandBase<void> {
  /// Creates a [DiscardCommand] instance.
  DiscardCommand(Iterable<Object> line) : super(line);
}

/// The CLIENT REPLY command.
///
/// Stores the specified server reply mode.
class ClientReplyCommand<T> extends CommandBase<T> {
  /// The specified server reply [mode] for this command.
  final ReplyMode mode;

  /// Creates a [ClientReplyCommand] instance.
  ClientReplyCommand(Iterable<Object> line, this.mode) : super(line);
}

/// Modes allowed for the CLIENT REPLY command.
class ReplyMode {
  /// The name of the mode.
  final String name;

  const ReplyMode._(this.name);

  /// The default mode in which the server returns a reply to every command.
  static const ReplyMode on = ReplyMode._(r'ON');

  /// In this mode the server will not reply to client commands.
  static const ReplyMode off = ReplyMode._(r'OFF');

  /// This mode skips the reply of command immediately after it.
  static const ReplyMode skip = ReplyMode._(r'SKIP');

  @override
  String toString() => 'ReplyMode: $name';
}
