// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.app.command.render;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:isomers/chem.dart';
import 'package:isomers/message.dart';

import '../../algo/dot.dart';
import 'command.dart';

/// Implementation of the `graph` command.
class RenderCommand extends ApplicationCommand {
  RenderCommand() {
    // DOT encoder options.
    argParser.addFlag('no-sticky',
        negatable: false, help: 'Disable the option below.', defaultsTo: false);
    argParser.addOption('sticky',
        allowMultiple: true,
        splitCommas: true,
        help: 'Create no individual nodes for atoms for these types.',
        valueHelp: 'element,...',
        defaultsTo: 'H');

    // Rendering options.
    argParser.addOption('renderer',
        abbr: 'r', help: 'Name of the image rendering engine.\n'
        'If `--format` is `txt` `graph-easy` will be used.',
        valueHelp: 'name',
        allowed: ['dot', 'neato', 'twopi'],
        defaultsTo: 'neato');
    argParser.addOption('bg',
        help: 'Background color of the image.',
        valueHelp: 'color',
        defaultsTo: 'transparent');
    argParser.addOption('fg',
        help: 'Foreground color of the image.',
        valueHelp: 'color',
        defaultsTo: 'black');
    argParser.addOption('dpi',
        help: 'Dots per inch.', valueHelp: 'number', defaultsTo: '96');
    argParser.addFlag('color',
        help: 'Colorize element symbols.', defaultsTo: true);
    argParser.addFlag('subscript',
        help: 'Print numbers in subscript.', defaultsTo: true);

    // Output options.
    argParser.addOption('format',
        abbr: 'f',
        help: 'Target file format. (e.g. `png` or `jpg`)',
        valueHelp: 'type',
        defaultsTo: 'txt');
    argParser.addOption('output',
        abbr: 'o',
        help: 'Output directory.',
        valueHelp: 'path',
        defaultsTo: '<stdout>');
    argParser.addOption('md5',
        help: 'Use MD5 hash of input or output as file name.\n'
        'If this options is turned `off` the files will be numbered '
        'consecutively.',
        valueHelp: 'mode',
        allowed: ['off', 'input', 'output'],
        defaultsTo: 'output');
  }

  @override
  String get name => 'render';

  @override
  String get description =>
      'Converts a structure formula to an image using Graph::Easy or Graphviz.';

  /// Whether the output format is `txt`.
  bool get isText => argResults['format'] == 'txt';

  /// Creates an unique filename for the output.
  ///
  /// The file is located in the `--output` directory.
  /// Returns `null` if the output should be redirected to `stdout`.
  String makeFileName(String input, List<int> output) {
    if (argResults['output'] == '<stdout>') return null;
    var name = '${++_fileCounter}';
    if (argResults['md5'] != 'off') {
      var md5 = new MD5();
      md5.add(argResults['md5'] == 'output' ? output : input.codeUnits);
      name = CryptoUtils.bytesToHex(md5.close());
    }
    return '${argResults['output']}/$name.${argResults['format']}';
  }
  int _fileCounter = 0;

  /// Creates a new exeternal process for the rendering.
  Future<Process> spawnRenderer() {
    var exe = argResults['renderer'];
    var args = [];
    if (isText) {
      exe = 'graph-easy';
      args.add('--boxart');
    } else {
      args.add('-T${argResults['format']}');
    }
    return Process.start(exe, args);
  }

  /// Spawns the renderer, feeds it with the [graph] on `stdin` and passes the
  /// `stdout` of the process to [output].
  Future render(String graph) async {
    var process = await spawnRenderer();
    var bytes = [];
    process.stdout.listen(bytes.addAll, onDone: () {
      output(makeFileName(graph, bytes), bytes);
    });
    return process.stdin
      ..write(graph)
      ..close();
  }

  /// Writes the output of a renderer to a file.
  ///
  /// If [filename] is `null` the otput is redirected to `stdout`.
  void output(String filename, List<int> bytes) {
    if (isText) {
      // Because Graph::Easy does not understand HTML we have to style the
      // output afterwards.
      var txt = UTF8.decode(bytes);
      var pattern = new RegExp('([A-Z][a-z]*)([1-9][0-9]*)?');
      txt = txt.replaceAllMapped(pattern, (Match m) {
        var sum = new SumFormula(
            {new Element(m[1]): m[2] == null ? 1 : int.parse(m[2])});
        return sum.toString(
            color: argResults['color'], subscript: argResults['subscript']);
      });
      bytes = UTF8.encode(txt);
    }

    if (filename == null) {
      stdout.add(bytes);
    } else {
      var f = new File(filename);
      f.writeAsBytes(bytes);
    }
  }

  @override
  Stream<Message> run() async* {
    // Create output directory if it does not exist.
    if (argResults['output'] != '<stdout>') {
      new Directory(argResults['output'])..createSync();
    }

    // Encode every molecule as a DOT graph.
    var sticky = new Set();
    if (!argResults['no-sticky']) {
      sticky.addAll(argResults['sticky'].map((s) => new Element(s)));
    }

    var encoder = new DotEncoder(
        sticky: sticky,
        color: !isText && argResults['color'],
        subscript: !isText && argResults['subscript'],
        bg: argResults['bg'],
        fg: argResults['fg'],
        dpi: int.parse(argResults['dpi']));

    var graphs = input.map(Molecule.parse).map(encoder.encode);
    await for (var future in graphs.map(render)) {
      await future;
    }
  }
}
