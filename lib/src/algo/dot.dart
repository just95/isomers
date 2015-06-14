// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.algo.dot;

import 'package:isomers/chem.dart';

/// DOT language encoder.
class DotEncoder {

  /// The elements for which no new node will be created.
  final Set<Element> sticky;

  /// Whether to colorize the graph.
  final bool color;

  /// Whether to print numbers as subscripts.
  final bool subscript;

  /// The background color.
  final String bg;

  /// The foreground color.
  final String fg;

  /// Dots per inch.
  final int dpi;

  DotEncoder({this.sticky, this.bg: 'transparent', this.fg: 'black',
      this.dpi: 96, this.color: true, this.subscript: true}) {
    sticky.forEach((Element s) {
      if (s.mainGroup != 1 && s.mainGroup != 7) {
        throw '${s.name} is in main group ${s.mainGroup} and can therefore'
            'not be sticky!';
      }
    });
  }

  /// Creates a DOT grapgh for a [molecule].
  String encode(Molecule molecule) {
    var str = new StringBuffer();
    str.write('graph molecule {');
    str.write('graph [dpi=$dpi bgcolor="$bg" truecolor=true];');
    str.write('edge [color="$fg"];');
    str.write('node [fontcolor="$fg" shape=plaintext];');

    Map<Atom, String> ids = {};
    Map<String, int> counter = {};
    molecule.atoms.forEach((Atom atom) {
      if (sticky.contains(atom.element)) return;

      var symbol = atom.element.symbol;
      if (!counter.containsKey(symbol)) counter[symbol] = 0;

      var id = '$symbol${++counter[symbol]}';
      ids[atom] = id;

      var sum = new SumFormula({atom.element: 1});
      molecule
          .neighbors(atom)
          .map((n) => n.element)
          .where(sticky.contains)
          .forEach(sum.add);

      var label = sum.toString(html: true, color: color, subscript: subscript);
      var attrs = ['label=<$label>'];
      str.write('$id [${attrs.join(' ')}];');
    });

    List<List<Atom>> chains(Atom atom, {Atom pre}) {
      var ret = [];
      for (Atom neighbor in molecule.neighbors(atom)) {
        if (neighbor == pre) continue;
        var cs = chains(neighbor, pre: atom);
        cs.fold([], (a, b) {
          if (a.length > b.length) return a;
          return b;
        }).insert(0, atom);
        ret.addAll(cs);
      }
      if (ret.isEmpty && !sticky.contains(atom.element)) return [[atom]];
      return ret;
    }
    if (molecule.atoms.isNotEmpty) {
      chains(molecule.atoms.first).forEach((List<Atom> chain) {
        str.write(chain.map((atom) => ids[atom]).join(' -- '));
        str.write(';');
      });
    }

    str.write('}');
    return str.toString();
  }
}
