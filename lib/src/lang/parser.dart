// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of isomers.lang;

/// Definition of [SumFormulaParser].
class SumFormulaParserDefinition extends ChemGrammar {
  Parser start() => ref(sum).trim(ref(ignore)).end();

  @override
  Parser sum() => super.sum().map((List args) {
    var sum = new SumFormula({});
    args.forEach((List pair) => sum.add(pair[0], pair[1]));
    return sum;
  });
  
  @override
  Parser element() =>
      super.element().flatten().map((String symbol) => new Element(symbol));

  @override
  Parser number() => super.number().flatten().map(int.parse);
}

/// Parser for [SumFormula]s
class SumFormulaParser extends GrammarParser {
  SumFormulaParser() : super(new SumFormulaParserDefinition());
}

/// Definition of [StructureFormulaParser].
class StructureFormulaParserDefinition extends SumFormulaParserDefinition {
  Parser start() => ref(structure).trim(ref(ignore)).end();
  
  @override
  Parser structure() => super.structure().map((List args) {
    var molecule = new Molecule();
    molecule.addAtom(args[0]);
    args[1].forEach((List summand) {
      for (var i = 0; i < summand[1]; i++) {
        var neighbor = new Molecule.clone(summand[0]);
        molecule.atoms.addAll(neighbor.atoms);
        molecule.bonds.addAll(neighbor.bonds);
        molecule.addBond(molecule.atoms.first, neighbor.atoms.first);
      }
    });
    return molecule;
  });
  
  @override
  Parser neighbors() => super.neighbors().pick(1);
}

/// Parser for [Molecule]s
class StructureFormulaParser extends GrammarParser {
  StructureFormulaParser() : super(new StructureFormulaParserDefinition());
}
