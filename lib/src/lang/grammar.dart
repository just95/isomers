// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of isomers.lang;

/// Grammar for chemical formulas.
abstract class ChemGrammar extends GrammarDefinition {

  /// A comment.
  Parser comment() => ref(lineComment) | ref(blockComment);

  /// A single line comment.
  Parser lineComment() => string('//') & char('\n').neg().star();

  /// A multiline comment.
  Parser blockComment() =>
      string('/*') & string('*/').neg().star() & string('*/');

  /// Whitespace or comment.
  Parser ignore() => (whitespace() | ref(comment)).plus();

  /// A whitespace and comment ignoring token.
  Parser token(String str) => string(str).trim(ref(ignore));

  /// Structure formula.
  Parser structure() => ref(element) & ref(neighbors).optional(const []);

  /// List of adjacent elements.
  Parser neighbors() => token('{') &
      ref(neighbor).separatedBy(token(','), includeSeparators: false) &
      token('}');

  /// An adjacent structure.
  Parser neighbor() => ref(summand, ref(structure));

  /// Sum formula.
  Parser sum() => ref(summand, ref(element)).plus();

  /// A [p] plus an optional [number] which defaults to `1`.
  Parser summand(Parser p) => p & ref(number).optional(1);

  /// The symbol of an element.
  Parser element() => pattern('A-Z') & pattern('a-z').star();

  /// An integer.
  Parser number() => pattern('1-9') & pattern('0-9').star();
}
