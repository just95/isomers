// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

import 'dart:async';
import 'dart:html' as dom;
import 'dart:isolate';

import 'package:bootjack/bootjack.dart';
import 'package:graphviz/graphviz.dart';
import 'package:isomers/isolate.dart';
import 'package:isomers/app.dart';
import 'package:isomers/chem.dart';
import 'package:isomers/message.dart';
import 'package:isomers/src/algo/dot.dart';
import 'package:toml/loader/http.dart';

/* Isolates. */

/// The application used by [run].
Application get app => _app;
void set app(Application app) {
  _app = app;
  app.init();
}
Application _app;

/// Runs a command in an isolate.
Stream<Message> run(List<String> args) async* {
  var port = new ReceivePort();
  var msg = new IsolateInterface(app: app, port: port.sendPort);

  Isolate.spawnUri(Uri.parse('isolate.dart'), args, msg.serialize());
  await for (Map msg in port) {
    if (msg == null) break;
    yield new Message(msg['data'], type: MessageType.values[msg['type']]);
  }
}

/* Element access. */

/// Finds the first descendant element of [root] that matches the specified
/// group of [selectors].
///
/// [root] defaults to the `<body>` of the current document.
dom.Element $(String selectors, [dom.Element root]) {
  if (root == null) root = dom.document.body;
  return root.querySelector(selectors);
}

/// Like [$], but returns an `<input>` element.
dom.InputElement $in(String selectors, [dom.Element root]) =>
    $(selectors, root);

/// Finds all descendant element of [root] that match the specified group of
/// [selectors].
///
/// [root] defaults to the `<body>` of the current document.
dom.ElementList<dom.Element> $$(String selectors, [dom.Element root]) {
  if (root == null) root = dom.document.body;
  return root.querySelectorAll(selectors);
}

/// A node validator which allows every element and every attribute.
///
/// Note: Use this validator only if you trust the input source.
class PermissiveValidator implements dom.NodeValidator {
  @override
  bool allowsAttribute(
      dom.Element element, String attributeName, String value) => true;

  @override
  bool allowsElement(dom.Element element) => true;
}

/* Search. */

/// Entry of the list of search results.
class SearchResult {

  /// Template for [element].
  static final String template = '''
    <div class="collapse search-result">
      <input type="text" class="form-control search-result-label" 
             placeholder="Label..." required />
      <a class="close">&times;</a>
      <div class="molecule"></div>
    </div>
  ''';

  /// The user interface of this search result.
  final dom.Element element = new dom.Element.html(template);

  /// The isomer which was found.
  final Molecule isomer;

  SearchResult(this.isomer, {String label: ''}) {
    this.label = label;
    $('.close', element).onClick.listen((_) async {
      results.remove(this);
      hide();
      await new Future.delayed(const Duration(milliseconds: 500));
      element.remove();
    });
  }

  /// A label defined by the user.
  String get label => $in('.search-result-label', element).value;

  /// A label defined by the user.
  void set label(String label) {
    $in('.search-result-label', element).value = label;
  }

  /// Shows the [element].
  Future show() {
    Collapse.wire(element).show();
    return new Future.delayed(const Duration(milliseconds: 350));
  }

  /// Hides the [element].
  Future hide() {
    Collapse.wire(element).hide();
    return new Future.delayed(const Duration(milliseconds: 350));
  }

  /// The `.molecule` container.
  dom.Element get svgElementContainer => $('.molecule', element);

  /// Converts [isomer] to a SVG image and updates [svgElementContainer].
  Future render() async {
    var dot = _encoder.encode(isomer);
    var svg = await _graphviz.layout(dot, layout: _layoutEngine);
    var elem = new dom.Element.html(svg, validator: new PermissiveValidator());

    if (svgElementContainer.children.isEmpty) {
      svgElementContainer.append(elem);
    } else {
      svgElementContainer.children.first.replaceWith(elem);
    }

    await new Future.delayed(const Duration(milliseconds: 500));
  }

  /// The graphviz worker used by [render].
  static final Graphviz _graphviz = new Graphviz();

  /// The encoder used by [render] to convert [isomer] to a DOT graph.
  static DotEncoder get _encoder => new DotEncoder(
      sticky: $in('#enable-sticky-hydrogen').checked
          ? [new Element('H')].toSet()
          : new Set(),
      color: $in('#enable-color').checked);

  /// The layout engine used by [render].
  static Layout get _layoutEngine =>
      $in('#enable-tree-rendering').checked ? Layout.DOT : Layout.NEATO;
}

/// Runs the `find` command on [input] in a new isolate.
Stream<SearchResult> search(String input) async* {
  var args = ['find'];
  if ($in('#enable-add-hydrogen').checked) args.add('-H');
  args.add(input);

  await for (Message msg in run(args)) {
    if (msg.type == MessageType.DEFAULT) {
      var isomer = Molecule.parse(msg.data);
      yield new SearchResult(isomer);
    } else {
      showMessage(msg);
      break;
    }
  }
}

