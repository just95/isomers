// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.app;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:isomers/chem.dart';
import 'package:isomers/message.dart';

import 'command/command.dart';

/// Controller of the application.
class Application {

  /// Name of the application.
  String name = 'isomers';

  /// Description of this application.
  String description = 'Isomer calculator.';

  /// URI of the root directory of this package.
  final Uri root;

  /// The configuration options.
  final Map<String, dynamic> config;

  /// The allowed commands.
  final Set<String> allowedCommands;

  Application({this.root, this.config, this.allowedCommands});

  /// Initializes the application.
  void init() {
    Element.init(config['element']);
  }

  /// Runs the application.
  Stream run(List<String> args) async* {
    init();
    var sw = new Stopwatch();

    var runner = new CommandRunner(name, description);
    var commands =
        await Future.wait(allowedCommands.map(ApplicationCommand.load));
    commands.forEach(runner.addCommand);

    // global options:
    runner.argParser.addFlag('measure',
        help: 'Measures the time required by the program.',
        negatable: false,
        callback: (flag) => flag ? sw.start() : null);
    
    runner.argParser.addOption('input',
        abbr: 'i',
        allowMultiple: true,
        valueHelp: 'path',
        help: 'An optional input file.\n'
        'Reads from the command line by default.');

    var res = await runner.run(args);
    if (res is Stream) {
      yield* res;
    } else {
      yield res;
    }
    if (sw.isRunning) {
      sw.stop();
      yield new Message.info(sw.elapsed);
    }
  }
}
