// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.algo.compare;

import 'package:isomers/chem.dart';
import 'package:quiver/iterables.dart';

/// Object which compares two molecules.
abstract class MoleculeComparator {

  /// The first molecule.
  final Molecule first;

  /// The second molecule.
  final Molecule second;

  MoleculeComparator({this.first, this.second});

  /// Tests whether there is a combination of atoms from [first] and [second]
  /// for which [compare] is `true`.
  bool compareAll([Atom pivotA, Atom pivotB]) {
    if (pivotA == null) return first.atoms.any((a) => compareAll(a, pivotB));
    if (pivotB == null) return second.atoms.any((b) => compareAll(pivotA, b));
    return compare(pivotA, pivotB);
  }

  /// Tests two atoms for chemical equality.
  ///
  /// [a] is an atom of the [first] molecule.
  /// [b] is an atom of the [second] molecule.
  /// [preA] and [preB] are a neighbors of [a] and [b] respectively. They will
  /// not be compared.
  bool compare(Atom a, Atom b, {Atom preA, Atom preB}) {
    if (a.element != b.element) return false;

    var ans = first.neighbors(a).toSet()..remove(preA);
    var bns = second.neighbors(b).toSet()..remove(preB);
    if (!compareMatrixSize(width: ans.length, height: bns.length)) return false;

    var matrix = bns.map((Atom bn) {
      return ans.map((Atom an) {
        return compare(an, bn, preA: a, preB: b);
      });
    });

    return compareMatrix(matrix);
  }

  bool compareMatrix(Iterable<Iterable<bool>> matrix) {
    if (matrix.isEmpty) return true;
    var col = -1;
    var row = matrix.first.toList();
    while (true) {
      col = row.indexOf(true, col + 1);
      if (col == -1) break;
      var subMatrix = matrix
          .skip(1)
          .map((row) => concat([row.take(col), row.skip(col + 1)]));
      if (compareMatrix(subMatrix)) return true;
    }
    return false;
  }

  bool compareMatrixSize({int width, int height});
}

/// A [MoleculeComparator] which tests whether the two molecules are equal.
class FullMoleculeComparator extends MoleculeComparator {
  factory FullMoleculeComparator(Molecule molecule, [Molecule other]) {
    if (other == null) other = molecule;
    return new FullMoleculeComparator._(first: molecule, second: other);
  }

  FullMoleculeComparator._({Molecule first, Molecule second})
      : super(first: first, second: second);

  @override
  bool compareAll([Atom pivotA, Atom pivotB]) {
    if (first.atoms.length != second.atoms.length ||
        first.bonds.length != second.bonds.length) {
      return false;
    }
    return super.compareAll(pivotA, pivotB);
  }

  @override
  bool compareMatrixSize({int width, int height}) => width == height;
}

/// A [MoleculeComparator] which tests whether the first molecule contains the
/// second molecule.
class PartialMoleculeComparator extends MoleculeComparator {
  factory PartialMoleculeComparator(Molecule molecule, [Molecule other]) {
    if (other == null) other = molecule;
    return new PartialMoleculeComparator._(first: molecule, second: other);
  }

  PartialMoleculeComparator._({Molecule first, Molecule second})
      : super(first: first, second: second);

  @override
  bool compareAll([Atom pivotA, Atom pivotB]) {
    if (first.atoms.length < second.atoms.length ||
        first.bonds.length < second.bonds.length) {
      return false;
    }
    return super.compareAll(pivotA, pivotB);
  }

  @override
  bool compareMatrixSize({int width, int height}) => width >= height;
}
