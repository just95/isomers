#!/usr/bin/env dart
// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:isomers/app.dart';
import 'package:isomers/message.dart';
import 'package:toml/loader/fs.dart';

Future main(List<String> args) async {
  try {
    FilesystemConfigLoader.use();
    var root = Platform.script.resolve('./packages/isomers/');
    var app = await createApplication(root: root);
    var res = await app.run(args);
    await for (var msg in res) {
      if (msg is Message && msg.type != MessageType.DEFAULT) {
        stderr.writeln(msg);
      } else if (msg != null) {
        stdout.writeln(msg);
      }
    }
  } on UsageException catch(e) {
    print(new Message.error(e.message));
    print('\n${e.usage}');
  } catch(e) {
    print(new Message.error(e));
  }
}
