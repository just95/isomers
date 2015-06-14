// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.message;

import 'package:ansicolor/ansicolor.dart';

/// The type of a [Message].
enum MessageType {
  DEFAULT,
  ERROR,
  WARNING,
  INFO,
  SUCCESS
}

/// A message from the application to the user.
class Message {

  /// Color of messages by type.
  static Map<MessageType, AnsiPen> pens = {
    MessageType.ERROR: new AnsiPen()..red(),
    MessageType.WARNING: new AnsiPen()..yellow(),
    MessageType.INFO: new AnsiPen()..blue(),
    MessageType.SUCCESS: new AnsiPen()..green()
  };

  /// The actual message.
  final String data;

  /// The type of the message.
  final MessageType type;

  Message(data, {this.type: MessageType.DEFAULT}) : data = '$data';
  
  factory Message.error(data) => new Message(data, type: MessageType.ERROR);
  factory Message.warning(data) => new Message(data, type: MessageType.WARNING);
  factory Message.info(data) => new Message(data, type: MessageType.INFO);
  factory Message.success(data) => new Message(data, type: MessageType.SUCCESS);

  @override
  String toString() {
    if (pens.containsKey(type)) {
      return pens[type](data);
    }
    return data;
  }
}
