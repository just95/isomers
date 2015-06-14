// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

library isomers.src.algo.hnmr;

import 'package:isomers/chem.dart';

import 'compare.dart';

/// Result of the [HnmrPredictor].
class HnmrPrediction {

  /// The molecule for which the prediction was done.
  final Molecule molecule;

  /// The predicted splitting pattern of the peaks.
  final List<int> pattern;

  HnmrPrediction({this.molecule, this.pattern});

  /// The predicted number of resonances.
  int get peaks => pattern.length;

  @override
  String toString() => '$molecule // ${pattern.join(',')}';
}

/// The H-NMR spectrum prediction engine.
class HnmrPredictor {

  /// Predicts certain properties of the H-NMR spectrum for [molecule].
  ///
  /// The method can currently only predict the splitting pattern of the
  /// peaks.
  HnmrPrediction predict(Molecule molecule) {
    var comparator = new FullMoleculeComparator(molecule);

    // Find sets of H atoms which are chemically equal.
    var different = [];
    molecule.atoms.where((a) => a.element.symbol == 'H').forEach((Atom h) {
      // Find a set in `different` which contains a H atom equal to `h`
      var equal = different.firstWhere((Set<Atom> set) {
        return comparator.compare(set.first, h);
      }, orElse: () {
        // If there is no such set create it and add it to `different`.
        var set = new Set();
        different.add(set);
        return set;
      });
      equal.add(h);
    });

    // Count neighboring H atoms of each of the different H atoms.
    var pattern = [];
    different.forEach((Set<Atom> equal) {
      // Counting for the first is sufficient because they are all equal anyway.
      var h = equal.first;
      var c = molecule.neighbors(h).first;

      var neighbors = molecule.neighbors(c);
      var environment = neighbors.expand(molecule.neighbors);
      var hydrogen = environment.where((a) => a.element.symbol == 'H');

      // The multiplicity of an absorption is equal to the number of
      // neighboring H atoms plus one.
      pattern.add(hydrogen.length + 1);
    });

    pattern.sort();
    return new HnmrPrediction(molecule: molecule, pattern: pattern);
  }
}

/// Filter of [HnmrPrediction]s.
class HnmrFilter {

  /// The expected number of peaks.
  final int peaks;

  /// The expected splitting pattern.
  final List<int> pattern;

  /// Number of peaks which do not have to match [pattern].
  final int wildcards;

  /// Whether the exact number of peaks is irrelevant.
  final bool ellipses;

  factory HnmrFilter.from(List<String> filter) {
    var ellipses = filter.isNotEmpty && filter.last == '...';
    if (ellipses) filter.removeLast();

    var wildcards = filter.where((e) => e == '*').toList();
    wildcards.forEach(filter.remove);

    return new HnmrFilter(
        peaks: filter.length + wildcards.length,
        pattern: filter.map(int.parse).toList(),
        wildcards: wildcards.length,
        ellipses: ellipses);
  }

  HnmrFilter({this.peaks, this.pattern, this.wildcards, this.ellipses});

  /// Tests whether [prediction] matches the conditions.
  bool filter(HnmrPrediction prediction) {
    if (peaks == 0) return true;
    if (ellipses ? prediction.peaks < peaks : prediction.peaks != peaks) {
      return false;
    }

    var remaining = prediction.pattern.toList();
    if (!pattern.every(remaining.remove)) return false;

    return ellipses || remaining.length == wildcards;
  }

  /// This object can be used like a function.
  ///
  /// Passes its only argument to the [filter] method.
  bool call(HnmrPrediction prediction) => filter(prediction);
}
