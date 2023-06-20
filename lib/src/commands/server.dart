// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:collection' show LinkedHashMap;

import '../command.dart';
import '../exception.dart';
import '../protocol.dart';

/// A convenient shared mapper for the COMMAND command.
const CommandMapper commandMapper = CommandMapper();

/// A convenient shared mapper for the CLIENT KILL command.
const ClientKillMapper clientKillMapper = ClientKillMapper();

/// A convenient shared mapper for the CLIENT LIST command.
const ClientListMapper clientListMapper = ClientListMapper();

/// A convenient shared mapper for the CONFIG GET command.
const ConfigMapper configMapper = ConfigMapper();

/// A convenient shared mapper for the MEMORY STATS command.
const MemoryStatsMapper memoryStatsMapper = MemoryStatsMapper();

/// A convenient shared mapper for the ROLE command.
const RoleMapper roleMapper = RoleMapper();

/// A convenient shared mapper for the SLOWLOG command.
const SlowLogMapper slowLogMapper = SlowLogMapper();

/// A convenient shared mapper for the TIMER command.
const TimeMapper timeMapper = TimeMapper();

/// Redis server commands.
abstract class ServerCommands<K> {
  /// Asynchronously rewrites the append-only file.
  ///
  /// Returns an informative text about the started background process.
  ///
  /// See https://redis.io/commands/bgrewriteaof
  Future<String> bgrewriteaof();

  /// Asynchronously saves the dataset to disk.
  ///
  /// Returns an informative text about the started background process.
  ///
  /// See https://redis.io/commands/bgsave
  Future<String> bgsave();

  /// Gets the current connection name.
  ///
  /// See https://redis.io/commands/client-getname
  Future<String?> clientGetname();

  /// Closes a given client connection.
  ///
  /// Returns the number of clients killed.
  ///
  /// See https://redis.io/commands/client-kill
  Future<int?> clientKill(
      {String? ipPort, Iterable<ClientFilter> filters = const []});

  /// Returns the list of client connections.
  ///
  /// See https://redis.io/commands/client-list
  Future<List<Map<String, String>>> clientList();

  /// Suspends all the Redis clients for the specified amount of time
  /// (in milliseconds).
  ///
  /// See https://redis.io/commands/client-pause
  Future<void> clientPause(int timeout);

  /// Instructs the server whether to reply to commands.
  ///
  /// See https://redis.io/commands/client-reply
  Future<void> clientReply(ReplyMode mode);

  /// Sets the current connection name.
  ///
  /// See https://redis.io/commands/client-setname
  Future<void> clientSetname(String connectionName);

  /// Returns details about all available Redis commands.
  ///
  /// See https://redis.io/commands/command
  Future<List<ClientCommand?>> command();

  /// Returns the total number of available Redis commands.
  ///
  /// See https://redis.io/commands/command-count
  Future<int> commandCount();

  /// Extracts keys from a given full Redis command.
  ///
  /// See https://redis.io/commands/command-getkeys
  Future<List<K>> commandGetkeys(List<Object> commandLine);

  /// Returns details about multiple Redis commands.
  ///
  /// See https://redis.io/commands/command-info
  Future<List<ClientCommand?>> commandInfo(
      {String? commandName, Iterable<String> commandNames = const []});

  /// Gets the value of a configuration [parameter].
  ///
  /// See https://redis.io/commands/config-get
  Future<Map<String?, String?>> configGet(String parameter);

  /// Resets the statistics reported by Redis using the `INFO` command.
  ///
  /// See https://redis.io/commands/config-resetstat
  Future<void> configResetstat();

  /// Rewrites the `redis.conf` file the server was started with, applying
  /// the minimal changes needed to make it reflect the configuration
  /// currently used by the server.
  ///
  /// See https://redis.io/commands/config-rewrite
  Future<void> configRewrite();

  /// Sets a configuration [parameter] to the given [value].
  ///
  /// See https://redis.io/commands/config-set
  Future<void> configSet(String parameter, String value);

  /// Returns the number of keys in the currently-selected database.
  ///
  /// See https://redis.io/commands/dbsize
  Future<int> dbsize();

  /// Gets debugging information about a [key].
  ///
  /// See https://redis.io/commands/debug-object
  Future<String> debugObject(K key);

