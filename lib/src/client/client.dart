// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:collection' show Queue;

import '../command.dart';
import '../exception.dart';
import '../logger.dart';
import '../protocol.dart';
import 'connection.dart';
import 'dispatcher.dart';
import 'transaction.dart';

/// A client that allows to send commands to a Redis server.
///
/// See [:PubSub:] for working in Publish/Subscribe mode.
///
/// See [:Monitor:] for working in Monitor mode.
///
/// See [:Terminal:] for working with inlined commands.
///
/// This client supports "pipelining" and "fire and forget".
///
/// In the pipelined mode, started calling [pipeline()], the commands
/// are stored locally until [flush()] is called. Then all the stored
/// commands are sent to the server in only one call, instead of doing
/// one call for each command.
///
/// In the "fire and forget" mode, started calling [Commands.clientReply()]
/// with [ReplyMode.off], or [ReplyMode.skip], the server doesn't sent
/// replies for the commands, so the client doesn't need to wait for them.
///
/// See `client.dart` in the `example` folder.
class Client implements CommandRunner {
  /// The underlying raw connection object.
  final Connection _connection;

  // Dispatcher.
  final _ClientDispatcher _dispatcher;

  /// Delayed commands.
  final List<Command<Object?>> _delayed = [];

  /// Whether this is in the pipelined mode.
  bool _pipelined = false;

  /// Creates a [Client] instance with the given [_connection].
  ///
  /// [connect()] provides a more convenient way for creating instances of
  /// this class.
  Client(this._connection) : _dispatcher = _ClientDispatcher(_connection);

  /// Creates a new connection according to the host and port specified
  /// in the [connectionString].
  ///
  /// Connection string must follow the pattern "redis://{host}:{port}".
  ///
  /// Example: redis://localhost:6379
  ///
  /// Returns a [Future] that will complete with either a [Client]
  /// once connected or an error if the connection failed.
  static Future<Client> connect(String connectionString) async {
    final connection = await Connection.connect(connectionString);

    return Client(connection);
  }

  /// The undelying raw connection object.
  Connection get connection => _connection;

  /// The converter used to serialize/deserialize all the values.
  ///
  /// Custom converters can be registered in order of adding new ones
  /// or replacing the existing ones.
  RedisCodec get codec => _dispatcher.codec;

  /// Returns a [Commands] view of this.
  ///
  /// The returned view can be used to execute Redis commands in a type-safe
  /// way.
  ///
  /// [K] is the type to be used for Redis keys and [V] for values. Most
  /// times, using [String] for keys and values is what you want:
  ///
  /// ```dart
  /// final commands = client.asCommands<String, String>();
  /// ```
  ///
  /// It's correct to call this method several times in order to get views with
  /// different parameterized types:
  ///
  /// ```dart
  /// final strings = client.asCommands<String, String>();
  /// final bytes = client.asCommands<String, List<int>>();
  ///
  /// String title = await strings.get('book:24902:title');
  /// List<int> cover = await bytes.get('book:24902:cover');
  ///
  /// // ERROR String author = await bytes.get('book:24092:author');
  /// ```
  ///
  /// Use [codec] to register new type converters or overwrite the
  /// existing ones.
  ///
  /// See [Commands].
  Commands<K, V> asCommands<K extends Object, V extends Object>() =>
      Commands<K, V>(this);

  /// Starts the pipelined mode in order to send multiple commands to the
  /// server in only one call, instead of doing one call for each command.
  ///
  /// In this mode, the client stores locally all the commands without sending
  /// them to the server until [flush()] is called.
  ///
  /// ```dart
  /// client.pipeline();
  ///
  /// commands.incr('product:9238:views').then(print);
  /// commands.incr('product:1725:views').then(print);
  /// commands.incr('product:4560:views').then(print);
  ///
  /// client.flush();
  /// ```
  ///
  /// Note that in this mode `await` can not be used for waiting the result
  /// of the execution of each command, because the returned future will not
  /// be completed until [flush()] was called.
  ///
  /// [flush()] returns a list of [Future]s that can be used for waiting
  /// the completion of all the commands.
  ///
  /// ```dart
  /// client.pipeline();
  ///
  /// commands.
  ///     ..incr('product:9238:views')
  ///     ..incr('product:1725:views')
  ///     ..incr('product:4560:views');
  ///
  /// final futures = client.flush();
  ///
  /// await Future.wait<Object>(futures).then(print);
  /// ```
  ///
  /// It's safe to call this method two or more times before calling [flush()].
  void pipeline() {
    _pipelined = true;
  }

