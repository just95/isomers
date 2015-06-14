// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of isomers.chem;

/// The sum formula of a molecule.
class SumFormula {

  /// Unicode subscript character by ASCII digit.
  static final Map<String, String> subscriptTable = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉'
  };

  /// Parser of [parse].
  static final _parser = new SumFormulaParser();

  /// Parses a sum formula.
  static SumFormula parse(String sum) => _parser.parse(sum).value;

  /// Number of elements by type.
  final Map<Element, int> elements;

  SumFormula(this.elements);

  /// Adds [n] atoms of the given [element] to the formula.
  void add(Element element, [int n = 1]) {
    elements.putIfAbsent(element, () => 0);
    elements[element] += n;
  }

  @override
  bool operator ==(SumFormula other) => mapsEqual(elements, other.elements);

  @override
  int get hashCode => hashObjects(concat(elements.keys
      .map((element) => [element.number, elements[element]])
      .toList()..sort((a, b) => b[0] - a[0])));

  @override
  String toString(
      {bool color: false, bool subscript: false, bool html: false}) {
    var ret = new StringBuffer();
    elements.forEach((Element element, int n) {
      var str = element.symbol;
      if (n > 1) str += '$n';
      if (subscript) {
        str = str.replaceAllMapped(new RegExp(r'[0-9]'), (Match m) {
          if (html) return '<SUB>${m[0]}</SUB>';
          return subscriptTable[m[0]];
        });
      }
      if (color) {
        if (html) {
          str = '<FONT COLOR="${element.color.hex}">$str</FONT>';
        } else {
          str = element.pen(str);
        }
      }
      ret.write(str);
    });
    return '$ret';
  }
}
