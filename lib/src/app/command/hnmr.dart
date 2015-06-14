// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.app.command.hnmr;

import 'dart:async';

import 'package:isomers/chem.dart';
import 'package:isomers/message.dart';

import '../../algo/hnmr.dart';
import 'command.dart';

/// Implementation of the `hnmr` command.
class HnmrCommand extends ApplicationCommand {
  
  /// The [HnmrPredictor] which is used by this command.
  static final predictor = new HnmrPredictor();

  HnmrCommand() {
    argParser.addOption('filter',
        allowMultiple: true,
        splitCommas: true,
        help: 'Filter by splitting pattern of peaks.\n'
        'Use `*` as a wildcard.\n'
        'Use `...` as the last item to specify a non-exhaustive list.',
        valueHelp: 'number,...');
  }

  @override
  String get name => 'hnmr';

  @override
  String get description =>
      'Predict the splitting pattern of the peaks in a H-NMR spectrum.';

  @override
  Stream<Message> run() async* {
    var matched = 0;
    var filter = new HnmrFilter.from(argResults['filter']);
    var predictions = input.map(Molecule.parse).map(predictor.predict);
    await for (var prediction in predictions.where(filter)) {
      matched++;
      yield new Message(prediction);
    }
    if (matched == 0) yield new Message.warning('Found no matches!');
  }
}
