// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.app.command.find;

import 'dart:async';

import 'package:isomers/chem.dart';
import 'package:isomers/message.dart';

import '../../algo/isomers.dart';
import 'command.dart';

/// Implementation of the `find` command.
class FindCommand extends ApplicationCommand {
  static final Element H = new Element('H');

  FindCommand() {
    argParser.addFlag('add-hydrogen',
        abbr: 'H',
        negatable: false,
        help: 'Add hydrogen atoms independently. Increases performance.',
        defaultsTo: false);
  }

  @override
  String get name => 'find';

  @override
  String get description => 'Find all isomers of a molecule.';

  /// Find all isomers with the given sum formula.
  Stream<Molecule> findIsomers(SumFormula sum) {
    return isomers(sum, addHydrogen: argResults['add-hydrogen']);
  }

  @override
  Stream<Message> run() async* {
    var found = 0;
    var isomers = input.map(SumFormula.parse).asyncExpand(findIsomers);
    await for (var isomer in isomers) {
      found++;
      yield new Message(isomer);
    }
    if (found == 0) yield new Message.warning('Found no isomers!');
  }
}
