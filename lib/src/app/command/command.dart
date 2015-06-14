// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.app.command;

import 'dart:async';
import 'dart:io' deferred as io;

import 'package:args/command_runner.dart';
import 'package:isomers/message.dart';

import 'find.dart';
import 'hnmr.dart';
import 'render.dart' deferred as render_command;

/// Type of a function which loads an [ApplicationCommand] asynchronously.
typedef Future<ApplicationCommand> ApplicationCommandLoader();

/// Base class of all commands.
abstract class ApplicationCommand extends Command {
  static Map<String, ApplicationCommandLoader> loaders = {
    'find': () async => new FindCommand(),
    'hnmr': () async => new HnmrCommand(),
    'render': () async {
      await render_command.loadLibrary();
      return new render_command.RenderCommand();
    }
  };

  static Future<ApplicationCommand> load(String name) => loaders[name]();

  /// Stream of input data.
  ///
  /// Reads the lines of the `--input` file if the option is provided.
  /// If additional arguments are provided and this command [takesArguments]
  /// they are yielded.
  /// Reads from `stdout` otherwise.
  Stream<String> get input async* {
    if (globalResults['input'].isNotEmpty) {
      await io.loadLibrary();
      for (var filename in globalResults['input']) {
        var file = new io.File(filename);
        for (var line in await file.readAsLines()) yield line;
      }
    } else if (argResults.rest.isEmpty || !takesArguments) {
      await io.loadLibrary();
      while (true) {
        var line = io.stdin.readLineSync();
        if (line == null) break;
        yield line;
      }
    } else {
      for (var arg in argResults.rest) yield arg;
    }
  }

  @override
  Stream<Message> run();
}
