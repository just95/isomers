// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of isomers.chem;

/// An edge of the molecule graph.
class Bond {

  /// The first node.
  final Atom first;

  /// The second none.
  final Atom second;

  Bond(this.first, this.second);

  @override
  bool operator ==(Bond other) {
    // Bonds are undirected.
    return first == other.first && second == other.second ||
        second == other.first && first == other.second;
  }

  @override
  int get hashCode => first.hashCode + second.hashCode;
}
