// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future, Stream, StreamController;

import '../exception.dart';
import '../protocol.dart';
import 'connection.dart';
import 'dispatcher.dart';

/// Pub/Sub event types.
abstract class PubSubEventType {
  /// Subscription to a channel.
  static const String subscribe = r'subscribe';

  /// Unsubscription from a channel.
  static const String unsubscribe = r'unsubscribe';

  /// Subscription to a pattern.
  static const String psubscribe = r'psubscribe';

  /// Unsubscription from a pattern.
  static const String punsubscribe = r'punsubscribe';

  /// Incoming message.
  static const String message = r'message';

  /// Incoming message matching a pattern.
  static const String pmessage = r'pmessage';

  /// Reply to a PING command.
  static const String pong = r'pong';
}

/// Marker interface for all the pub/sub events.
abstract class PubSubEvent {}

/// An event emitted when a command is performed on a channel.
class SubscriptionEvent<K> implements PubSubEvent {
  /// The name of the command that caused this event.
  ///
  /// See [PubSubEventType].
  final String? command;

  /// The name of the channel affected by this event.
  final K channel;

  /// The number of channels that the client is currently subscribed to.
  final int? channelCount;

  /// Creates a [SubscriptionEvent] instance.
  const SubscriptionEvent(this.command, this.channel, this.channelCount);

  @override
  String toString() => '''SubscriptionEvent<$K>: {command=$command,'''
      ''' channel=$channel, channelCount=$channelCount}''';
}

/// An event emitted when a message is published on a channel.
class MessageEvent<K, V> implements PubSubEvent {
  /// The name of the channel where the message was published.
  final K channel;

  /// The message content.
  final V message;

  /// The original pattern matching the name of the channel, if any.
  final K? pattern;

  /// Creates a [MessageEvent] instance.
  const MessageEvent(this.channel, this.message, [this.pattern]);

  @override
  String toString() => '''MessageEvent<$K, $V>: {channel=$channel,'''
      ''' message=$message, pattern=$pattern}''';
}

/// An event emitted in response to a PING command.
class PongEvent<V> implements PubSubEvent {
  /// The message content.
  final V message;

  /// Creates a [PongEvent] instance.
  const PongEvent(this.message);

  @override
  String toString() => 'PongEvent<$V>: $message';
}

/// A client in Publish/Subscribe mode.
///
/// In this mode the only allowed commands are SUBSCRIBE, UNSUBSCRIBE,
/// PSUBSCRIBE, PUNSUBSCRIBE, PING and QUIT.
///
/// The replies to subscription and unsubscription commands along with the
/// published messages are received in the form of events, so that the client
/// can just read a coherent [Stream] of Events.
///
/// The type [K] is used for channel names and the type [V] for messages.
/// Most times, using [String] for both is what you want.
///
/// ```dart
/// final pubsub = await PubSub
///     .connect<String, String>('redis://localhost:6379');
///
/// pubsub // Subscribe to some channels
///    ..subscribe(channel: 'dev.dart')
///    ..psubscribe(pattern: 'dartlang.news.*');
///
/// pubsub.stream.listen(print, onError: print); // Listen for server replies
/// ```
///
/// See [SubscriptionEvent], [MessageEvent] and [PongEvent].
///
/// See `pubsub.dart` in the `example` folder.
class PubSub<K, V> {
  final _PubSubDispatcher<K, V> _dispatcher;

  /// Creates a [PubSub] instance with the given [connection].
  ///
  /// [connect()] provides a more convenient way for creating instances
  /// of this class.
  PubSub(Connection connection)
      : _dispatcher = _PubSubDispatcher<K, V>(connection);

  /// Creates a new connection according to the host and port specified
  /// in the [connectionString].
  ///
  /// Connection string must follow the pattern "redis://{host}:{port}".
  ///
  /// Example: redis://localhost:6379
  ///
  /// Returns a [Future] that will complete with either a [PubSub] once
  /// connected or an error if the connection failed.
  static Future<PubSub<K, V>> connect<K, V>(String connectionString) async {
    final connection = await Connection.connect(connectionString);

    return PubSub<K, V>(connection);
  }

  /// Returns the stream where all events will be published.
  Stream<PubSubEvent> get stream => _dispatcher.stream;