  /// Exits of the pipelined mode sending all the commands locally stored,
  /// since [pipeline()] was called, to the server in only one call.
  ///
  /// Returns a [List] with a [Future] for each command that will complete with
  /// either the result of its execution or an error if the execution failed.
  ///
  /// It's safe to call this method even before calling [pipeline()].
  List<Future<Object?>> flush() {
    final futures = _dispatcher.dispatchAll(_delayed);

    _delayed.clear();
    _pipelined = false;

    return futures;
  }

  /// Runs a [command] that returns a value of type [T].
  ///
  /// If the pipelined mode is active then the command is delayed until
  /// [flush()] was called.
  ///
  /// Returns a [Future] that will complete with either the result of its
  /// execution or an error if the execution failed.
  ///
  /// If the 'fire and forget' mode is currently active then the [Future]
  /// is immediately completed with `null`.
  @override
  Future<T> run<T>(Command<T> command) =>
      _pipelined ? _delay(command) : _dispatcher.dispatch(command);

  /// Closes the connection.
  Future<void> disconnect() => _dispatcher.disconnect();

  Future<T> _delay<T>(Command<T> command) {
    _delayed.add(command);

    return command.future;
  }
}

/// A dispatcher for a client.
class _ClientDispatcher extends ReplyDispatcher {
  /// Commands waiting for a server reply.
  final Queue<Command<Object?>> _unreplied = Queue<Command<Object?>>();

  /// Transaction in progress, if any.
  final Transaction _transaction = Transaction();

  /// Current reply mode according the last runned CLIENT REPLY command.
  ReplyMode _replyMode = ReplyMode.on;

  _ClientDispatcher(Connection connection) : super(connection);

  /// Sends a [command] to the server.
  Future<T> dispatch<T>(Command<T> command) {
    final bytes = writer.write(command.line, codec);
    send(bytes);

    _fire(command);

    return command.future;
  }

  /// Sends a list of [commands] to the server.
  List<Future<Object?>> dispatchAll(Iterable<Command<Object?>> commands) {
    final lines = commands.map((command) => command.line);

    final bytes = writer.writeAll(lines, codec);
    send(bytes);

    final futures = commands.map(_fire).toList();
    return futures;
  }

  /// Stores a [command] for completing it with the server reply, or
  /// completes it immediately with `null` if the 'fire and forget'
  /// mode is currently active.
  Future<Object?> _fire(Command<Object?> command) {
    final fireAndForget = _mustFireAndForget(command);

    if (fireAndForget) {
      command.complete(nullReply, codec);
    } else {
      _unreplied.add(command);
    }

    return command.future;
  }

  /// Checks if a [command] must be completed without waiting a server reply.
  bool _mustFireAndForget(Command<Object?> command) {
    if (command is ClientReplyCommand) {
      _replyMode = command.mode;
      return _replyMode != ReplyMode.on;
    }
    if (_replyMode == ReplyMode.skip) {
      _replyMode = ReplyMode.on;
      return true;
    }
    return _replyMode == ReplyMode.off;
  }

  @override
  void onReply(Reply reply) {
    if (_unreplied.isEmpty) {
      throw RedisException('Unexpected server reply: $reply.');
    }

    final command = _unreplied.removeFirst();
    log.finer(() => 'Completed command $command with reply $reply.');

    // Completes the command or waits until the end of the current transaction.
    if (_transaction.inProgress) {
      _transaction.onReply(command, reply, codec);
    } else {
      _transaction.begin(command);

      command.complete(reply, codec);
    }
  }

  @override
  void onErrorReply(ErrorReply reply) {
    if (_unreplied.isEmpty) {
      throw RedisException('Unexpected server error reply: $reply.');
    }

    final command = _unreplied.removeFirst();
    log.finer(() => 'Completed Command $command with error reply $reply.');

    // Completes the command or waits until the end of the current transaction.
    if (_transaction.inProgress) {
      _transaction.onErrorReply(command, reply, codec);
    } else {
      command.completeErrorReply(reply, codec);
    }
  }

  @override
  void onError(Object error, [StackTrace? stackStrace]) {
    try {
      for (var command in _unreplied) {
        command.completeError(error, stackStrace);
      }
      _unreplied.clear();
      if (_transaction.inProgress) {
        _transaction.onError(error, stackStrace);
      }
    } finally {
      // Disconnects to ensure the socket is destroyed.
      disconnect();
    }
  }

  @override
  void onDone() {
    if (_unreplied.isNotEmpty) {
      log.info('Discarding ${_unreplied.length} commands without replies.');
    }
    if (_transaction.inProgress) {
      log.info('Discarding current transaction in progress.');
    }
  }
}
