// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

import 'dart:async';

import 'package:isomers/isolate.dart';
import 'package:isomers/message.dart';

Future main(List<String> args, Map serializedMsg) async {
  var msg = new IsolateInterface.deserialize(serializedMsg);
  void send(obj) {
    if (obj is! Message) return send(new Message(obj));
    msg.port.send({
      'data': obj.data,
      'type': obj.type.index
    });
  }
  try {
    msg.app.init();
    await for (var obj in msg.app.run(args)) {
      send(obj);
    }
  } catch (e) {
    send(new Message.error('$e'));
  }
  msg.port.send(null); // Close port.
}
