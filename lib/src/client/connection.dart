// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Completer, Future, StreamSubscription, Zone;
import 'dart:io' show SecureSocket, Socket, SocketOption;

import '../exception.dart';
import '../logger.dart';

/// A connection for communicating over a TCP socket with a Redis server.
class Connection {
  final Socket _socket;

  /// The stream socket subscription.
  final StreamSubscription<List<int>> _subscription;

  /// Error handler from the latest listener.
  void Function(Object, StackTrace?)? _onErrorListener;

  /// Implementation of [done].
  final Completer<void> _done = Completer<void>();

  /// Creates a [Connection] instance with the given socket.
  ///
  /// [connect()] provides a more convenient way for creating instances
  /// of this class.
  Connection(this._socket) : _subscription = _socket.listen(null) {
    // If the out-going half of the socket closes, we mark the connection as
    // closed for sending. If there is an error, either when listening or when
    // sending we forward it as an error to the listener.
    _socket.done
        .catchError(_onError)
        .whenComplete(() => _done.isCompleted ? null : _done.complete());
    _subscription.onError(_onError);
  }

  /// Future that is resolved when the connection is closed.
  ///
  /// If the connection closes gracefully this future will be completed and
  /// future attempts to use the connection will throw a
  /// [RedisConnectionClosedException].
  ///
  /// If the connection is broken, an error occurs writing/reading to/from the
  /// connection this future will be resolved with error. If unhandled this
  /// will propagate to the encapsulating [Zone] where it may be handled.
  /// If using the default root [Zone] this will cause the isolate to crash.
  ///
  /// If not implementing custom reconnection logic it might be desirable to
  /// simply restart the process when it crashes.
  ///
  /// If implementing custom reconnection logic, consumers should stop using a
  /// connection once [done] have been resolved, as all future commands will
  /// will throw an error. If an error occurs reading or writing all outstanding
  /// commands will be resolved with an exception.
  Future<void> get done => _done.future;

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

    // ignore: close_sinks
    final socket = (uri.isTls
        ? await SecureSocket.connect(uri.host, uri.port)
        : await Socket.connect(uri.host, uri.port))
      ..setOption(SocketOption.tcpNoDelay, true);

    log.info('Connected to "$uri".');

    return Connection(socket);
  }

  /// Replaces the current event handlers.
  void listen(void Function(List<int> data) onData,
      void Function(Object, [StackTrace?])? onError, void Function()? onDone) {
    _subscription
      ..onData(onData)
      ..onDone(onDone);
    // We use _onErrorListener because we also want to call this if there was
    // errors sending data.
    _onErrorListener = onError;
  }

  /// Sends raw [data] through the socket.
  void send(List<int> data) {
    if (_done.isCompleted) {
      // This could just be graceful shutdown from the server
      log.info('Attempted to send data after outgoing connection closed.');
      throw const RedisConnectionClosedException();
    }

    log.finest(() => 'Sent data: $data.');

    _socket.add(data);
  }

  /// Closes the socket.
  Future<void> disconnect() async {
    try {
      await _socket.flush();
      await _socket.close();
    } finally {
      // Always destroy the socket to avoid leaking. Just in case there is an
      // error during flush for some reason.
      _socket.destroy();
    }

    log.info('Disconnected.');
  }

  void _onError(Object error, [StackTrace? stackTrace]) {
    log.info('An error read/write to socket occured.', error, stackTrace);

    // Stop trying to send anything new.
    if (!_done.isCompleted) {
      _done.completeError(error, stackTrace);
    }

    try {
      // If an onErrorHandler have been set we forward the error, otherwise, we
      // rethrow the error into the ether and let the wrapping zone capture it.
      if (_onErrorListener == null) {
        throw error; // ignore: only_throw_errors
      }
      _onErrorListener!(error, stackTrace);
    } finally {
      // Ensure we cleanup, by destroying the socket.
      _socket.destroy();
    }
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

  /// Returns if the scheme is rediss.
  bool get isTls => _uri.scheme == 'rediss';

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
      (uri.scheme == 'redis' || uri.scheme == 'rediss') &&
      uri.host.isNotEmpty &&
      uri.hasPort;

  @override
  String toString() => _uri.toString();
}