/// Cache of [search].
List<SearchResult> results = [];

Future addSearchResult(SearchResult result) async {
  results.add(result);
  await result.render();
  $('#search-results').append(result.element);
  result.show();
}

/// Removes all search results and resets the error message.
void clear() {
  clearMessage();
  results.clear();
  $('#search-results').innerHtml = '';
}

/* Error handling. */

/// Displays a message.
void showMessage(Message msg) {
  $('#search-form label').text = msg.data;
  $('#search-form .form-group').classes
      ..toggle('has-error', msg.type == MessageType.ERROR)
      ..toggle('has-warning', msg.type == MessageType.WARNING)
      ..toggle('has-info', msg.type == MessageType.INFO)
      ..toggle('has-success', msg.type == MessageType.SUCCESS);
}

/// Removes the current message.
void clearMessage() => showMessage(new Message(''));

/* Loading screen. */

/// Shows the loading screen.
///
/// Returns `false` if the loading screen was visible already.
bool startLoading() => $('#loading').classes.add('in');

/// Hides the loading screen.
///
/// Returns `false` if the loading screen has not been visible.
bool stopLoading() => $('#loading').classes.remove('in');

/* Import/Export */

/// The name of the exportable file.
///
/// Set by [import] and [searchHandler].
String get filename => _filename;
void set filename(String filename) {
  _filename = filename;
}
String _filename = 'unnamed.isomers';

/// Imports molecules from [file].
///
/// Each line of the file contains the structure formula of one molecule.
Future import(dom.File file) async {
  filename = file.name;

  var reader = new dom.FileReader();
  reader.readAsText(file);
  await reader.onLoad.first;
  String str = reader.result;

  var results = str.split('\n').where((line) => line.isNotEmpty).map((line) {
    var molecule = Molecule.parse(line);
    var label = '';
    var comment = line.indexOf('//');
    if (comment != -1) {
      label = line.substring(comment + 2).trim();
    }
    return new SearchResult(molecule, label: label);
  });

  clear();
  await Future.wait(results.map(addSearchResult));
}

/* Event handlers. */

/// Downloads the search results.
void exportHandler() {
  if (results.isEmpty) throw 'Nothing to export.';
  var data = results
      .map((result) => result.label.isEmpty
          ? '${result.isomer}'
          : '${result.isomer} // ${result.label}')
      .join('\n');
  var uri = 'data:text/plain;charset=utf-8,${Uri.encodeComponent(data)}';

  var a = new dom.Element.a();
  a.download = filename;
  a.href = uri;
  a.click();
}

/// Asks the user to select a file.
///
/// The contents of the file are then rendered.
void importHandler() {
  var input = new dom.InputElement(type: 'file');
  input.click();
  input.onChange.listen((_) async {
    startLoading();
    await import(input.files.first);
    stopLoading();
  });
}

/// Finds and displays the search [results] for the current input.
Future searchHandler() async {
  clear();
  var input = $in('#search-form input');
  filename = '$input.isomers';
  try {
    input.blur();
    var futures = [];
    await for (SearchResult result in search(input.value)) {
      futures.add(addSearchResult(result));
    }
    await Future.wait(futures);
  } finally {
    input.focus();
  }
}

/// Redraws all search [results].
Future rerenderHandler() =>
    Future.wait(results.map((result) => result.render()));

/// Wraps an event [handler].
///
/// The default action of the event is prevented and the loading screen visible
/// while the operation is pending.
Function action(Function handler) {
  return (dom.Event evt) async {
    evt.preventDefault();
    startLoading();
    try {
      await handler();
    } catch (e) {
      showMessage(new Message.error('Error: $e'));
    }
    stopLoading();
  };
}

Future main() async {
  Transition.use();
  Collapse.use();
  Dropdown.use();
  Modal.use();

  HttpConfigLoader.use();
  app = await createApplication(disabledCommands: ['render']);

  $('#export').onClick.listen(action(exportHandler));
  $('#import').onClick.listen(action(importHandler));
  $('#search-form').onSubmit.listen(action(searchHandler));
  $('#rerender').onClick.listen(action(rerenderHandler));
  $$('.toggle-active').forEach((dom.Element elem) {
    elem.onClick.listen((_) => elem.classes.toggle('active'));
  });

  var query = Uri.parse(dom.window.location.search).queryParameters;
  if (query.containsKey('q')) {
    $in('#search-form input').value = query['q'];
    try {
      await searchHandler();
    } catch (e) {
      showMessage(new Message.error('Error: $e'));
    }
  }
  stopLoading();
}