  /// Performs an invalid memory access that crashes Redis.
  ///
  /// See https://redis.io/commands/debug-segfault
  Future<void> debugSegfault();

  /// Removes all the keys from all the existing databases.
  ///
  /// See https://redis.io/commands/flushall
  Future<void> flushall({bool asynchronously = false});

  /// Removes all the keys from the currently selected database.
  ///
  /// See https://redis.io/commands/flushdb
  Future<void> flushdb({bool asynchronously = false});

  /// Returns information and statistics about the server.
  ///
  /// See https://redis.io/commands/info
  Future<String> info([InfoSection? section]);

  /// Returns the UNIX time of the last DB save executed with success.
  ///
  /// See https://redis.io/commands/lastsave
  Future<int> lastsave();

  /// Returns different memory-related issues that the Redis server
  /// experiences, and advises about possible remedies.
  ///
  /// See https://redis.io/commands/memory-doctor
  Future<String> memoryDoctor();

  /// Returns a helpful text describing the different subcommands.
  ///
  /// See https://redis.io/commands/memory-help
  Future<List<String>> memoryHelp();

  /// Returns an internal statistics report from the memory allocator.
  ///
  /// See https://redis.io/commands/memory-malloc-stats
  Future<String> memoryMallocStats();

  /// Attempts to purge dirty pages so these can be reclaimed by the allocator.
  ///
  /// See https://redis.io/commands/memory-purge
  Future<void> memoryPurge();

  /// Returns memory usage details.
  ///
  /// See https://redis.io/commands/memory-stats
  Future<Map<String?, Object?>> memoryStats();

  /// Returns the number of bytes that a [key] and its value require to be
  /// stored in RAM.
  ///
  /// See https://redis.io/commands/memory-usage
  Future<int?> memoryUsage(K key, {int? count});

  /// Returns the role of the instance in the context of replication.
  ///
  /// See https://redis.io/commands/role
  Future<Role> role();

  /// Synchronously saves the dataset to disk.
  ///
  /// See https://redis.io/commands/save
  Future<void> save();

  /// Synchronously saves the dataset to disk and then shut down the server.
  ///
  /// See https://redis.io/commands/shutdown
  Future<void> shutdown([ShutdownMode? mode]);

  /// Makes the server a slave of another instance, or promote it as master.
  ///
  /// See https://redis.io/commands/slaveof
  Future<void> slaveof(String host, String port);

  /// Returns the entries in the slow log.
  ///
  /// See [slowlogLen] and [slowlogReset].
  ///
  /// See https://redis.io/commands/slowlog
  Future<List<SlowLogEntry>> slowlogGet({int? count});

  /// Returns the length of the slow log.
  ///
  /// See [slowlogGet] and [slowlogReset].
  ///
  /// See https://redis.io/commands/slowlog
  Future<int> slowlogLen();

  /// Resets the slow log.
  ///
  /// See [slowlogGet] and [slowlogLen].
  ///
  /// See https://redis.io/commands/slowlog
  Future<void> slowlogReset();

  /// Returns the current server time.
  ///
  /// See https://redis.io/commands/time
  Future<ServerTime> time();
}

/// Allowed client types for the CLIENT KILL command.
class ClientType {
  /// The name of the type.
  final String name;

  const ClientType._(this.name);

  /// Normal.
  static const ClientType normal = ClientType._(r'normal');

  /// Master.
  static const ClientType master = ClientType._(r'master');

  /// Slave.
  static const ClientType slave = ClientType._(r'slave');

  /// Pub/Sub.
  static const ClientType pubsub = ClientType._(r'pubsub');

  @override
  String toString() => 'ClientType: $name';
}

/// Allowed sections for the INFO command.
class InfoSection {
  /// The name of the section.
  final String name;

  const InfoSection._(this.name);

  /// General information about the Redis server.
  static const InfoSection server = InfoSection._(r'server');

  /// Client connections section.
  static const InfoSection clients = InfoSection._(r'clients');

  /// Memory consumption related information.
  static const InfoSection memory = InfoSection._(r'memory');

  /// RDB and AOF related information.
  static const InfoSection persistence = InfoSection._(r'persistence');

  /// General statistics.
  static const InfoSection stats = InfoSection._(r'stats');

  /// Master/slave replication information.
  static const InfoSection replication = InfoSection._(r'replication');

