// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

void updateZValues(List<DivElement> zOrderedElements) {
  for (int i = 0; i < zOrderedElements.length; i++) {
    Element element  = zOrderedElements[i];
    element.style.zIndex = '$i';
  }
}

void setOnTop(Element e, List<DivElement> zOrderedElements) {
  zOrderedElements
    ..remove(e)
    ..add(e);
  updateZValues(zOrderedElements);
}

enum Borders {
  widthPlus,
  widthMinus,
  heightPlus,
  heightMinus,
  leftPlus,
  leftMinus,
  topPlus,
  topMinus,
}

/// Attach movement listener to DOM element.
void attachMovementListener(DivElement e, List<DivElement> zOrderedElements) {
  // Make sure that the element's position depends only on left and top.
  // Makes computation easier later.
  e.style.left = '${e.offset.left}px';
  e.style.top = '${e.offset.top}px';
  e.style.bottom = null;
  e.style.right = null;

  // Resize listeners
  Map<Element, List<Borders>> resizeListeners = {
    e.querySelector('.top'): [Borders.heightMinus, Borders.topPlus],
    e.querySelector('.top-left'): [Borders.widthMinus, Borders.heightMinus, Borders.leftPlus, Borders.topPlus],
    e.querySelector('.top-right'): [Borders.widthPlus, Borders.heightMinus, Borders.topPlus],
    e.querySelector('.left'): [Borders.widthMinus, Borders.leftPlus],
    e.querySelector('.right'): [Borders.widthPlus],
    e.querySelector('.bottom'): [Borders.heightPlus],
    e.querySelector('.bottom-left'): [Borders.leftPlus, Borders.widthMinus, Borders.heightPlus],
    e.querySelector('.bottom-right'): [Borders.widthPlus, Borders.heightPlus],
  };

  resizeListeners.forEach((Element resizeElement, List<Borders> borders) {
    resizeElement.onMouseDown.listen((MouseEvent event) {
      event.stopPropagation();
      event.preventDefault();

      setOnTop(e, zOrderedElements);
      if (resizeElement.classes.contains('top') ||
          resizeElement.classes.contains('top-left') ||
          resizeElement.classes.contains('top-right')) {
        removeParentConnections(e);
      }
      int mouseMovementX = 0, mouseMovementY = 0; // For tracking the mouse movement
      int mouseLastPositionX = event.page.x, mouseLastPositionY = event.page.y; // For tracking the mouse movement
      StreamSubscription mouseMove = document.onMouseMove.listen((MouseEvent event) {
        mouseMovementX = event.client.x - mouseLastPositionX; // For tracking the mouse movement
        mouseMovementY = event.client.y - mouseLastPositionY; // For tracking the mouse movement
        mouseLastPositionX = event.client.x; // For tracking the mouse movement
        mouseLastPositionY = event.client.y; // For tracking the mouse movement
        borders.forEach((Borders border) {
          bool fixedHeight = e.attributes.containsKey('fixed-height');
          int newWidth = e.contentEdge.width;
          int newHeight = e.contentEdge.height;
          int newLeft = e.offset.left;
          int newTop = e.offset.top;
          switch(border) {
            case Borders.widthPlus:
              newWidth += mouseMovementX;
              break;
            case Borders.widthMinus:
              newWidth -= mouseMovementX;
              break;
            case Borders.heightPlus:
              newHeight += mouseMovementY;
              break;
            case Borders.heightMinus:
              newHeight -= mouseMovementY;
              break;
            case Borders.leftPlus:
              newLeft += mouseMovementX;
              break;
            case Borders.leftMinus:
              newLeft -= mouseMovementX;
              break;
            case Borders.topPlus:
              newTop += mouseMovementY;
              break;
            case Borders.topMinus:
              newTop -= mouseMovementY;
              break;
          }
          e.style.width = '${newWidth}px';
          e.style.height = fixedHeight ? e.style.height : '${newHeight}px'; // See main.dart:attachTitleBarButtonsListeners()
          e.style.left = '${newLeft}px';
          e.style.top = '${newTop}px';
        });
        prepareSnapToOtherPanels(e);
        if (resizeElement.classes.contains('bottom') ||
            resizeElement.classes.contains('bottom-left') ||
            resizeElement.classes.contains('bottom-right')) {

          moveChildrenConnections(e, 0, mouseMovementY);
        }
        if (e.id == 'output-histogram' && plot != null) {
          plot.relayout(plotLayout);
        }
      });

      StreamSubscription mouseUp;
      mouseUp = document.onMouseUp.listen((MouseEvent event) {
        mouseMove.cancel();
        mouseUp.cancel();
        handleSnapToOtherPanels(e, useHeightInsteadOfTop: true);
      });
    });
  });

  // Move listeners
  e.onMouseDown.listen((MouseEvent event) {
    setOnTop(e, zOrderedElements);
    Element target = event.target;
    // TODO(mariana): Remove contentEditable once the input comes from files, not text in the UI.
    if (containsClassOnParentPath(target, 'CodeMirror-code') ||
        containsClassOnParentPath(target, 'title-bar-buttons') ||
        target is SelectElement ||
        target.contentEditable == "true") {
      return;
    }
    event.stopPropagation();
    event.preventDefault();
    querySelector('body').style.userSelect = 'none';
    removeParentConnections(e);
    int mouseMovementX = 0, mouseMovementY = 0; // For tracking the mouse movement
    int mouseLastPositionX = event.page.x, mouseLastPositionY = event.page.y; // For tracking the mouse movement
    StreamSubscription mouseMove = document.onMouseMove.listen((MouseEvent event) {
      event.stopPropagation();
      event.preventDefault();
      mouseMovementX = event.client.x - mouseLastPositionX; // For tracking the mouse movement
      mouseMovementY = event.client.y - mouseLastPositionY; // For tracking the mouse movement
      mouseLastPositionX = event.client.x; // For tracking the mouse movement
      mouseLastPositionY = event.client.y; // For tracking the mouse movement
      int newLeft = e.offset.left + mouseMovementX;
      int newTop = e.offset.top + mouseMovementY;
      e.style.left = '${newLeft}px';
      e.style.top = '${newTop}px';
      prepareSnapToOtherPanels(e);
      moveChildrenConnections(e, mouseMovementX, mouseMovementY);
    });

    StreamSubscription mouseUp;
    mouseUp = document.onMouseUp.listen((MouseEvent event) {
      mouseMove.cancel();
      mouseUp.cancel();
      handleSnapToOtherPanels(e);
      querySelector('body').style.userSelect = 'text';
    });
  });
}
