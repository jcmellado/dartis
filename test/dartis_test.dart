// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

@Skip('Avoid to run all the tests two times.')

import 'package:test/test.dart' show Skip;

import 'client/client_test.dart' as client_client_test;
import 'client/connection_test.dart' as client_connection_test;
import 'client/monitor_test.dart' as client_monitor_test;
import 'client/pubsub_test.dart' as client_pubsub_test;
import 'client/terminal_test.dart' as client_terminal_test;
import 'client/transaction_test.dart' as client_transaction_test;

import 'command/command_test.dart' as command_command_test;
import 'command/module_test.dart' as command_module_test;

import 'commands/cluster_test.dart' as commands_cluster_test;
import 'commands/connection_test.dart' as commands_connection_test;
import 'commands/geo_test.dart' as commands_geo_test;
import 'commands/hash_test.dart' as commands_hash_test;
import 'commands/hyperloglog_test.dart' as commands_hyperloglog_test;
import 'commands/key_test.dart' as commands_key_test;
import 'commands/list_test.dart' as commands_list_test;
import 'commands/pubsub_test.dart' as commands_pubsub_test;
import 'commands/scripting_test.dart' as commands_scripting_test;
import 'commands/server_test.dart' as commands_server_test;
import 'commands/set_test.dart' as commands_set_test;
import 'commands/sortedset_test.dart' as commands_sortedset_test;
import 'commands/stream_test.dart' as commands_stream_test;
import 'commands/string_test.dart' as commands_string_test;
import 'commands/transaction_test.dart' as commands_transaction_test;

import 'exception_test.dart' as exception_test;

import 'protocol/codec_test.dart' as protocol_codec_test;
import 'protocol/reader_test.dart' as protocol_reader_test;
import 'protocol/reply_test.dart' as protocol_reply_test;
import 'protocol/writer_test.dart' as protocol_writer_test;

void main() {
  // Client
  client_client_test.main();
  client_connection_test.main();
  client_monitor_test.main();
  client_pubsub_test.main();
  client_terminal_test.main();
  client_transaction_test.main();

  // Command
  command_command_test.main();
  command_module_test.main();

  // Commands
  commands_cluster_test.main();
  commands_connection_test.main();
  commands_geo_test.main();
  commands_hash_test.main();
  commands_hyperloglog_test.main();
  commands_key_test.main();
  commands_list_test.main();
  commands_pubsub_test.main();
  commands_scripting_test.main();
  commands_server_test.main();
  commands_set_test.main();
  commands_sortedset_test.main();
  commands_stream_test.main();
  commands_string_test.main();
  commands_transaction_test.main();

  // Protocol
  protocol_codec_test.main();
  protocol_reader_test.main();
  protocol_reply_test.main();
  protocol_writer_test.main();

  // Exception
  exception_test.main();
}
