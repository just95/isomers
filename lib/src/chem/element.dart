// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of isomers.chem;

/// Color of an atom.
class Color {
  /// The red component of the color.
  final num r;

  /// The green component of the color.
  final num g;

  /// The blue component of the color.
  final num b;

  const Color({this.r, this.g, this.b});

  /// The color in the format `#RRGGBB`.
  String get hex {
    var RR = (r * 255).floor().toRadixString(16).padLeft(2, '0');
    var GG = (g * 255).floor().toRadixString(16).padLeft(2, '0');
    var BB = (b * 255).floor().toRadixString(16).padLeft(2, '0');
    return '#$RR$GG$BB';
  }
}

/// A chemical element.
class Element {

  /// Instances of this class by [symbol].
  static Map<String, Element> _instances = {};

  /// Creates the instances of this class from configuration options.
  static void init(Map cfg) {
    cfg.forEach((String symbol, Map options) {
      _instances[symbol] = new Element._(symbol,
          name: options['name'],
          number: options['number'],
          mainGroup: options['main_group'],
          color: new Color(
              r: options['color']['r'],
              g: options['color']['g'],
              b: options['color']['b']));
    });
  }

  /// The chemical symbol of this element.
  final String symbol;

  /// The name of this element.
  final String name;

  /// The atomic number of this element.
  final int number;

  /// The main group of this element.
  final int mainGroup;

  /// The color of this atom.
  final Color color;

  Element._(this.symbol, {this.name, this.number, this.mainGroup, this.color});

  factory Element(String symbol) {
    if (_instances.containsKey(symbol)) return _instances[symbol];
    throw 'Unknown element: $symbol';
  }

  /// An [AnsiPen] for the [color] of this element.
  AnsiPen get pen => new AnsiPen()..rgb(r: color.r, g: color.g, b: color.b);
}
