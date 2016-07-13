// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;


DivElement newCodePanel(String title) {
  DivElement panel = newEmptyPanel(
    style: {'width': '600px', 'height': '400px', 'left': 'calc((100% - 604px)/2)', 'top': 'calc((100% - 400px)/2)'},
    withResizeControls: true);
  panel
      ..classes.add('code-panel')
      ..style.display = 'flex'
      ..style.flexFlow = 'column';
  addTitleBarButtonsToElement(panel, unfoldButton: true, closeButton: true);
  componentHandler().upgradeElement(panel);
  panel.append(new HeadingElement.h1()
      ..classes.add('panel-title')
      ..style.flex = '0 1 auto'
      ..text = title);
  panel.append(new DivElement()
      ..classes.add('code')
      ..style.flex = '1 1 auto');
  return panel;
}

DivElement newInputOutputPanel(String title, String id) {
  DivElement panel = newEmptyPanel(id: id, withResizeControls: true);
  panel.classes.add('panel');
  addTitleBarButtonsToElement(panel, unfoldButton: true, closeButton: true);
  componentHandler().upgradeElement(panel);
  panel.append(new HeadingElement.h1()
      ..classes.add('panel-title')
      ..text = title);
  panel.append(new DivElement()
      ..classes.add('card-contents')
      ..append(new PreElement()));
  return panel;
}

DivElement newChartPanel(String id) {
  DivElement panel = newEmptyPanel(id: id, withResizeControls: true);
  panel.classes.add('panel');
  addTitleBarButtonsToElement(panel, unfoldButton: true, closeButton: true);
  componentHandler().upgradeElement(panel);

  DivElement cardContents = new DivElement()..classes.add('card-contents');
  cardContents.innerHtml ="""<select class="type-menu" name="type-menu">
    <option value="scatter">Scatter plot</option>
    <option value="bar">Bar chart</option>
  </select>
  <select class="x-axis-menu" name="x-axis-menu"></select>
  <select class="y-axis-menu" name="y-axis-menu"></select>
  <select class="sort-axis-menu" name="sort-axis-menu">
    <option value="unsort" selected>Unsorted</option>
    <option value="x-asc">Sort by x axis ascending</option>
    <option value="x-desc">Sort by x axis descending</option>
    <option value="y-asc">Sort by y axis ascending</option>
    <option value="y-desc">Sort by y axis descending</option>
  </select>
  <div class="chart-container"></div>""";
  panel.append(cardContents);
  return panel;
}

DivElement newEmptyPanel({String id, Map<String, String> style, bool withResizeControls: false}) {
  String idAttribute = id != null && id.length > 0 ? "id=\"$id\"" : "";
  StringBuffer styleAttributeBuffer = new StringBuffer("style=\"");
  if (style != null) {
    style.forEach((String param, String value) => styleAttributeBuffer.write('$param: $value;'));
  }
  styleAttributeBuffer.write('\"');
  String resizeControls = withResizeControls ?
      """<div class="resize-controls">
          <div class="top-left"></div><div class="top-right"></div><div class="bottom-left"></div><div class="bottom-right"></div>
          <div class="top"></div><div class="right"></div><div class="left"></div><div class="bottom"></div>
         </div>""" : "";
  return new Element.html("""<div $idAttribute ${styleAttributeBuffer.toString()} class="panel mdl-panel mdl-panel--shadow"> $resizeControls </div>""",
      validator: new NodeValidatorBuilder()
          ..allowHtml5()
          ..allowInlineStyles());
}

void addTitleBarButtonsToElement(DivElement panel, {bool unfoldButton: false, bool closeButton: false}) {
  String htmlToAppend = '<div class="title-bar-buttons">';
  htmlToAppend += (unfoldButton ? '<button class="mdl-button mdl-js-button mdl-button--icon icon--fold-unfold"><i class="material-icons">unfold_less</i></button>' : '');
  htmlToAppend += (unfoldButton ? '<button class="mdl-button mdl-js-button mdl-button--icon icon--close"><i class="material-icons">close</i></button>' : '');
  htmlToAppend += '</div>';
  panel.appendHtml(htmlToAppend);
}
