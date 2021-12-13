// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:typed_data' show Uint8List;

import '../logger.dart';
import '../protocol.dart';
import 'connection.dart';

/// Shared command writer.
final Writer writer = Writer();

/// Base class for implementing dispatchers.
abstract class DispatcherBase {
  /// The underlying network connection.
  final Connection _connection;

  /// The serializer/deserializer.
  final RedisCodec codec = RedisCodec();

  /// Creates a [DispatcherBase] with the given connection.
  DispatcherBase(this._connection) {
    _connection.listen(onData, onError, onDone);
  }

  /// Sends [data] through the network connection.
  void send(List<int> data) {
    _connection.send(data);
  }

  /// Closes the network connection.
  Future<void> disconnect() => _connection.disconnect();

  /// Overwrite this method for receiving incoming [data].
  void onData(List<int> data);

  /// Overwrite this method to handle errors that occured reading or writing
  /// to the connection.
  void onError(Object error, [StackTrace? stackTrace]) {
    // Default to rethrow the error.
    throw error; // ignore: only_throw_errors
  }

  /// Overwrite this method for receiving on done signal.
  void onDone();
}

/// A dispatcher that analyzes incoming raw data and streams reply objects.
abstract class ReplyDispatcher extends DispatcherBase {
  /// Current reply reader.
  Reader? _reader;

  /// Creates a [ReplyDispatcher] instance with the given [connection].
  ReplyDispatcher(Connection connection) : super(connection);

  /// Analyzes the incoming [data] and extracts the replies from it.
  @override
  void onData(List<int> data) {
    log.finest(() => 'Received data: $data.');

    final bytes = data is Uint8List ? data : Uint8List.fromList(data);

    var index = 0;
    while (index < bytes.length) {
      // Creates a reader.
      if (_reader == null) {
        final type = bytes[index++];
        _reader = Reader(type);
      }

      // Reads.
      index = _reader!.read(bytes, index);

      // Consumes the reply.
      if (_reader!.done) {
        final reply = _reader!.consume();
        _dispatch(reply);
        _reader = null;
      }
    }
  }

  void _dispatch(Reply reply) {
    log.finest(() => 'Consumed reply: $reply.');

    if (reply is ErrorReply) {
      onErrorReply(reply);
    } else {
      onReply(reply);
    }
  }

  /// Overwrite this method for receiving incoming replies.
  void onReply(Reply reply);

  /// Overwrite this method for receiving incoming error replies.
  void onErrorReply(ErrorReply reply);
}