  /// CPU consumption statistics.
  static const InfoSection cpu = InfoSection._(r'cpu');

  /// Redis command statistics.
  static const InfoSection commandstats = InfoSection._(r'commandstats');

  /// Redis Cluster section.
  static const InfoSection cluster = InfoSection._(r'cluster');

  /// Database related statistics
  static const InfoSection keyspace = InfoSection._(r'keyspace');

  /// Return all sections.
  static const InfoSection all = InfoSection._(r'all');

  @override
  String toString() => 'InfoSection: $name';
}

/// Allowed modes for the SHUTDOWN command.
class ShutdownMode {
  /// The name of the mode.
  final String name;

  const ShutdownMode._(this.name);

  /// Will prevent a DB saving operation even if one or more save points
  /// are configured.
  static const ShutdownMode noSave = ShutdownMode._(r'NOSAVE');

  /// Will force a DB saving operation even if no save points are configured.
  static const ShutdownMode save = ShutdownMode._(r'SAVE');

  @override
  String toString() => 'ShutdownMode: $name';
}

/// A client filter.
class ClientFilter {
  /// The client ID.
  final int? clientId;

  /// The client type.
  final ClientType? type;

  /// The ip:port.
  final String? ipPort;

  /// The "skip me" flag.
  final bool skipMe;

  /// Creates a [ClientFilter] instance.
  const ClientFilter(
      {this.clientId, this.type, this.ipPort, this.skipMe = true});

  @override
  String toString() => '''ClientFilter: {clientId=$clientId, type=$type,'''
      ''' ipPort=$ipPort, skipMe=$skipMe}''';
}

/// A client command.
class ClientCommand {
  /// The name.
  final String? name;

  /// The arity specification.
  final int? arity;

  /// The flags.
  final List<String>? flags;

  /// The position of first key in argument list.
  final int? firstKeyPosition;

  /// The position of last key in argument list.
  final int? lastKeyPosition;

  /// Key sep count for locating repeating keys.
  final int? keyStepCount;

  /// Creates a [ClientCommand] instance.
  const ClientCommand(this.name, this.arity, this.flags, this.firstKeyPosition,
      this.lastKeyPosition, this.keyStepCount);

  @override
  String toString() => '''ClientCommand: {name=$name, arity=$arity,'''
      ''' flags=$flags, firstKeyPosition=$firstKeyPosition,'''
      ''' lastKeyPosition=$lastKeyPosition, keyStepCount=$keyStepCount}''';
}

/// Server time.
class ServerTime {
  /// The UNIX timestamp in seconds.
  final int? timestamp;

  /// The amount of microseconds already elapsed in the current second.
  final int? microseconds;

  /// Creates a [ServerTime] instance.
  const ServerTime(this.timestamp, this.microseconds);

  @override
  String toString() => '''ServerTime: {timestamp=$timestamp,'''
      ''' microseconds=$microseconds}''';
}

/// A slave server.
class Slave {
  /// The slave IP.
  final String? ip;

  /// The slave port.
  final int? port;

  /// The last acknowledged replication offset.
  final int? offset;

  /// Creates a [Slave] instance.
  const Slave(this.ip, this.port, this.offset);

  @override
  String toString() => 'Slave: {ip=$ip, port=$port, offset=$offset}';
}

/// Master instance details.
class MasterRole {
  /// The current master replication offset.
  final int? offset;

  /// The connected slaves.
  final List<Slave>? slaves;

  /// Creates a [MasterRole] instance.
  const MasterRole(this.offset, this.slaves);

  @override
  String toString() => 'MasterRole: {offset=$offset, slaves=$slaves}';
}

/// Slave instance details.
class SlaveRole {
  /// The IP of the master.
  final String? ip;

  /// The port number of the master.
  final int? port;

  /// The state of the replication from the point of view of the master.
  final String? state;

  /// The amount of data received from the slave so far.
  final int? received;

  /// Creates a [SlaveRole] instance.
  const SlaveRole(this.ip, this.port, this.state, this.received);

  @override
  String toString() => '''SlaveRole: {ip=$ip, port=$port, state=$state,'''
      ''' received=$received}''';
}

/// Sentinel instance details.
class SentinelRole {
  /// The master names monitored by the Sentinel instance.
  final List<String>? masters;