  /// Returns the converter used to serialize/deserialize all the values.
  ///
  /// Custom converters can be registered in order of adding new ones
  /// or replacing the existing ones.
  RedisCodec get codec => _dispatcher.codec;

  /// Subscribes the client to the given [channel] or [channels].
  ///
  /// See https://redis.io/commands/subscribe
  void subscribe({K? channel, Iterable<K> channels = const []}) =>
      _run(<Object?>[r'SUBSCRIBE', channel, ...channels]);

  /// Unsubscribes the client from the given [channel] or [channels], or
  /// from all of them if none is given.
  ///
  /// See https://redis.io/commands/unsubscribe
  void unsubscribe({K? channel, Iterable<K> channels = const []}) =>
      _run(<Object?>[r'UNSUBSCRIBE', channel, ...channels]);

  /// Subscribes the client to the given [pattern] or [patterns].
  ///
  /// See https://redis.io/commands/psubscribe
  void psubscribe({K? pattern, Iterable<K> patterns = const []}) =>
      _run(<Object?>[r'PSUBSCRIBE', pattern, ...patterns]);

  /// Unsubscribes the client from the given [pattern] or [patterns], or
  /// from all of them if none is given.
  ///
  /// See https://redis.io/commands/punsubscribe
  void punsubscribe({K? pattern, Iterable<K> patterns = const []}) =>
      _run(<Object?>[r'PUNSUBSCRIBE', pattern, ...patterns]);

  /// Returns an empty string if no [message] is provided, otherwise returns
  /// a copy of the [message].
  ///
  /// See https://redis.io/commands/ping
  void ping([String? message]) => _run(<Object?>[r'PING', message]);

  /// Closes the connection.
  Future<void> disconnect() => _dispatcher.disconnect();

  void _run(Iterable<Object?> line) {
    final withoutNulls =
        line.where((value) => value != null).map((value) => value!);

    _dispatcher.dispatch(withoutNulls);
  }
}

/// A dispatcher for a client in Publish/Subscribe mode.
class _PubSubDispatcher<K, V> extends ReplyDispatcher {
  final StreamController<PubSubEvent> _controller =
      StreamController<PubSubEvent>.broadcast();

  _PubSubDispatcher(Connection connection) : super(connection);

  Stream<PubSubEvent> get stream => _controller.stream;

  void dispatch(Iterable<Object> line) {
    final bytes = writer.write(line, codec);
    send(bytes);
  }

  @override
  void onReply(Reply reply) {
    if (reply is! ArrayReply) {
      throw RedisException('Unexpected server reply: $reply.');
    }

    final event = _onEvent(reply);
    _controller.add(event);
  }

  @override
  void onErrorReply(ErrorReply reply) {
    _controller.addError(reply);
  }

  @override
  void onError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  void onDone() {
    _controller.close();
  }

  PubSubEvent _onEvent(ArrayReply reply) {
    final array = reply.array;

    final type = codec.decode<String>(array[0]);
    switch (type) {
      case PubSubEventType.message:
        return _onMessage(array);
      case PubSubEventType.pmessage:
        return _onPmessage(array);
      case PubSubEventType.subscribe:
      case PubSubEventType.unsubscribe:
      case PubSubEventType.psubscribe:
      case PubSubEventType.punsubscribe:
        return _onSubscription(array);
      case PubSubEventType.pong:
        return _onPong(array);
    }

    throw RedisException('Unexpected server reply type "$type".');
  }

  PubSubEvent _onSubscription(List<Reply> array) {
    final command = codec.decode<String>(array[0]);
    final channel = codec.decode<K>(array[1]);
    final channelCount = codec.decode<int>(array[2]);

    return SubscriptionEvent<K>(command, channel, channelCount);
  }

  PubSubEvent _onMessage(List<Reply> array) {
    final channel = codec.decode<K>(array[1]);
    final message = codec.decode<V>(array[2]);

    return MessageEvent<K, V>(channel, message);
  }

  PubSubEvent _onPmessage(List<Reply> array) {
    final pattern = codec.decode<K>(array[1]);
    final channel = codec.decode<K>(array[2]);
    final message = codec.decode<V>(array[3]);

    return MessageEvent<K, V>(channel, message, pattern);
  }

  PubSubEvent _onPong(List<Reply> array) {
    final message = codec.decode<V>(array[1]);

    return PongEvent<V>(message);
  }
}
