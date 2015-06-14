// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.algo.isomers;

import 'dart:async';

import 'package:isomers/chem.dart';

Stream<Molecule> _isomers(Atom seed, Map<Element, int> elements,
    Molecule molecule, Map<SumFormula, List<Molecule>> seen) async* {
  var seenSameSum = seen.putIfAbsent(molecule.sum, () => []);
  if (!seenSameSum.any((s) => molecule.equals(s, seed))) {
    var mol = new Molecule.from(molecule);
    seenSameSum.add(mol);

    if (elements.values.every((value) => value == 0)) {
      yield mol;
    } else {
      for (var element in elements.keys) {
        if (elements[element] == 0) continue;
        --elements[element];
        var added = molecule.addAtom(element);
        var any = false;
        for (var atom in molecule.atoms.toList().reversed) {
          if (atom == added || !molecule.canBeBond(atom)) continue;
          var bond = molecule.addBond(atom, added);
          yield* _isomers(seed, elements, molecule, seen).map((isomer) {
            any = true;
            return isomer;
          });
          molecule.bonds.remove(bond);
        }
        molecule.atoms.remove(added);
        ++elements[element];
        if (any) break;
      }
    }
  }
}

/// Yields all unique isomers with the specified sum formula.
Stream<Molecule> isomers(SumFormula sum, {bool addHydrogen: false}) {
  final Element H = new Element('H');
  if (addHydrogen) {
    var hydrogen = sum.elements.remove(H);
    return isomers(sum).map((Molecule isomer) {
      isomer = new Molecule.fill(isomer, H);
      if (hydrogen != null &&
          isomer.atoms.where((a) => a.element == H).length != hydrogen) {
        return null;
      }
      return isomer;
    }).where((isomer) => isomer != null);
  } else {
    var elements = new Map.from(sum.elements);

    var molecule = new Molecule();
    var seed = molecule.addAtom(elements.keys.first);
    --elements[seed.element];

    var seen = {};
    return _isomers(seed, elements, molecule, seen);
  }
}