  /// Creates a [SentinelRole] instance.
  const SentinelRole(this.masters);

  @override
  String toString() => 'SentinelRole: $masters';
}

/// The role of an instance.
class Role {
  /// The type of the role.
  final String? type;

  /// The instance details for master instances.
  final MasterRole? master;

  /// The instance details for slave instances.
  final SlaveRole? slave;

  /// The instance details for Sentinel instances.
  final SentinelRole? sentinel;

  /// Creates a [Role] instance.
  const Role(this.type, {this.master, this.slave, this.sentinel});

  @override
  String toString() => '''Role: {type=$type, master=$master,'''
      ''' slave=$slave, sentinel=$sentinel}''';
}

/// A slow log entry.
class SlowLogEntry {
  /// The id.
  final int? id;

  /// The unix timestamp at which the logged command was processed.
  final int? timestamp;

  /// The amount of time needed for its execution, in microseconds.
  final int? responseTime;

  /// The arguments of the command.
  final List<String>? args;

  /// Client IP address and port
  final String? clientIpPort;

  /// Client name.
  final String? clientName;

  /// Creates a [SlowLogEntry] instance.
  const SlowLogEntry(this.id, this.timestamp, this.responseTime, this.args,
      this.clientIpPort, this.clientName);

  @override
  String toString() => '''SlowLogEntry: {id=$id, timestamp=$timestamp,'''
      ''' responseTime=$responseTime, args=$args,'''
      ''' clientIpPort=$clientIpPort, clientName=$clientName}''';
}

/// A mapper for the COMMAND and COMMAND INFO commands.
class CommandMapper implements Mapper<List<ClientCommand?>> {
  /// Creates a [CommandMapper] instance.
  const CommandMapper();

  @override
  List<ClientCommand?> map(covariant ArrayReply reply, RedisCodec codec) =>
      reply.array
          .map((value) => value.value == null
              ? null
              : _mapCommand(value as ArrayReply, codec))
          .toList();

  /// Maps a [reply] to a [ClientCommand] instance.
  ClientCommand _mapCommand(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final name = codec.decode<String>(array[0]);
    final arity = codec.decode<int>(array[1]);
    final flags = codec.decode<List<String>>(array[2]);
    final firstKeyPosition = codec.decode<int>(array[3]);
    final lastKeyPosition = codec.decode<int>(array[4]);
    final keyStepCount = codec.decode<int>(array[5]);

    return ClientCommand(
        name, arity, flags, firstKeyPosition, lastKeyPosition, keyStepCount);
  }
}

/// A mapper for the CLIENT KILL command.
class ClientKillMapper implements Mapper<int> {
  /// Creates a [ClientKillMapper] instance.
  const ClientKillMapper();

  @override
  int map(Reply reply, RedisCodec codec) {
    if (reply is StringReply) {
      return 1;
    }

    return codec.decode<int>(reply);
  }
}

/// A maper for the CLIENT LIST command.
class ClientListMapper implements Mapper<List<Map<String, String>>> {
  /// Creates a [ClientListMapper] instance.
  const ClientListMapper();

  @override
  List<Map<String, String>> map(Reply reply, RedisCodec codec) {
    final clients = <Map<String, String>>[];

    final raw = codec.decode<String>(reply);
    final lines = raw.split('\n');

    for (final line in lines.where((line) => line.isNotEmpty)) {
      final client = _mapClient(line);

      clients.add(client);
    }

    return clients;
  }

  Map<String, String> _mapClient(String line) {
    // ignore: prefer_collection_literals
    final map = LinkedHashMap<String, String>();

    final entries = line.split(' ');
    for (final entry in entries.where((entry) => entry.isNotEmpty)) {
      final parts = entry.split('=');

      map[parts[0]] = parts[1];
    }

    return map;
  }
}

/// A mapper for the CONFIG GET command.
class ConfigMapper implements Mapper<Map<String?, String?>> {
  /// Creates a [ConfigMapper] instance.
  const ConfigMapper();

  @override
  Map<String?, String?> map(covariant ArrayReply reply, RedisCodec codec) {
    // ignore: prefer_collection_literals
    final hash = LinkedHashMap<String?, String?>();

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final key = codec.decode<String>(array[i]);
      final value = codec.decode<String>(array[i + 1]);

      hash[key] = value;
    }

