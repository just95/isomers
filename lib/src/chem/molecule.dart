// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of isomers.chem;

/// An undirected acyclic graph of [Atom]s.
class Molecule {

  /// Parser of [parse].
  static final _parser = new StructureFormulaParser();

  /// Converts a string to a molecule.
  static Molecule parse(String structure) => _parser.parse(structure).value;

  /// The atoms which belong to this molecule.
  final Set<Atom> atoms = new Set();

  /// The bonds of this molecule.
  final Set<Bond> bonds = new Set();

  Molecule();

  /// Creates a shallow copy of the [other] molecule.
  Molecule.from(Molecule other) {
    atoms.addAll(other.atoms);
    bonds.addAll(other.bonds);
  }

  /// Creates a deep copy of the [other] molecule.
  Molecule.clone(Molecule other) {
    var table = {};
    other.atoms.forEach((Atom atom) {
      table[atom] = addAtom(atom.element);
    });
    other.bonds.forEach((Bond bond) {
      addBond(table[bond.first], table[bond.second]);
    });
  }

  /// Creates a shallow copy of the [other] molecule and adds the [placeholder]
  /// to every atom where possible.
  factory Molecule.fill(Molecule other, Element placeholder) {
    var molecule = new Molecule.from(other);
    for (Atom atom in other.atoms) {
      while (molecule.canBeBond(atom)) {
        var hydrogen = molecule.addAtom(placeholder);
        molecule.addBond(atom, hydrogen);
      }
    }
    return molecule;
  }

  /// The sum formula of this molecule.
  SumFormula get sum {
    var sum = new SumFormula({});
    atoms.forEach((Atom atom) {
      sum.add(atom.element);
    });
    return sum;
  }

  @override
  bool operator ==(Molecule other) =>
      setsEqual(atoms, other.atoms) && setsEqual(bonds, other.bonds);

  @override
  int get hashCode => hashObjects(concat([atoms, bonds]));

  /// Tests whether this molecule is chemically equal to the [other] molecule.
  bool equals(Molecule other, [Atom pivotA, Atom pivotB]) {
    var comparator = new FullMoleculeComparator(this, other);
    return comparator.compareAll(pivotA, pivotB);
  }

  /// Tests whether this molecule is contains the [other] molecule.
  bool contains(Molecule other, [Atom pivotA, Atom pivotB]) {
    var comparator = new PartialMoleculeComparator(this, other);
    return comparator.compareAll(pivotA, pivotB);
  }

  /// Adds a new atom of the specified type to the molecule.
  Atom addAtom(Element element) {
    var atom = new Atom(element);
    atoms.add(atom);
    return atom;
  }

  /// Adds a bound between two atoms.
  Bond addBond(Atom first, Atom second) {
    var bond = new Bond(first, second);
    bonds.add(bond);
    return bond;
  }

  /// Gets all bonds of [atom].
  Iterable<Bond> bondsOf(Atom atom) sync* {
    for (Bond bond in bonds) {
      if (bond.first == atom || bond.second == atom) yield bond;
    }
  }

  /// Tests whether [atom] can be bond to another atom.
  bool canBeBond(Atom atom) => bondsOf(atom).length < atom.maxBonds;

  /// Gets the adjacent atoms of [atom].
  Iterable<Atom> neighbors(Atom atom) sync* {
    for (Bond bond in bonds) {
      if (bond.first == atom) {
        yield bond.second;
      } else if (bond.second == atom) {
        yield bond.first;
      }
    }
  }

  /// Finds all carbon chains adjacent to the specified [atom].
  Iterable<List<Atom>> chains(Atom atom) {
    var seen = new Set();
    Iterable<List<Atom>> _chains(Atom a) sync* {
      if (a.element.symbol == 'C' && !seen.contains(a)) {
        seen.add(a);

        for (Atom n in neighbors(a)) {
          yield* _chains(n).map((c) => concat([[a], c]));
        }
        yield [a];
      }
    }
    return _chains(atom);
  }

  /// The sum formula for this molecule.
  SumFormula get sumFormula {
    var sum = new SumFormula({});
    atoms.map((a) => a.element).forEach(sum.add);
    return sum;
  }

  @override
  String toString() {
    var seen = new Set();
    String stringify(Atom atom) {
      seen.add(atom);

      var str = atom.element.symbol;
      var nbs = neighbors(atom).where((n) => !seen.contains(n));
      if (nbs.isNotEmpty) {
        var count = {};
        nbs.map(stringify).forEach((String nstr) {
          count.putIfAbsent(nstr, () => 0);
          count[nstr]++;
        });
        str += '{' + count.keys.map((String nstr) {
          if (count[nstr] == 1) return nstr;
          return '$nstr${count[nstr]}';
        }).join(',') + '}';
      }
      return str;
    }

    return stringify(atoms.first);
  }
}
