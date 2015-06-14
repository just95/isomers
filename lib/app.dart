// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.app;

import 'dart:async';

import 'package:toml/loader.dart';

import 'src/app/app.dart';
import 'src/app/command/command.dart';

export 'src/app/app.dart';

/// Creates a new instance of [Application].
/// 
/// [root] is the path to the root directory of this library.
/// [disabledCommands] is a list of the names of disabled commands.
Future<Application> createApplication(
    {Uri root, List<String> disabledCommands: const []}) async {
  if (root == null) root = Uri.parse('./packages/isomers/');
  return new Application(
      root: root,
      config: await loadConfig(root.resolve('config.toml').path),
      allowedCommands: ApplicationCommand.loaders.keys
          .toSet()
          .difference(disabledCommands.toSet()));
}