    return hash;
  }
}

/// A mapper for the MEMORY STATS command.
class MemoryStatsMapper implements Mapper<Map<String?, Object?>> {
  /// Creates a [MemoryStatsMapper] instance.
  const MemoryStatsMapper();

  @override
  Map<String?, Object?> map(covariant ArrayReply reply, RedisCodec codec) {
    // ignore: prefer_collection_literals
    final stats = LinkedHashMap<String?, Object?>();

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final key = codec.decode<String>(array[i]);

      final raw = array[i + 1];
      final value =
          raw is ArrayReply ? map(raw, codec) : codec.decode<String>(raw);

      stats[key] = value;
    }

    return stats;
  }
}

/// A mapper for the ROLE command.
class RoleMapper implements Mapper<Role> {
  /// Creates a [RoleMapper] instance.
  const RoleMapper();

  @override
  Role map(covariant ArrayReply reply, RedisCodec codec) {
    final type = codec.decode<String>(reply.array[0]);

    MasterRole? master;
    SlaveRole? slave;
    SentinelRole? sentinel;

    switch (type) {
      case 'master':
        master = _mapMaster(reply, codec);
        break;
      case 'slave':
        slave = _mapSlave(reply, codec);
        break;
      case 'sentinel':
        sentinel = _mapSentinel(reply, codec);
        break;
      default:
        throw RedisException('Unexpected role "$type".');
    }

    return Role(type, master: master, slave: slave, sentinel: sentinel);
  }

  /// Maps a [reply] to a [MasterRole] instance.
  MasterRole _mapMaster(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final offset = codec.decode<int>(array[1]);
    final slaves = _mapSlaves(array[2] as ArrayReply, codec);

    return MasterRole(offset, slaves);
  }

  /// Maps a [reply] to a list of [Slave] instances.
  List<Slave> _mapSlaves(ArrayReply reply, RedisCodec codec) => reply.array
      .map((value) => _mapSlaveItem(value as ArrayReply, codec))
      .toList();

  /// Maps a [reply] to a [Slave] instance.
  Slave _mapSlaveItem(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final ip = codec.decode<String>(array[0]);
    final port = codec.decode<int>(array[1]);
    final offset = codec.decode<int>(array[2]);

    return Slave(ip, port, offset);
  }

  /// Maps a [reply] to a [SlaveRole] instance.
  SlaveRole _mapSlave(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final ip = codec.decode<String>(array[1]);
    final port = codec.decode<int>(array[2]);
    final state = codec.decode<String>(array[3]);
    final received = codec.decode<int>(array[4]);

    return SlaveRole(ip, port, state, received);
  }

  /// Maps a [reply] to a [SentinelRole] instance.
  SentinelRole _mapSentinel(ArrayReply reply, RedisCodec codec) {
    final masters = codec.decode<List<String>>(reply.array[1]);

    return SentinelRole(masters);
  }
}

/// A mapper for the SLOWLOG command.
class SlowLogMapper implements Mapper<List<SlowLogEntry>> {
  /// Creates a [SlowLogMapper] instance.
  const SlowLogMapper();

  @override
  List<SlowLogEntry> map(covariant ArrayReply reply, RedisCodec codec) =>
      reply.array
          .map((value) => _mapEntry(value as ArrayReply, codec))
          .toList();

  /// Maps a [reply] to a [SlowLogEntry] instance.
  SlowLogEntry _mapEntry(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final id = codec.decode<int>(array[0]);
    final timestamp = codec.decode<int>(array[1]);
    final responseTime = codec.decode<int>(array[2]);
    final args = codec.decode<List<String>>(array[3]);

    String? clientIpPort;
    String? clientName;
    if (array.length > 4) {
      clientIpPort = codec.decode<String>(array[4]);
      clientName = codec.decode<String>(array[5]);
    }

    return SlowLogEntry(
        id, timestamp, responseTime, args, clientIpPort, clientName);
  }
}

/// A mapper for the TIME command.
class TimeMapper implements Mapper<ServerTime> {
  /// Creates a [TimeMapper] instance.
  const TimeMapper();

  @override
  ServerTime map(covariant ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final timestamp = codec.decode<int>(array[0]);
    final microseconds = codec.decode<int>(array[1]);

    return ServerTime(timestamp, microseconds);
  }
}
