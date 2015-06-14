// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of isomers.chem;

/// A single atom.
class Atom {

  /// The type of the atom.
  final Element element;

  Atom(this.element);

  /// Gets the maximum number of bonds for this atom.
  int get maxBonds => 4 - (element.mainGroup - 4).abs();
}
