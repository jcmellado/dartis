# Redis client for Dart

[![Build Status](https://travis-ci.org/jcmellado/dartis.svg?branch=master)](https://travis-ci.org/jcmellado/dartis)
[![Coverage Status](https://coveralls.io/repos/github/jcmellado/dartis/badge.svg?branch=master)](https://coveralls.io/github/jcmellado/dartis?branch=master)

## Features
- Type-safe commands
- Pipelining
- Fire and forget
- Publish/Subscribe
- Monitor mode
- Inline commands
- Transactions
- Lua scripting
- Custom serializers/deserializers
- Custom commands for building Modules

## Usage
Create a connection:

```dart
final client = await Client.connect('redis://localhost:6379');
```

Get a type-safe view of the available Redis Commands:
```dart
final commands = client.asCommands<String, String>();
```

Run some commands:
```dart
await commands.set('key', 'value');

final value = await commands.get('key');

print(value);
```

Disconnect:
```dart
await client.disconnect();
```

### Connection String
Connection string must follow the following pattern:

```
redis://{host}:{port}
```

Example:

```
redis://localhost:6379
```

## Client Modes
Clients can work in the following modes:
- Online
- Publish/Subscribe
- Inline commands
- Monitor

### Online
In this mode the client can send any command to the Redis server.

```dart
// Connect
final client = await Client.connect('redis://localhost:6379');

// Run some commands
final commands = client.asCommands<String, String>();

final result = await commands.ping();
print(result);

// Disconnect
await client.disconnect();
```

See `client.dart` in the `example` folder.

### Publish/Subscribe
In this mode the only allowed commands are `subscribe`, `unsubscribe`, `psubscribe`, `punsubscribe`, `ping` and `quit`.

The replies to subscription and unsubscription commands along with the published messages are received in the form of events, so that the client can just read a coherent `Stream` of events.

```dart
final pubsub = await PubSub.connect<String, String>('redis://localhost:6379');

// Subscribe to some channels and patterns
pubsub
  ..subscribe(channel: 'dev.dart')
  ..psubscribe(pattern: 'dartlang.news.*');

// Listen for server replies
pubsub.stream.listen(print, onError: print);
```

See `pubsub.dart` in the `example` folder.

If the Redis server is protected with a password then a client connection must be created in order to run the Redis AUTH command.

```dart
final client = await Client.connect('redis://localhost:6379');

final commands = client.asCommands<String, String>();

await commands.auth('password');

// Create the PubSub object using the client connection
final broker = PubSub<String, String>(client.connection);
```

### Inline Commands
In this mode the commands are sent to the server using the "inline command" format. Ideal to use in interactive sessions, like a Telnet session.

```dart
final terminal = await Terminal.connect('redis://localhost:6379');

// Run some commands
terminal.run('PING\r\n'.codeUnits);

// Listen for server replies
terminal.stream.listen(print);
```

Note that in this mode the commands are just lists of bytes with a trailing `\r\n`.

See `terminal.dart` in the `example` folder.

### Monitor
In this mode the client receives all the commands procesed by the Redis server. Useful for debugging.

```dart
final monitor = await Monitor.connect('redis://localhost:6379');

// Start the monitor mode
monitor.start();

// Listen for server replies
monitor.stream.listen(print);
```

In this mode the client can not run any command.

See `monitor.dart` in the `example` folder.

## Commands
The method `asCommands<K, V>` of the client returns a type-safe view of the available Redis Commands. `K` is the type to be used for Redis keys and `V` for values. Most times, using `String` for keys and values is what you want:

```dart
final commands = client.asCommands<String, String>();
```

However, it's correct to call this method several times in order to get views with different parameterized types:

```dart
final strings = client.asCommands<String, String>();
final bytes = client.asCommands<String, List<int>>();

String title = await strings.get('book:24902:title');
List<int> cover = await bytes.get('book:24902:cover');

// ERROR String author = await bytes.get('book:24092:author');
```

Keep in mind that Redis stores sequences of bytes, not just `String`s.

## Pipelining
Pipeling is used in order to send multiple commands to the server in only one call, instead of doing one call for each command.

In this mode the client stores locally all the commands without sending them to the server until the `flush` method is called.

```dart
// Start pipeline
client.pipeline();

// Run some commands
commands.incr('product:9238:views').then(print);
commands.incr('product:1725:views').then(print);
commands.incr('product:4560:views').then(print);

// Flush pipeline
client.flush();
```

The method `flush` returns a list of `Future`s that can be used for waiting the completion of all the commands.

```dart
// Start pipeline
client.pipeline();

// Run some commands
commands
  ..incr('product:9238:views')
  ..incr('product:1725:views')
  ..incr('product:4560:views');

// Flush pipeline
final futures = client.flush();

// Wait for all the Futures
await Future.wait<Object>(futures).then(print);
```

Please note that in this mode `await` can not be used for waiting the result of the execution of each command because the returned `Future`s will not be completed until `flush` was called.

## Fire and Forget
In this mode the server doesn't sent replies for the commands, so the client doesn't need to wait for them.

This mode is started running the `clientReply` command with `ReplyMode.off` or `ReplyMode.skip`.

In this mode the `Future`s are immediately completed with `null`.

```dart
// Discard all the server replies
await commands.clientReply(ReplyMode.off);

// Run some commands
await commands.ping().then(print); // null
await commands.ping().then(print); // null
await commands.ping().then(print); // null
```

The following modes are available:
- `ReplyMode.off`: In this mode the server will not reply to client commands.
- `ReplyMode.skip`: In this mode the server will skip the reply of command immediately after it.
- `ReplyMode.on`: In this mode the server will return a reply to every command.

## Transactions
Redis allows to group commands together so that they are executed as a single transaction.

A transaction begins running the `multi` command, ends running the `exec` command, and can be aborted running the `discard` command.

```dart
// Start transaction
await commands.multi();

// Run some commands
commands.set(key, 1).then(print);
commands.incr(key).then(print);

// End transaction
await commands.exec(); // Or abort: commands.discard()
```

The `watch` command can be used for perfoming optimistic lockings over some keys. A transaction will fail if the "watched" keys are modified by another client.

```dart
// Watch
await commands.watch(key: key);

// Start transaction
await commands.multi();

// Run some commands
commands.set(key, 1).then(print);
commands.incr(key).then(print);

// End transaction
await commands.exec();
```

Please note that in this mode `await` can not be used for waiting the result of the execution of each command because the returned `Future`s will not be completed until `exec` or `discard` were called.

### Caveats
Don't run the `clientReply` command inside a transaction. If the "fire and forget" mode is de/activated inside a transaction then the client could go out of sync with the server.

Redis transactions are deprecated in favor of Lua scripting.

## Lua scripting
Redis allows to run Lua scripts in the server.

Scripts can be executed with the `eval` and `evalsha` commands.

```dart
// Evaluate
await commands.eval<void>(
    'return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}',
    keys: [key1, key2],
    args: ['first', 'second']);
```

The result of a script can be anything. It can be ignored, like in the above example, or it can be mapped to a most useful thing.

```dart
// Maps a list of server replies to a list of Strings
class _Mapper implements Mapper<List<String>> {
  @override
  List<String> map(Reply reply, RedisCodec codec) =>
    codec.decode<List<String>>(reply);
}

...

// Evaluate with a mapper
final results = await commands.eval<List<String>>(
    'return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}',
    keys: [key1, key2],
    args: ['first', 'second'],
    mapper: _Mapper());

print(results); // ['key1', 'key2', 'first', 'second']
```

## Custom Serializers/Deserializers
Encoders are used for serializing all the values sent to Redis. They convert instances of any type to list of bytes. Encoders for types `int`, `double`, `String` and `List<int>` are registered by default. UTF-8 is used for `String`s.

Custom encoders can be written extending from `Encoder` or `Converter`.

Example:

An encoder that encodes instances of `DateTime` to lists of bytes:

```dart
class DateTimeEncoder extends Encoder<DateTime> {
  @override
  List<int> convert(DateTime value, [RedisCodec codec]) =>
      utf8.encode(value.toString());
}
```

Decoders are used for deserializing all the replies received from Redis. They convert list of bytes to instances of any type, and arrays of server replies to lists of instances of any type. Decoders for types `int`, `double`, `String`, `List<int>`, `List<double>`, `List<Sring>` and `List<List<int>>` are registered by default. UTF-8 is used for `String`s.

Custom decoders can be written extending from `Decoder` or `Converter`.

Example:

A decoder that decodes lists of bytes to instances of `DateTime`.

```dart
class DateTimeDecoder extends Decoder<SingleReply, DateTime> {
  @override
  DateTime convert(SingleReply value, [RedisCodec codec]) =>
      value.bytes == null ? null : DateTime.parse(utf8.decode(value.bytes));
}
```

Custom encoders and decoders can be registered using the `codec` member of the client:

```dart
client.codec.register(
    encoder: DateTimeEncoder(),
    decoder: DateTimeDecoder());
```

## Custom Commands
Custom sets of commands can be written extending from `ModuleBase`. This class exposes the method `run` that sent to Redis any given line of commands, so it can be used for implementing the API of any Redis module.

Example:

A module that exposes a `HELLO name` command:

```dart
class HelloModule extends ModuleBase {

  HelloModule(Client client) : super(client);

  Future<String> hello(String name) => run<String>(<Object>[r'HELLO', name]);
}
```

Usage:

```dart
final module = HelloModule(client);

final message = await module.hello('World!');

print(message);
```

Note that standard Redis commands can be rewritten too for building custom interfaces.

Example:

An even more type-safe set of commands:

```dart
class TypedCommands<K> extends ModuleBase {

  TypedCommands(Client client) : super(client);

  Future<void> set<R>(K key, R value) => run<void>(<Object>[r'SET', key, value]);

  Future<R> get<R>(K key) => run<R>(<Object>[r'GET', key]);
}
```

Usage:

```dart
final commands = TypedCommands<String>(client);

await commands.set<String>('name', 'Bob');
await commands.set<int>('age', 29);
await commands.set<List<int>>('photo', png);

final name = await commands.get<String>('name');
final age = await commands.get<int>('age');
final photo = await commands.get<List<int>>('photo');
```

Note that if a module works with a custom structure, like a record with multiple fields, then custom encoders and decoders should be used.

## Log
The logging package is used for logging messages through a custom logger named 'dartis'.

Here is a simple logging configuration that logs all messages via `print`:

```dart
import 'package:logging/logging.dart';

...

Logger.root.level = Level.INFO;
Logger.root.onRecord.listen((LogRecord record) {
  print('${record.time} ${record.level.name} ${record.loggerName} ${record.message}');
});
```

Set the log level according your needs. Most times, `INFO` is what you want. `ALL` is good for filling issues.

## Testing
Dependencies of this packages can installed with `pub get` and test cases can
be run with `pub run test`. These test cases requires a redis running on
`localhost:6379`, for local development this can be created with docker:

 * `docker run --rm -p 127.0.0.1:6379:6379 redis`

This starts a container running redis and exposes port `6379` localhost, when
killed using `ctrl+c` the container will be deleted.
