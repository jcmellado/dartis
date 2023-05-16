// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../commands.dart';
import 'command.dart';
import 'module.dart';

/// Redis commands.
class Commands<K extends Object, V extends Object> extends ModuleBase
    implements
        ClusterCommands<K>,
        ConnectionCommands,
        GeoCommands<K, V>,
        HashCommands<K, V>,
        HyperLogLogCommands<K, V>,
        KeyCommands<K, V>,
        ListCommands<K?, V?>,
        PubSubCommands<K?, V>,
        ScriptingCommands<K>,
        ServerCommands<K>,
        SetCommands<K, V>,
        SortedSetCommands<K?, V?>,
        StreamCommands<K?, V?>,
        StringCommands<K, V>,
        TransactionCommands<K> {
  /// Creates a [Commands] instance.
  Commands(CommandRunner runner) : super(runner);

  // Cluster.

  @override
  Future<void> clusterAddslots({int? slot, Iterable<int> slots = const []}) =>
      run<void>(<Object?>[r'CLUSTER', r'ADDSLOTS', slot, ...slots]);

  @override
  Future<int?> clusterCountFailureReports(String nodeId) =>
      run<int?>(<Object>[r'CLUSTER', r'COUNT-FAILURE-REPORTS', nodeId]);

  @override
  Future<int?> clusterCountkeysinslot(int slot) =>
      run<int?>(<Object>[r'CLUSTER', r'COUNTKEYSINSLOT', slot]);

  @override
  Future<void> clusterDelslots({int? slot, Iterable<int> slots = const []}) =>
      run<void>(<Object?>[r'CLUSTER', r'DELSLOTS', slot, ...slots]);

  @override
  Future<void> clusterFailover([ClusterFailoverMode? mode]) =>
      run<void>(<Object?>[r'CLUSTER', r'FAILOVER', mode?.name]);

  @override
  Future<void> clusterForget(String nodeId) =>
      run<void>(<Object>[r'CLUSTER', r'FORGET', nodeId]);

  @override
  Future<List<K>?> clusterGetkeysinslot(int slot, int count) =>
      run<List<K>?>(<Object>[r'CLUSTER', r'GETKEYSINSLOT', slot, count]);

  @override
  Future<Map<String, String>?> clusterInfo() =>
      run<Map<String, String>?>(<Object>[r'CLUSTER', r'INFO'],
          mapper: clusterInfoMapper);

  @override
  Future<int?> clusterKeyslot(K key) =>
      run<int?>(<Object?>[r'CLUSTER', r'KEYSLOT', key]);

  @override
  Future<void> clusterMeet(String ip, int port) =>
      run<void>(<Object>[r'CLUSTER', r'MEET', ip, port]);

  @override
  Future<String?> clusterNodes() =>
      run<String?>(<Object>[r'CLUSTER', r'NODES']);

  @override
  Future<void> clusterReplicate(String nodeId) =>
      run<void>(<Object>[r'CLUSTER', r'REPLICATE', nodeId]);

  @override
  Future<void> clusterReset([ClusterResetMode? mode]) =>
      run<void>(<Object?>[r'CLUSTER', r'RESET', mode?.name]);

  @override
  Future<void> clusterSaveconfig() =>
      run<void>(<Object>[r'CLUSTER', r'SAVECONFIG']);

  @override
  Future<void> clusterSetConfigEpoch(int configEpoch) =>
      run<void>(<Object>[r'CLUSTER', r'SET-CONFIG-EPOCH', configEpoch]);

  @override
  Future<void> clusterSetslot(int slot, ClusterSetslotCommand command,
          {String? nodeId}) =>
      run<void>(<Object?>[r'CLUSTER', r'SETSLOT', slot, command.name, nodeId]);

  @override
  Future<String?> clusterSlaves(String nodeId) =>
      run<String?>(<Object>[r'CLUSTER', r'SLAVES', nodeId]);

  @override
  Future<List<ClusterSlotRange>?> clusterSlots() =>
      run<List<ClusterSlotRange>?>(<Object>[r'CLUSTER', r'SLOTS'],
          mapper: clusterSlotRangeMapper);

  @override
  Future<void> readonly() => run<void>(<Object>[r'READONLY']);

  @override
  Future<void> readwrite() => run<void>(<Object>[r'READWRITE']);

  // Connection.

  @override
  Future<void> auth(String password) => run<void>(<Object>[r'AUTH', password]);

  @override
  Future<String?> echo(String? message) =>
      run<String?>(<Object?>[r'ECHO', message]);

  @override
  Future<String?> ping([String? message]) =>
      run(<Object>[r'PING', if (message != null) message]);

  @override
  Future<void> quit() => run<void>(<Object>[r'QUIT']);

  @override
  Future<void> select(int index) => run<void>(<Object>[r'SELECT', index]);

  @override
  Future<void> swapdb(int index1, int index2) =>
      run<void>(<Object>[r'SWAPDB', index1, index2]);

  // Geo.

  @override
  Future<int?> geoadd(K key,
          {GeoItem<V>? item, Iterable<GeoItem<V>> items = const []}) =>
      run<int?>(<Object?>[
        r'GEOADD',
        key,
        ..._expandGeoItem(item),
        ...items.expand(_expandGeoItem)
      ]);

  List<Object?> _expandGeoItem(GeoItem<V>? item) => item == null
      ? <Object?>[]
      : <Object?>[item.position.longitude, item.position.latitude, item.member];

  @override
  Future<double?> geodist(K key, V member1, V member2, {GeoUnit? unit}) =>
      run<double?>(<Object?>[r'GEODIST', key, member1, member2, unit?.name]);

  @override
  Future<List<String?>?> geohash(K key,
          {V? member, Iterable<V> members = const []}) =>
      run<List<String?>?>(<Object?>[r'GEOHASH', key, member, ...members]);

  @override
  Future<List<GeoPosition?>?> geopos(K key,
          {V? member, Iterable<V> members = const []}) =>
      run<List<GeoPosition?>?>(<Object?>[r'GEOPOS', key, member, ...members],
          mapper: geoPositionMapper);

  @override
  Future<List<GeoradiusResult<V>>?> georadius(
          K key, double longitude, double latitude, double radius, GeoUnit unit,
          {bool withCoord = false,
          bool withDist = false,
          bool withHash = false,
          int? count,
          GeoOrder? order}) =>
      run<List<GeoradiusResult<V>>?>(<Object?>[
        r'GEORADIUS_RO',
        key,
        longitude,
        latitude,
        radius,
        unit.name,
        withCoord ? r'WITHCOORD' : null,
        withDist ? r'WITHDIST' : null,
        withHash ? r'WITHHASH' : null,
        count == null ? null : r'COUNT',
        count,
        order?.name
      ],
          mapper: GeoRadiusMapper<V>(
              withCoord: withCoord, withDist: withDist, withHash: withHash));

  @override
  Future<int?> georadiusStore(
          K key, double longitude, double latitude, double radius, GeoUnit unit,
          {int? count, GeoOrder? order, K? storeKey, K? storeDistKey}) =>
      run<int?>(<Object?>[
        r'GEORADIUS',
        key,
        longitude,
        latitude,
        radius,
        unit.name,
        count == null ? null : r'COUNT',
        count,
        order?.name,
        storeKey == null ? null : r'STORE',
        storeKey,
        storeDistKey == null ? null : r'STOREDIST',
        storeDistKey
      ], mapper: geoRadiusStoreMapper);

  @override
  Future<List<GeoradiusResult<V>>?> georadiusbymember(
          K key, V member, double radius, GeoUnit unit,
          {bool withCoord = false,
          bool withDist = false,
          bool withHash = false,
          int? count,
          GeoOrder? order}) =>
      run<List<GeoradiusResult<V>>?>(<Object?>[
        r'GEORADIUSBYMEMBER_RO',
        key,
        member,
        radius,
        unit.name,
        withCoord ? r'WITHCOORD' : null,
        withDist ? r'WITHDIST' : null,
        withHash ? r'WITHHASH' : null,
        count == null ? null : r'COUNT',
        count,
        order?.name
      ],
          mapper: GeoRadiusMapper<V>(
              withCoord: withCoord, withDist: withDist, withHash: withHash));

  @override
  Future<int?> georadiusbymemberStore(
          K key, V member, double radius, GeoUnit unit,
          {int? count, GeoOrder? order, K? storeKey, K? storeDistKey}) =>
      run<int?>(<Object?>[
        r'GEORADIUSBYMEMBER',
        key,
        member,
        radius,
        unit.name,
        count == null ? null : r'COUNT',
        count,
        order?.name,
        storeKey == null ? null : r'STORE',
        storeKey,
        storeDistKey == null ? null : r'STOREDIST',
        storeDistKey
      ], mapper: geoRadiusStoreMapper);

  // Hashes.

  @override
  Future<int?> hdel(K key, {K? field, Iterable<K> fields = const []}) =>
      run<int?>(<Object?>[r'HDEL', key, field, ...fields]);

  @override
  Future<int?> hexists(K key, K field) =>
      run<int?>(<Object?>[r'HEXISTS', key, field]);

  @override
  Future<V?> hget(K key, K field) => run<V?>(<Object?>[r'HGET', key, field]);

  @override
  Future<Map<K, V?>?> hgetall(K key) =>
      run<Map<K, V?>?>(<Object?>[r'HGETALL', key], mapper: HashMapper<K, V>());

  @override
  Future<int?> hincrby(K key, K field, int increment) =>
      run<int?>(<Object?>[r'HINCRBY', key, field, increment]);

  @override
  Future<double?> hincrbyfloat(K key, K field, double increment) =>
      run<double?>(<Object?>[r'HINCRBYFLOAT', key, field, increment]);

  @override
  Future<List<K>?> hkeys(K key) => run<List<K>?>(<Object?>[r'HKEYS', key]);

  @override
  Future<int?> hlen(K key) => run<int?>(<Object?>[r'HLEN', key]);

  @override
  Future<List<V?>> hmget(K key, {K? field, Iterable<K> fields = const []}) =>
      run<List<V?>>(<Object?>[r'HMGET', key, field, ...fields]);

  @override
  Future<void> hmset(K key, {K? field, V? value, Map<K, V?> hash = const {}}) =>
      run<void>(<Object?>[
        r'HMSET',
        key,
        field,
        value,
        ...hash.entries.expand((entry) => [entry.key, entry.value])
      ]);

  @override
  Future<HashScanResult<K, V?>?> hscan(K key, int cursor,
          {K? pattern, int? count}) =>
      run<HashScanResult<K, V?>?>(<void>[
        r'HSCAN',
        key,
        cursor,
        pattern == null ? null : r'MATCH',
        pattern,
        count == null ? null : r'COUNT',
        count
      ], mapper: HashScanMapper<K, V>());

  @override
  Future<int?> hset(K key, K field, V? value) =>
      run<int?>(<Object?>[r'HSET', key, field, value]);

  @override
  Future<int?> hsetnx(K key, K field, V? value) =>
      run<int?>(<Object?>[r'HSETNX', key, field, value]);

  @override
  Future<int?> hstrlen(K key, K field) =>
      run<int?>(<Object?>[r'HSTRLEN', key, field]);

  @override
  Future<List<V?>?> hvals(K? key) => run<List<V?>?>(<Object?>[r'HVALS', key]);

  // HyperLogLogs.

  @override
  Future<int?> pfadd(K key, {V? element, Iterable<V> elements = const []}) =>
      run<int?>(<Object?>[r'PFADD', key, element, ...elements]);

  @override
  Future<int?> pfcount({K? key, Iterable<K> keys = const []}) =>
      run<int?>(<Object?>[r'PFCOUNT', key, ...keys]);

  @override
  Future<void> pfmerge(K destkey,
          {K? sourcekey, Iterable<K> sourcekeys = const []}) =>
      run<void>(<Object?>[r'PFMERGE', destkey, sourcekey, ...sourcekeys]);

  // Keys.

  @override
  Future<int> del({K? key, Iterable<K> keys = const []}) =>
      run<int>(<Object>[r'DEL', if (key != null) key, ...keys]);

  @override
  Future<List<int>?> dump(K key) => run<List<int>?>(<Object>[r'DUMP', key]);

  @override
  Future<int> exists({K? key, Iterable<K> keys = const []}) =>
      run<int>(<Object>[r'EXISTS', if (key != null) key, ...keys]);

  @override
  Future<int> expire(K key, int seconds) =>
      run<int>(<Object>[r'EXPIRE', key, seconds]);

  @override
  Future<int> expireat(K key, int timestamp) =>
      run<int>(<Object>[r'EXPIREAT', key, timestamp]);

  @override
  Future<List<K>> keys(K pattern) => run<List<K>>(<Object>[r'KEYS', pattern]);

  @override
  Future<String> migrate(String host, int port, int destinationDb, int timeout,
          {bool copy = false,
          bool replace = false,
          K? key,
          Iterable<K> keys = const []}) =>
      run<String>(<Object>[
        r'MIGRATE',
        host,
        port,
        key ?? r'',
        destinationDb,
        timeout,
        if (copy) r'COPY',
        if (replace) r'REPLACE',
        if (keys.isNotEmpty) r'KEYS',
        ...keys
      ]);

  @override
  Future<int> move(K key, int db) => run<int>(<Object>[r'MOVE', key, db]);

  @override
  Future<String?> object(ObjectSubcommand subcommand, K key) =>
      run<String?>(<Object>[r'OBJECT', subcommand.name, key]);

  @override
  Future<List<String>> objectHelp() =>
      run<List<String>>(<Object>[r'OBJECT', r'HELP']);

  @override
  Future<int> persist(K key) => run<int>(<Object>[r'PERSIST', key]);

  @override
  Future<int> pexpire(K key, int milliseconds) =>
      run<int>(<Object>[r'PEXPIRE', key, milliseconds]);

  @override
  Future<int> pexpireat(K key, int millisecondsTimestamp) =>
      run<int>(<Object>[r'PEXPIREAT', key, millisecondsTimestamp]);

  @override
  Future<int> pttl(K key) => run<int>(<Object>[r'PTTL', key]);

  @override
  Future<K> randomkey() => run<K>(<Object>[r'RANDOMKEY']);

  @override
  Future<void> rename(K key, K newkey) =>
      run<void>(<Object?>[r'RENAME', key, newkey]);

  @override
  Future<int> renamenx(K key, K newkey) =>
      run<int>(<Object>[r'RENAMENX', key, newkey]);

  @override
  Future<void> restore(K key, int ttl, List<int> serializedValue,
          {bool replace = false}) =>
      run<void>(<Object?>[
        r'RESTORE',
        key,
        ttl,
        serializedValue,
        replace ? r'REPLACE' : null
      ]);

  @override
  Future<KeyScanResult<K>> scan(int cursor, {K? pattern, int? count}) =>
      run<KeyScanResult<K>>(<Object?>[
        r'SCAN',
        cursor,
        pattern == null ? null : r'MATCH',
        pattern,
        count == null ? null : r'COUNT',
        count
      ], mapper: KeyScanMapper<K>());

  @override
  Future<List<V?>> sort(K key,
      {K? by,
      int? offset,
      int? count,
      Iterable<K> get = const [],
      SortOrder? order,
      bool alpha = false}) {
    assert(
        (offset == null && count == null) || (offset != null && count != null));

    return run<List<V?>>(<Object?>[
      r'SORT',
      key,
      by == null ? null : r'BY',
      by,
      offset == null ? null : r'LIMIT',
      offset,
      count,
      ...get.expand((pattern) => <Object?>[r'GET', pattern]),
      order?.name,
      alpha ? r'ALPHA' : null
    ]);
  }

  @override
  Future<int> sortStore(K key, K destination,
      {K? by,
      int? offset,
      int? count,
      Iterable<K> get = const [],
      SortOrder? order,
      bool alpha = false}) {
    assert(
        (offset == null && count == null) || (offset != null && count != null));

    return run<int>(<Object?>[
      r'SORT',
      key,
      by == null ? null : r'BY',
      by,
      offset == null ? null : r'LIMIT',
      offset,
      count,
      ...get.expand((pattern) => <Object?>[r'GET', pattern]),
      order?.name,
      alpha ? r'ALPHA' : null,
      r'STORE',
      destination
    ]);
  }

  @override
  Future<int> touch({K? key, Iterable<K> keys = const []}) =>
      run<int>(<Object?>[r'TOUCH', key, ...keys]);

  @override
  Future<int> ttl(K key) => run<int>(<Object?>[r'TTL', key]);

  @override
  Future<String> type(K key) => run<String>(<Object?>[r'TYPE', key]);

  @override
  Future<int> unlink({K? key, Iterable<K> keys = const []}) =>
      run<int>(<Object?>[r'UNLINK', key, ...keys]);

  @override
  Future<int> wait(int numslaves, int timeout) =>
      run<int>(<Object>[r'WAIT', numslaves, timeout]);

  // Lists.

  @override
  Future<ListPopResult<K?, V?>?> blpop(
          {K? key, Iterable<K?> keys = const [], int timeout = 0}) =>
      run<ListPopResult<K?, V?>?>(<Object?>[r'BLPOP', key, ...keys, timeout],
          mapper: ListPopResultMapper<K, V>());

  @override
  Future<ListPopResult<K?, V?>?> brpop(
          {K? key, Iterable<K?> keys = const [], int timeout = 0}) =>
      run<ListPopResult<K?, V?>?>(<Object?>[r'BRPOP', key, ...keys, timeout],
          mapper: ListPopResultMapper<K, V>());

  @override
  Future<V?> brpoplpush(K? source, K? destination, {int timeout = 0}) =>
      run<V?>(<Object?>[r'BRPOPLPUSH', source, destination, timeout],
          mapper: BrpoplpushMapper<V>());

  @override
  Future<V?> lindex(K? key, int index) =>
      run<V?>(<Object?>[r'LINDEX', key, index]);

  @override
  Future<int> linsert(K? key, InsertPosition position, V? pivot, V? value) =>
      run<int>(<Object?>[r'LINSERT', key, position.name, pivot, value]);

  @override
  Future<int> llen(K? key) => run<int>(<Object?>[r'LLEN', key]);

  @override
  Future<V?> lpop(K? key) => run<V?>(<Object?>[r'LPOP', key]);

  @override
  Future<int> lpush(K? key, {V? value, Iterable<V?> values = const []}) =>
      run<int>(<Object?>[r'LPUSH', key, value, ...values]);

  @override
  Future<int> lpushx(K? key, V? value) =>
      run<int>(<Object?>[r'LPUSHX', key, value]);

  @override
  Future<List<V>> lrange(K? key, int start, int stop) =>
      run<List<V>>(<Object?>[r'LRANGE', key, start, stop]);

  @override
  Future<int> lrem(K? key, int count, V? value) =>
      run<int>(<Object?>[r'LREM', key, count, value]);

  @override
  Future<void> lset(K? key, int index, V? value) =>
      run<void>(<Object?>[r'LSET', key, index, value]);

  @override
  Future<void> ltrim(K? key, int start, int stop) =>
      run<void>(<Object?>[r'LTRIM', key, start, stop]);

  @override
  Future<V?> rpop(K? key) => run<V?>(<Object?>[r'RPOP', key]);

  @override
  Future<V?> rpoplpush(K? source, K? destination) =>
      run<V?>(<Object?>[r'RPOPLPUSH', source, destination]);

  @override
  Future<int> rpush(K? key, {V? value, Iterable<V?> values = const []}) =>
      run<int>(<Object?>[r'RPUSH', key, value, ...values]);

  @override
  Future<int> rpushx(K? key, V? value) =>
      run<int>(<Object?>[r'RPUSHX', key, value]);

  // Pub/Sub.

  @override
  Future<int> publish(K? channel, V message) =>
      run<int>(<Object?>[r'PUBLISH', channel, message]);

  @override
  Future<List<K>> pubsubChannels({K? pattern}) =>
      run<List<K>>(<Object?>[r'PUBSUB', r'CHANNELS', pattern]);

  @override
  Future<List<PubsubResult<K?>>> pubsubNumsub(
          {Iterable<K?> channels = const []}) =>
      run<List<PubsubResult<K?>>>(<Object?>[r'PUBSUB', r'NUMSUB', ...channels],
          mapper: PubsubResultMapper<K>());

  @override
  Future<int> pubsubNumpat() => run<int>(<Object>[r'PUBSUB', r'NUMPAT']);

  // Scripting.

  @override
  Future<T> eval<T>(String script,
          {Iterable<K> keys = const [],
          Iterable<Object> args = const [],
          Mapper<T>? mapper}) =>
      run<T>(<Object?>[r'EVAL', script, keys.length, ...keys, ...args],
          mapper: mapper);

  @override
  Future<T> evalsha<T>(String sha1,
          {Iterable<K> keys = const [],
          Iterable<Object> args = const [],
          Mapper<T>? mapper}) =>
      run<T>(<Object?>[r'EVALSHA', sha1, keys.length, ...keys, ...args],
          mapper: mapper);

  @override
  Future<void> scriptDebug(ScriptDebugMode mode) =>
      run<void>(<Object>[r'SCRIPT', r'DEBUG', mode.name]);

  @override
  Future<List<int>> scriptExists(
          {String? sha1, Iterable<String> sha1s = const []}) =>
      run<List<int>>(<Object?>[r'SCRIPT', r'EXISTS', sha1, ...sha1s]);

  @override
  Future<void> scriptFlush() => run<void>(<Object>[r'SCRIPT', r'FLUSH']);

  @override
  Future<void> scriptKill() => run<void>(<Object>[r'SCRIPT', r'KILL']);

  @override
  Future<String> scriptLoad(String script) =>
      run<String>(<Object>[r'SCRIPT', r'LOAD', script]);

  // Server.

  @override
  Future<String> bgrewriteaof() => run<String>(<Object>[r'BGREWRITEAOF']);

  @override
  Future<String> bgsave() => run<String>(<Object>[r'BGSAVE']);

  @override
  Future<String?> clientGetname() =>
      run<String?>(<Object>[r'CLIENT', r'GETNAME']);

  @override
  Future<int?> clientKill(
          {String? ipPort, Iterable<ClientFilter> filters = const []}) =>
      run<int?>(<Object?>[
        r'CLIENT',
        r'KILL',
        ipPort,
        ...filters.expand(_expandClientFilter)
      ], mapper: clientKillMapper);

  List<Object?> _expandClientFilter(ClientFilter filter) => <Object?>[
        filter.clientId == null ? null : r'ID',
        filter.clientId,
        filter.type == null ? null : r'TYPE',
        filter.type?.name,
        filter.ipPort == null ? null : r'ADDR',
        filter.ipPort,
        filter.skipMe ? null : r'SKIPME',
        filter.skipMe ? null : r'no'
      ];

  @override
  Future<List<Map<String, String>>> clientList() =>
      run<List<Map<String, String>>>(<Object>[r'CLIENT', r'LIST'],
          mapper: clientListMapper);

  @override
  Future<void> clientPause(int timeout) =>
      run<void>(<Object>[r'CLIENT', r'PAUSE', timeout]);

  @override
  Future<void> clientReply(ReplyMode mode) {
    final command = ClientReplyCommand<void>(
        <Object>[r'CLIENT', r'REPLY', mode.name], mode);

    return execute(command);
  }

  @override
  Future<void> clientSetname(String connectionName) =>
      run<void>(<Object>[r'CLIENT', r'SETNAME', connectionName]);

  @override
  Future<List<ClientCommand?>> command() =>
      run<List<ClientCommand?>>(<Object>[r'COMMAND'], mapper: commandMapper);

  @override
  Future<int> commandCount() => run<int>(<Object>[r'COMMAND', r'COUNT']);

  @override
  Future<List<K>> commandGetkeys(List<Object> commandLine) =>
      run<List<K>>(<Object>[r'COMMAND', r'GETKEYS', ...commandLine]);

  @override
  Future<List<ClientCommand?>> commandInfo(
          {String? commandName, Iterable<String> commandNames = const []}) =>
      run<List<ClientCommand?>>(
          <Object?>[r'COMMAND', r'INFO', commandName, ...commandNames],
          mapper: commandMapper);

  @override
  Future<Map<String?, String?>> configGet(String parameter) =>
      run<Map<String?, String?>>(<Object>[r'CONFIG', r'GET', parameter],
          mapper: configMapper);

  @override
  Future<void> configResetstat() =>
      run<void>(<Object>[r'CONFIG', r'RESETSTAT']);

  @override
  Future<void> configRewrite() => run<void>(<Object>[r'CONFIG', r'REWRITE']);

  @override
  Future<void> configSet(String parameter, String value) =>
      run<void>(<Object>[r'CONFIG', r'SET', parameter, value]);

  @override
  Future<int> dbsize() => run<int>(<Object>[r'DBSIZE']);

  @override
  Future<String> debugObject(K key) =>
      run<String>(<Object?>[r'DEBUG', r'OBJECT', key]);

  @override
  Future<void> debugSegfault() => run<void>(<Object>[r'DEBUG', r'SEGFAULT']);

  @override
  Future<void> flushall({bool asynchronously = false}) =>
      run<void>(<Object?>[r'FLUSHALL', asynchronously ? r'ASYNC' : null]);

  @override
  Future<void> flushdb({bool asynchronously = false}) =>
      run<void>(<Object?>[r'FLUSHDB', asynchronously ? r'ASYNC' : null]);

  @override
  Future<String> info([InfoSection? section]) =>
      run<String>(<Object?>[r'INFO', section?.name]);

  @override
  Future<int> lastsave() => run<int>(<Object>[r'LASTSAVE']);

  @override
  Future<String> memoryDoctor() => run<String>(<Object>[r'MEMORY', r'DOCTOR']);

  @override
  Future<List<String>> memoryHelp() =>
      run<List<String>>(<Object>[r'MEMORY', r'HELP']);

  @override
  Future<String> memoryMallocStats() =>
      run<String>(<Object>[r'MEMORY', r'MALLOC-STATS']);

  @override
  Future<void> memoryPurge() => run<void>(<Object>[r'MEMORY', r'PURGE']);

  @override
  Future<Map<String?, Object?>> memoryStats() =>
      run<Map<String?, Object?>>(<Object>[r'MEMORY', r'STATS'],
          mapper: memoryStatsMapper);

  @override
  Future<int?> memoryUsage(K key, {int? count}) => run<int?>(<Object?>[
        r'MEMORY',
        r'USAGE',
        key,
        count == null ? null : r'SAMPLES',
        count
      ]);

  @override
  Future<Role> role() => run<Role>(<Object>[r'ROLE'], mapper: roleMapper);

  @override
  Future<void> save() => run<void>(<Object>[r'SAVE']);

  @override
  Future<void> shutdown([ShutdownMode? mode]) =>
      run<void>(<Object?>[r'SHUTDOWN', mode?.name]);

  @override
  Future<void> slaveof(String host, String port) =>
      run<void>(<Object>[r'SLAVEOF', host, port]);

  @override
  Future<List<SlowLogEntry>> slowlogGet({int? count}) =>
      run<List<SlowLogEntry>>(<Object?>[r'SLOWLOG', r'GET', count],
          mapper: slowLogMapper);

  @override
  Future<int> slowlogLen() => run<int>(<Object>[r'SLOWLOG', r'LEN']);

  @override
  Future<void> slowlogReset() => run<void>(<Object>[r'SLOWLOG', r'RESET']);

  @override
  Future<ServerTime> time() =>
      run<ServerTime>(<Object>[r'TIME'], mapper: timeMapper);

  // Sets.

  @override
  Future<int> sadd(K key, {V? member, Iterable<V> members = const []}) =>
      run<int>(<Object?>[r'SADD', key, member, ...members]);

  @override
  Future<int> scard(K key) => run<int>([r'SCARD', key]);

  @override
  Future<List<V>> sdiff(K key, {Iterable<K> keys = const []}) =>
      run<List<V>>(<Object?>[r'SDIFF', key, ...keys]);

  @override
  Future<int> sdiffstore(K destination, K key, {Iterable<K> keys = const []}) =>
      run<int>(<Object?>[r'SDIFFSTORE', destination, key, ...keys]);

  @override
  Future<List<V>> sinter(K key, {Iterable<K> keys = const []}) =>
      run<List<V>>(<Object?>[r'SINTER', key, ...keys]);

  @override
  Future<int> sinterstore(K destination, K key,
          {Iterable<K> keys = const []}) =>
      run<int>(<Object?>[r'SINTERSTORE', destination, key, ...keys]);

  @override
  Future<int> sismember(K key, V member) =>
      run<int>(<Object?>[r'SISMEMBER', key, member]);

  @override
  Future<List<V>> smembers(K key) => run<List<V>>(<Object?>[r'SMEMBERS', key]);

  @override
  Future<int> smove(K source, K destination, V member) =>
      run<int>(<Object?>[r'SMOVE', source, destination, member]);

  @override
  Future<V?> spop(K key) => run<V?>(<Object?>[r'SPOP', key]);

  @override
  Future<List<V>> spopCount(K key, int count) =>
      run<List<V>>(<Object?>[r'SPOP', key, count]);

  @override
  Future<V?> srandmember(K key) => run<V?>(<Object?>[r'SRANDMEMBER', key]);

  @override
  Future<List<V>> srandmemberCount(K key, int count) =>
      run<List<V>>(<Object?>[r'SRANDMEMBER', key, count]);

  @override
  Future<int> srem(K key, {V? member, Iterable<V> members = const []}) =>
      run<int>(<Object?>[r'SREM', key, member, ...members]);

  @override
  Future<SetScanResult<V>> sscan(K key, int cursor, {K? pattern, int? count}) =>
      run<SetScanResult<V>>(<Object?>[
        r'SSCAN',
        key,
        cursor,
        pattern == null ? null : r'MATCH',
        pattern,
        count == null ? null : r'COUNT',
        count
      ], mapper: SetScanMapper<V>());

  @override
  Future<List<V>> sunion(K key, {Iterable<K> keys = const []}) =>
      run<List<V>>(<Object?>[r'SUNION', key, ...keys]);

  @override
  Future<int> sunionstore(K destination, K key,
          {Iterable<K> keys = const []}) =>
      run<int>(<Object?>[r'SUNIONSTORE', destination, key, ...keys]);

  // Sorted sets.

  @override
  Future<SortedSetPopResult<K, V>?> bzpopmax(
          {K? key, Iterable<K?> keys = const [], int timeout = 0}) =>
      run<SortedSetPopResult<K, V>?>(
          <Object?>[r'BZPOPMAX', key, ...keys, timeout],
          mapper: SortedSetPopResultMapper<K, V>());

  @override
  Future<SortedSetPopResult<K, V>?> bzpopmin(
          {K? key, Iterable<K?> keys = const [], int timeout = 0}) =>
      run<SortedSetPopResult<K, V>?>(
          <Object?>[r'BZPOPMIN', key, ...keys, timeout],
          mapper: SortedSetPopResultMapper<K, V>());

  @override
  Future<int> zadd(K? key,
          {SortedSetExistMode? mode,
          bool changed = false,
          double? score,
          V? member,
          Map<V?, double> set = const {}}) =>
      run<int>(<Object?>[
        r'ZADD',
        key,
        mode?.name,
        changed ? r'CH' : null,
        score,
        member,
        ...set.entries.expand((entry) => [entry.value, entry.key])
      ]);

  @override
  Future<double?> zaddIncr(K? key, double score, V? member,
          {SortedSetExistMode? mode}) =>
      run<double?>(<Object?>[r'ZADD', key, mode?.name, r'INCR', score, member]);

  @override
  Future<int> zcard(K? key) => run<int>(<Object?>[r'ZCARD', key]);

  @override
  Future<int> zcount(K? key, String min, String max) =>
      run<int>(<Object?>[r'ZCOUNT', key, min, max]);

  @override
  Future<double> zincrby(K? key, double increment, V? member) =>
      run<double>(<Object?>[r'ZINCRBY', key, increment, member]);

  @override
  Future<int> zinterstore(K? destination, List<K?> keys,
          {Iterable<double> weights = const [], AggregateMode? mode}) =>
      run<int>(<Object?>[
        r'ZINTERSTORE',
        destination,
        keys.length,
        ...keys,
        weights.isEmpty ? null : r'WEIGHTS',
        ...weights,
        mode == null ? null : r'AGGREGATE',
        mode?.name
      ]);

  @override
  Future<int> zlexcount(K? key, V? min, V? max) =>
      run<int>(<Object?>[r'ZLEXCOUNT', key, min, max]);

  @override
  Future<Map<V?, double?>?> zpopmax(K? key, {int? count}) =>
      run<Map<V?, double?>?>(<Object?>[r'ZPOPMAX', key, count],
          mapper: SortedSetMapper<V>(withScores: true));

  @override
  Future<Map<V?, double?>?> zpopmin(K? key, {int? count}) =>
      run<Map<V?, double?>?>(<Object?>[r'ZPOPMIN', key, count],
          mapper: SortedSetMapper<V>(withScores: true));

  @override
  Future<Map<V?, double?>?> zrange(K? key, int start, int stop,
          {bool withScores = false}) =>
      run<Map<V?, double?>?>(<Object?>[
        r'ZRANGE',
        key,
        start,
        stop,
        withScores ? r'WITHSCORES' : null
      ], mapper: SortedSetMapper<V>(withScores: withScores));

  @override
  Future<List<V>> zrangebylex(K? key, V? min, V? max,
      {int? offset, int? count}) {
    assert(
        (offset == null && count == null) || (offset != null && count != null));

    return run<List<V>>(<Object?>[
      r'ZRANGEBYLEX',
      key,
      min,
      max,
      offset == null ? null : r'LIMIT',
      offset,
      count
    ]);
  }

  @override
  Future<Map<V?, double?>?> zrangebyscore(K? key, String min, String max,
      {bool withScores = false, int? offset, int? count}) {
    assert(
        (offset == null && count == null) || (offset != null && count != null));

    return run<Map<V?, double?>?>(<Object?>[
      r'ZRANGEBYSCORE',
      key,
      min,
      max,
      withScores ? r'WITHSCORES' : null,
      offset == null ? null : r'LIMIT',
      offset,
      count
    ], mapper: SortedSetMapper<V>(withScores: withScores));
  }

  @override
  Future<int?> zrank(K? key, V? member) =>
      run<int?>(<Object?>[r'ZRANK', key, member]);

  @override
  Future<int> zrem(K? key, {V? member, Iterable<V?> members = const []}) =>
      run<int>(<Object?>[r'ZREM', key, member, ...members]);

  @override
  Future<int> zremrangebylex(K? key, V? min, V? max) =>
      run<int>(<Object?>[r'ZREMRANGEBYLEX', key, min, max]);

  @override
  Future<int> zremrangebyrank(K? key, int start, int stop) =>
      run<int>(<Object?>[r'ZREMRANGEBYRANK', key, start, stop]);

  @override
  Future<int> zremrangebyscore(K? key, String min, String max) =>
      run<int>(<Object?>[r'ZREMRANGEBYSCORE', key, min, max]);

  @override
  Future<Map<V?, double?>?> zrevrange(K? key, int start, int stop,
          {bool withScores = false}) =>
      run<Map<V?, double?>?>(<Object?>[
        r'ZREVRANGE',
        key,
        start,
        stop,
        withScores ? r'WITHSCORES' : null
      ], mapper: SortedSetMapper<V>(withScores: withScores));

  @override
  Future<List<V>> zrevrangebylex(K? key, V? max, V? min,
      {int? offset, int? count}) {
    assert(
        (offset == null && count == null) || (offset != null && count != null));

    return run<List<V>>(<Object?>[
      r'ZREVRANGEBYLEX',
      key,
      max,
      min,
      offset == null ? null : r'LIMIT',
      offset,
      count
    ]);
  }

  @override
  Future<Map<V?, double?>?> zrevrangebyscore(K? key, String max, String min,
      {bool withScores = false, int? offset, int? count}) {
    assert(
        (offset == null && count == null) || (offset != null && count != null));

    return run<Map<V?, double?>?>(<Object?>[
      r'ZREVRANGEBYSCORE',
      key,
      max,
      min,
      withScores ? r'WITHSCORES' : null,
      offset == null ? null : r'LIMIT',
      offset,
      count
    ], mapper: SortedSetMapper<V>(withScores: withScores));
  }

  @override
  Future<int?> zrevrank(K? key, V? member) =>
      run<int?>(<Object?>[r'ZREVRANK', key, member]);

  @override
  Future<SortedSetScanResult<K>> zscan(K? key, int cursor,
          {K? pattern, int? count}) =>
      run<SortedSetScanResult<K>>(<Object?>[
        r'ZSCAN',
        key,
        cursor,
        pattern == null ? null : r'MATCH',
        pattern,
        count == null ? null : r'COUNT',
        count
      ], mapper: SortedSetScanMapper<K>());

  @override
  Future<double?> zscore(K? key, V? member) =>
      run<double?>(<Object?>[r'ZSCORE', key, member]);

  @override
  Future<int> zunionstore(K? destination, List<K?> keys,
          {Iterable<double> weights = const [], AggregateMode? mode}) =>
      run<int>(<Object?>[
        r'ZUNIONSTORE',
        destination,
        keys.length,
        ...keys,
        weights.isEmpty ? null : r'WEIGHTS',
        ...weights,
        mode == null ? null : r'AGGREGATE',
        mode?.name
      ]);

  // Streams.

  @override
  Future<int> xack(K? key, K? group, {K? id, Iterable<K?> ids = const []}) =>
      run<int>(<Object?>[r'XACK', key, group, id, ...ids]);

  @override
  Future<K> xadd(K? key,
          {K? id,
          K? field,
          V? value,
          Map<K?, V?> fields = const {},
          int? maxlen,
          bool roughly = false}) =>
      run<K>(<Object?>[
        r'XADD',
        key,
        maxlen == null ? null : r'MAXLEN',
        roughly ? r'~' : null,
        maxlen,
        id ?? r'*',
        field,
        value,
        ...fields.entries.expand((entry) => [entry.key, entry.value])
      ]);

  @override
  Future<Object> xclaim(K? key, K? group, K? consumer, int minIdleTime,
          {K? id,
          Iterable<K?> ids = const [],
          int? idle,
          int? idleTimestamp,
          int? retryCount,
          bool force = false,
          bool justId = false}) =>
      run<Object>(<Object?>[
        r'XCLAIM',
        key,
        group,
        consumer,
        minIdleTime,
        id,
        ...ids,
        idle == null ? null : r'IDLE',
        idle,
        idleTimestamp == null ? null : r'TIME',
        idleTimestamp,
        retryCount == null ? null : r'RETRYCOUNT',
        retryCount,
        force ? r'FORCE' : null,
        justId ? r'JUSTID' : null
      ], mapper: StreamClaimMapper<K, V>(justId: justId));

  @override
  Future<int> xdel(K? key, {K? id, Iterable<K?> ids = const []}) =>
      run<int>(<Object?>[r'XDEL', key, id, ...ids]);

  @override
  Future<Object?> xgroup(StreamGroupSubcommand subcommand,
          {K? key, K? group, K? id, K? consumer, bool mkstream = false}) =>
      run<Object?>(<Object?>[
        r'XGROUP',
        subcommand.name,
        key,
        group,
        id,
        consumer,
        mkstream ? r'MKSTREAM' : null
      ], mapper: streamGroupMapper);

  @override
  Future<Object> xinfo(StreamInfoSubcommand subcommand, {K? key, K? group}) =>
      run<Object>(<Object?>[r'XINFO', subcommand.name, key, group],
          mapper: StreamInfoMapper<K, V>(subcommand));

  @override
  Future<int> xlen(K? key) => run<int>(<Object?>[r'XLEN', key]);

  @override
  Future<Object> xpending(K? key, K? group,
      {K? start, K? end, int? count, K? consumer}) {
    assert((start == null && end == null && count == null) ||
        (start != null && end != null && count != null) ||
        (start != null && end != null && count != null && consumer != null));

    return run<Object>(
        <Object?>[r'XPENDING', key, group, start, end, count, consumer],
        mapper: StreamPendingMapper<K, V>(justSummary: start == null));
  }

  @override
  Future<List<StreamEntry<K?, V?>>> xrange(K? key, K? start, K? end,
          {int? count}) =>
      run<List<StreamEntry<K?, V?>>>(<Object?>[
        r'XRANGE',
        key,
        start,
        end,
        count == null ? null : r'COUNT',
        count
      ], mapper: StreamMapper<K, V>());

  @override
  Future<Map<K?, List<StreamEntry<K?, V?>?>>?> xread(
          {K? key,
          K? id,
          Iterable<K?> keys = const [],
          Iterable<K?> ids = const [],
          int? count,
          int? timeout}) =>
      run<Map<K?, List<StreamEntry<K?, V?>?>>?>(<Object?>[
        r'XREAD',
        count == null ? null : r'COUNT',
        count,
        timeout == null ? null : r'BLOCK',
        timeout,
        r'STREAMS',
        key,
        ...keys,
        id,
        ...ids
      ], mapper: StreamsMapper<K, V>());

  @override
  Future<Map<K?, List<StreamEntry<K?, V?>?>>?> xreadgroup(K? group, K? consumer,
          {K? key,
          K? id,
          Iterable<K?> keys = const [],
          Iterable<K?> ids = const [],
          int? count,
          int? timeout,
          bool noack = false}) =>
      run<Map<K?, List<StreamEntry<K?, V?>?>>?>(<Object?>[
        r'XREADGROUP',
        r'GROUP',
        group,
        consumer,
        count == null ? null : r'COUNT',
        count,
        timeout == null ? null : r'BLOCK',
        timeout,
        noack ? r'NOACK' : null,
        r'STREAMS',
        key,
        ...keys,
        id,
        ...ids
      ], mapper: StreamsMapper<K, V>());

  @override
  Future<List<StreamEntry<K?, V?>?>> xrevrange(K? key, K? end, K? start,
          {int? count}) =>
      run<List<StreamEntry<K?, V?>?>>(<Object?>[
        r'XREVRANGE',
        key,
        end,
        start,
        count == null ? null : r'COUNT',
        count
      ], mapper: StreamMapper<K, V>());

  @override
  Future<int> xtrim(K? key, int maxlen, {bool roughly = false}) => run<int>(
      <Object?>[r'XTRIM', key, r'MAXLEN', roughly ? r'~' : null, maxlen]);

  // Strings.

  @override
  Future<int> append(K key, V value) =>
      run<int>(<Object?>[r'APPEND', key, value]);

  @override
  Future<int> bitcount(K key, [int? start, int? end]) {
    assert((start == null && end == null) || (start != null && end != null));
    return run<int>(<Object?>[r'BITCOUNT', key, start, end]);
  }

  @override
  Future<List<int?>> bitfield(K key, List<BitfieldOperation> operations) =>
      run<List<int?>>(
          <Object?>[r'BITFIELD', key, ...operations.expand(_expandBitfield)]);

  List<Object?> _expandBitfield(BitfieldOperation operation) => <Object?>[
        operation.overflow == null ? null : r'OVERFLOW',
        operation.overflow?.name,
        operation.command!.name,
        operation.type,
        operation.offset,
        operation.value
      ];

  @override
  Future<int> bitop(BitopOperation operation, K destkey,
          {K? key, Iterable<K> keys = const []}) =>
      run<int>(<Object?>[r'BITOP', operation.name, destkey, key, ...keys]);

  @override
  Future<int> bitpos(K key, int bit, [int? start, int? end]) =>
      run<int>(<Object?>[r'BITPOS', key, bit, start, end]);

  @override
  Future<int> decr(K key) => run<int>(<Object?>[r'DECR', key]);

  @override
  Future<int> decrby(K key, int decrement) =>
      run<int>(<Object?>[r'DECRBY', key, decrement]);

  @override
  Future<V?> get(K key) => run<V?>(<Object?>[r'GET', key]);

  @override
  Future<int> getbit(K key, int offset) =>
      run<int>(<Object?>[r'GETBIT', key, offset]);

  @override
  Future<V> getrange(K key, int start, int end) =>
      run<V>(<Object?>[r'GETRANGE', key, start, end]);

  @override
  Future<V?> getset(K key, V value) =>
      run<V?>(<Object?>[r'GETSET', key, value]);

  @override
  Future<int> incr(K key) => run<int>(<Object?>[r'INCR', key]);

  @override
  Future<int> incrby(K key, int increment) =>
      run<int>(<Object?>[r'INCRBY', key, increment]);

  @override
  Future<double> incrbyfloat(K key, double increment) =>
      run<double>(<Object?>[r'INCRBYFLOAT', key, increment]);

  @override
  Future<List<V?>> mget({K? key, Iterable<K> keys = const []}) =>
      run<List<V?>>(<Object?>[r'MGET', key, ...keys]);

  @override
  Future<void> mset({K? key, V? value, Map<K, V> map = const {}}) =>
      run<void>(<Object?>[
        r'MSET',
        key,
        value,
        ...map.entries.expand((entry) => [entry.key, entry.value])
      ]);

  @override
  Future<int> msetnx({K? key, V? value, Map<K, V> map = const {}}) =>
      run<int>(<Object?>[
        r'MSETNX',
        key,
        value,
        ...map.entries.expand((entry) => [entry.key, entry.value])
      ]);

  @override
  Future<void> psetex(K key, int milliseconds, V value) =>
      run<void>(<Object?>[r'PSETEX', key, milliseconds, value]);

  @override
  Future<bool> set(K key, V value,
      {int? seconds, int? milliseconds, SetExistMode? mode}) async {
    assert((seconds == null && milliseconds == null) ||
        (seconds != null && milliseconds == null) ||
        (seconds == null && milliseconds != null));

    return await run<bool?>(<Object?>[
          r'SET',
          key,
          value,
          seconds == null ? null : r'EX',
          seconds,
          milliseconds == null ? null : r'PX',
          milliseconds,
          mode?.name
        ], mapper: stringSetMapper) ??
        false;
  }

  @override
  Future<int> setbit(K key, int offset, int value) =>
      run<int>(<Object?>[r'SETBIT', key, offset, value]);

  @override
  Future<void> setex(K key, int seconds, V value) =>
      run<void>(<Object?>[r'SETEX', key, seconds, value]);

  @override
  Future<int> setnx(K key, V value) =>
      run<int>(<Object?>[r'SETNX', key, value]);

  @override
  Future<int> setrange(K key, int offset, V value) =>
      run<int>(<Object?>[r'SETRANGE', key, offset, value]);

  @override
  Future<int> strlen(K key) => run<int>(<Object?>[r'STRLEN', key]);

  // Transactions.

  @override
  Future<void> discard() {
    final command = DiscardCommand(<Object>[r'DISCARD']);

    return execute(command);
  }

  @override
  Future<void> exec() {
    final command = ExecCommand(<Object>[r'EXEC']);

    return execute(command);
  }

  @override
  Future<void> multi() {
    final command = MultiCommand(<Object>[r'MULTI']);

    return execute(command);
  }

  @override
  Future<void> unwatch() => run<void>(<Object>[r'UNWATCH']);

  @override
  Future<void> watch({K? key, Iterable<K> keys = const []}) =>
      run<void>(<Object?>[r'WATCH', key, ...keys]);
}
