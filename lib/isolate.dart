// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.isolate;

import 'dart:isolate';

import 'src/app/app.dart';

/// Initial message of an isolate.
class IsolateInterface {

  /// Copy of the application which spawned the isolate.
  final Application app;

  /// Port to communicate with parent isolate.
  final SendPort port;

  IsolateInterface({this.app, this.port});

  /// Reconstructs a [serialize]d instance of this class.
  factory IsolateInterface.deserialize(Map msg) {
    return new IsolateInterface(
        port: msg['port'],
        app: new Application(
            root: Uri.parse(msg['app']['root']),
            allowedCommands: msg['app']['allowedCommands'],
            config: msg['app']['config']));
  }

  /// Converts this object to a map which can be sent to an isolate.
  Map serialize() => {
    'port': port,
    'app': {
      'root': '${app.root}',
      'config': app.config,
      'allowedCommands': app.allowedCommands
    }
  };
}
