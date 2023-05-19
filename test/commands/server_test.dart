// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late Commands<String, String> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('ServerCommands', () {
    test('bgrewriteaof', () async {
      expect(await commands.bgrewriteaof(), isNotEmpty);
    }, skip: 'Starts an Append Only File rewrite process.');

    test('bgsave', () async {
      expect(await commands.bgsave(), isNotEmpty);
    }, skip: 'Asynchronously saves the dataset to disk.');

    test('clientGetname', () async {
      expect(await commands.clientGetname(), isNull);

      final name = uuid();
      await commands.clientSetname(name);

      expect(await commands.clientGetname(), equals(name));
    });

    test('clientKill', () async {
      // Kill IP:port.
      expect(await commands.clientKill(ipPort: 'unknown:999'), equals(0));

      // Kill filtering.
      expect(
          await commands
              .clientKill(filters: [const ClientFilter(clientId: -999)]),
          equals(0));
      expect(
          await commands.clientKill(
              filters: [const ClientFilter(type: ClientType.slave)]),
          equals(0));
      expect(
          await commands
              .clientKill(filters: [const ClientFilter(ipPort: 'unknown:999')]),
          equals(0));

      // Kill skipping me.
      expect(
          await commands.clientKill(filters: [
            const ClientFilter(type: ClientType.normal, skipMe: false)
          ]),
          greaterThan(0));
    }, skip: 'Kills Redis clients.');

    test('clientList', () async {
      expect(await commands.clientList(), isNotEmpty);
    });

    test('clientPause', () async {
      await commands.clientPause(1);
    });

    test('clientReply', () async {
      // Enable server replies.
      await commands.clientReply(ReplyMode.on);
      expect(await commands.ping(), equals('PONG'));

      // Skip the next server reply.
      await commands.clientReply(ReplyMode.skip);
      expect(await commands.ping(), isNull);
      expect(await commands.ping(), equals('PONG'));

      // Disable server replies.
      await commands.clientReply(ReplyMode.off);
      expect(await commands.ping(), isNull);
      expect(await commands.ping(), isNull);

      // Enable server replies.
      await commands.clientReply(ReplyMode.on);
      expect(await commands.ping(), equals('PONG'));
    });

    test('clientSetname', () async {
      final name = uuid();
      await commands.clientSetname(name);

      expect(await commands.clientGetname(), equals(name));
    });

    test('command', () async {
      expect(await commands.command(), isNotEmpty);
    });

    test('commandCount', () async {
      expect(await commands.commandCount(), greaterThan(0));
    });

    test('commandGetkeys', () async {
      expect(
          await commands
              .commandGetkeys(<Object>['MSET', 'key1', 'val1', 'key2', 'val2']),
          equals(['key1', 'key2']));
      expect(
          await commands.commandGetkeys(
              <Object>['SORT', 'key1', 'ALPHA', 'STORE', 'key2']),
          equals(['key1', 'key2']));
    });

    test('commandInfo', () async {
      // Retrieve one command.
      final results = await commands.commandInfo(commandName: 'GET');
      expect(results, hasLength(1));
      final firstResult = results[0]!;
      expect(firstResult.name, equals('get'));
      expect(firstResult.arity, equals(2));
      expect(firstResult.flags, equals(['readonly', 'fast']));
      expect(firstResult.firstKeyPosition, equals(1));
      expect(firstResult.lastKeyPosition, equals(1));
      expect(firstResult.keyStepCount, equals(1));

      // Retrieve some commands.
      expect(await commands.commandInfo(commandNames: ['GET', 'SET', 'PING']),
          hasLength(3));

      // Try to retrieve information about a non existing command.
      final name = uuid();
      expect(await commands.commandInfo(commandNames: [name]), [null]);
    });

    test('configGet', () async {
      // Retrieve all the parameters.
      expect(await commands.configGet('*'), isNotEmpty);

      // Retrieve one parameter.
      expect(await commands.configGet('requirepass'), isNotEmpty);

      // Try to retrieve a non existing parameter.
      final name = uuid();
      expect(await commands.configGet(name), isEmpty);
    });

    test('configResetstat', () async {
      await commands.configResetstat();
    }, skip: 'Resets the server statistics.');

    test('configRewrite', () async {
      await commands.configRewrite();
    }, skip: 'Overwrites the server configuration file.');

    test('configSet', () async {
      await commands.configSet('maxclients', '100');
    }, skip: 'Updates the server configuration.');

    test('dbsize', () async {
      expect(await commands.dbsize(), greaterThanOrEqualTo(0));
    });

    test('debugObject', () async {
      // Add some values.
      final key = uuid();
      await commands.set(key, 'abc');

      // Get.
      expect(await commands.debugObject(key), isNotEmpty);
    }, skip: 'ERR DEBUG is disabled by default in Redis >=7');

    test('debugSegfault', () async {
      await commands.debugSegfault();
    }, skip: 'Crashes the server.');

    test('flushall', () async {
      // Add some values.
      final key = uuid();
      await commands.set(key, 'abc');

      // Flush.
      await commands.flushall();

      expect(await commands.get(key), isNull);

      // Flush asynchronously.
      await commands.flushall(asynchronously: true);
    }, skip: 'Removes all the keys from all the databases.');

    test('flushdb', () async {
      // Add some values.
      final key = uuid();
      await commands.set(key, 'abc');

      // Flush.
      await commands.flushdb();

      expect(await commands.get(key), isNull);

      // Flush asynchronously.
      await commands.flushdb(asynchronously: true);
    }, skip: 'Removes all the keys from the currently selected database.');

    test('info', () async {
      expect(await commands.info(), isNotEmpty);
      expect(await commands.info(InfoSection.server), isNotEmpty);
      expect(await commands.info(InfoSection.clients), isNotEmpty);
      expect(await commands.info(InfoSection.memory), isNotEmpty);
      expect(await commands.info(InfoSection.persistence), isNotEmpty);
      expect(await commands.info(InfoSection.stats), isNotEmpty);
      expect(await commands.info(InfoSection.replication), isNotEmpty);
      expect(await commands.info(InfoSection.cpu), isNotEmpty);
      expect(await commands.info(InfoSection.commandstats), isNotEmpty);
      expect(await commands.info(InfoSection.cluster), isNotEmpty);
      expect(await commands.info(InfoSection.keyspace), isNotEmpty);
      expect(await commands.info(InfoSection.all), isNotEmpty);
    });

    test('lastsave', () async {
      expect(await commands.lastsave(), greaterThanOrEqualTo(0));
    });

    test('memoryDoctor', () async {
      expect(await commands.memoryDoctor(), isNotEmpty);
    });

    test('memoryHelp', () async {
      expect(await commands.memoryHelp(), isNotEmpty);
    });

    test('memoryMallocStats', () async {
      expect(await commands.memoryMallocStats(), isNotEmpty);
    });

    test('memoryPurge', () async {
      await commands.memoryPurge();
    });

    test('memoryStats', () async {
      expect(await commands.memoryStats(), isNotEmpty);
    });

    test('memoryUsage', () async {
      // Get.
      final key1 = uuid();
      await commands.set(key1, 'abc');
      expect(await commands.memoryUsage(key1), greaterThanOrEqualTo(0));

      // Get with samples.
      final key2 = uuid();
      await commands.hmset(key2, hash: {'a': '1', 'b': '2', 'c': '3'});
      expect(
          await commands.memoryUsage(key2, count: 10), greaterThanOrEqualTo(0));

      // Try to retrieve the memory usage of a non existing key.
      final key3 = uuid();
      expect(await commands.memoryUsage(key3), isNull);
    });

    test('role', () async {
      final result = await commands.role();
      expect(result.type, 'master');
    });

    test('save', () async {
      await commands.save();
    }, skip: 'Blocks all the clients.');

    test('shutdown', () async {
      await commands.shutdown();
      await commands.shutdown(ShutdownMode.noSave);
      await commands.shutdown(ShutdownMode.save);
    }, skip: 'Shuts down the server.');

    test('slaveof', () async {
      await commands.slaveof('NO', 'ONE');
      await commands.slaveof('unknown', 999.toString());
    }, skip: 'Changes the replication settings.');

    test('slowlogGet', () async {
      await commands.configSet('slowlog-log-slower-than', '0');
      await commands.ping();

      expect(await commands.slowlogGet(), isNotEmpty);

      await commands.configSet('slowlog-log-slower-than', '10000');
    });

    test('slowlogLen', () async {
      expect(await commands.slowlogLen(), greaterThanOrEqualTo(0));
    });

    test('slowlogReset', () async {
      await commands.slowlogReset();
    });

    test('time', () async {
      final result = await commands.time();

      expect(result.timestamp, greaterThanOrEqualTo(0));
      expect(result.microseconds, greaterThanOrEqualTo(0));
    });

    group('support', () {
      group('ClientType', () {
        test('toString', () {
          expect(ClientType.master.toString(), startsWith('ClientType:'));
        });
      });

      group('InfoSection', () {
        test('toString', () {
          expect(InfoSection.all.toString(), startsWith('InfoSection:'));
        });
      });

      group('ShutdownMode', () {
        test('toString', () {
          expect(ShutdownMode.save.toString(), startsWith('ShutdownMode:'));
        });
      });

      group('ClientFilter', () {
        test('toString', () {
          const value = ClientFilter();
          expect(value.toString(), startsWith('ClientFilter:'));
        });
      });

      group('ClientCommand', () {
        test('toString', () {
          const value = ClientCommand(null, null, null, null, null, null);
          expect(value.toString(), startsWith('ClientCommand:'));
        });
      });

      group('ServerTime', () {
        test('toString', () {
          const value = ServerTime(null, null);
          expect(value.toString(), startsWith('ServerTime:'));
        });
      });

      group('Slave', () {
        test('toString', () {
          const value = Slave(null, null, null);
          expect(value.toString(), startsWith('Slave:'));
        });
      });

      group('MasterRole', () {
        test('toString', () {
          const value = MasterRole(null, null);
          expect(value.toString(), startsWith('MasterRole:'));
        });
      });

      group('SlaveRole', () {
        test('toString', () {
          const value = SlaveRole(null, null, null, null);
          expect(value.toString(), startsWith('SlaveRole:'));
        });
      });

      group('SentinelRole', () {
        test('toString', () {
          const value = SentinelRole(null);
          expect(value.toString(), startsWith('SentinelRole:'));
        });
      });

      group('Role', () {
        test('toString', () {
          const value = Role(null);
          expect(value.toString(), startsWith('Role:'));
        });
      });

      group('SlowLogEntry', () {
        test('toString', () {
          const value = SlowLogEntry(null, null, null, null, null, null);
          expect(value.toString(), startsWith('SlowLogEntry:'));
        });
      });
    });
  });
}
