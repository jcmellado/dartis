// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future, StreamSubscription;
import 'dart:io' show Socket, SocketOption;

import '../logger.dart';

/// A connection for communicating over a TCP socket with a Redis server.
class Connection {
  final Socket _socket;

  /// The stream socket subscription.
  final StreamSubscription<List<int>> _subscription;

  /// Creates a [Connection] instance with the given socket.
  ///
  /// [connect()] provides a more convenient way for creating instances
  /// of this class.
  Connection(this._socket) : _subscription = _socket.listen(null);

  /// Creates a new connection according to the host and port specified
  /// in the [connectionString].
  ///
  /// Connection string must follow the pattern "redis://{host}:{port}".
  ///
  /// Example: redis://localhost:6379
  ///
  /// Returns a [Future] that will complete with either a [Connection] once
  /// connected or an error if the connection failed.
  static Future<Connection> connect(String connectionString) async {
    final uri = RedisUri.parse(connectionString);

    log.fine(() => 'Attempting to connect to "$uri".');

    /// ignore: close_sinks
    final socket = await Socket.connect(uri.host, uri.port)
      ..setOption(SocketOption.tcpNoDelay, true);

    log.info('Connected to "$uri".');

    return Connection(socket);
  }

  /// Replaces the current event handlers.
  void listen(void Function(List<int> data) onData, void Function() onDone) {
    _subscription
      ..onData(onData)
      ..onDone(onDone);
  }

  /// Sends raw [data] through the socket.
  void send(List<int> data) {
    log.finest(() => 'Sent data: $data.');

    _socket.add(data);
  }

  /// Closes the socket.
  Future<void> disconnect() async {
    await _socket.flush();
    await _socket.close();
    _socket.destroy();

    log.info('Disconnected.');
  }
}

/// A parsed Redis connection string.
///
/// Connection string must follow the pattern "redis://{host}:{port}".
///
/// Example: redis://localhost:6379
class RedisUri {
  final Uri _uri;

  RedisUri._(this._uri);

  /// Returns the host name.
  String get host => _uri.host;

  /// Returns the port number.
  int get port => _uri.port;

  /// Creates a new [RedisUri] object by parsing a URI string.
  // ignore: prefer_constructors_over_static_methods
  static RedisUri parse(String connectionString) {
    final uri = Uri.parse(connectionString);

    if (!_isValid(uri)) {
      throw FormatException(
          '''Invalid Redis connection string "$connectionString".\n'''
          '''It must follow the pattern "redis://{host}:{port}".\n'''
          '''Example: "redis://localhost:6379".''');
    }

    return RedisUri._(uri);
  }

  static bool _isValid(Uri uri) =>
      uri.scheme == 'redis' && uri.host.isNotEmpty && uri.hasPort;

  @override
  String toString() => _uri.toString();
}
