// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sintr_ui;

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

/// Attach movement listener to DOM element.
void attachResizeAndMovementListenersToElement(DivElement e, List<DivElement> zOrderedElements) {
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
        if (e.id == 'reducer-chart' && plot != null) {
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

attachTitleBarButtonsListenersToElement(DivElement e) {
  ButtonElement closeButton = e.querySelector('.icon--close');
  if (closeButton != null) {
    closeButton.onClick.listen((MouseEvent event) {
      removeParentConnections(e);
      removeChildrenConnections(e);
      connections.remove(e);
      e.remove();
      editors.remove(e);
    });
  }

  ButtonElement foldButton = e.querySelector('.icon--fold-unfold');
  if (foldButton != null) {
    foldButton.onClick.listen((MouseEvent event) {
      if (foldButton.innerHtml.contains('unfold_less')) {
        // First save the previous height & mark the height as unchangeable
        // (until the unfold button is pressed again).
        e.attributes['original_height'] = e.style.height;
        e.attributes['fixed-height'] = "";
        // Set the transition
        // e.style.transition = 'height 5s';
        // e.onTransitionEnd.first.then((_) => e.style.transition = '');
        e.style.height = '16px';
        // Propagate the change to the children neighbours.
        int heightDiff = 16 - pxValueToInt(e.attributes['original_height']);
        propagateFoldToChildren(e, heightDiff);
        // Replace the button
        foldButton.querySelector('i').text = 'unfold_more';
        componentHandler().upgradeElement(foldButton);
      } else if (foldButton.innerHtml.contains('unfold_more')) {
        // Set the transition
        // e.style.transition = 'height 5s';
        // e.onTransitionEnd.first.then((_) => e.style.transition = '');
        e.style.height = e.attributes['original_height'];
        // Propagate the change to the children neighbours.
        int heightDiff = pxValueToInt(e.attributes['original_height']) - 16;
        propagateFoldToChildren(e, heightDiff);
        // Remove the height limitations
        e.attributes.remove('original_height');
        e.attributes.remove('fixed-height');
        //Replace the button
        foldButton.querySelector('i').text = 'unfold_less';
        componentHandler().upgradeElement(foldButton);
      }
    });
  }

  HeadingElement title = e.querySelector('.panel-title');
  if (title != null) {
    title.onDoubleClick.listen((Event event) {
      title.contentEditable = 'true';
      title.focus();

      // Clicking outside the title marks it as not editable again.
      StreamSubscription<MouseEvent> documentOnClickSubscription;
      documentOnClickSubscription = document.onClick.listen((Event event) {
        if (event.target != title) {
          title.contentEditable = 'false';
          documentOnClickSubscription.cancel();
        }
      });

      // Pressing Enter marks it as not editable again.
      StreamSubscription<KeyboardEvent> keyDownSubscription;
      keyDownSubscription = title.onKeyDown.listen((KeyboardEvent event) {
        if (event.keyCode == 13) {
          event.preventDefault();
          title.contentEditable = 'false';
          keyDownSubscription.cancel();
        }
      });
    });
  }
}

int snapMaxDistanceInPx = 20;
prepareSnapToOtherPanels(DivElement panel) {
  for (DivElement other in connections.keys) {
    other.style.border = '';
    panel.style.border = '';
    String borderStyle = '2px solid #ff5252';
    // Only try to snap to panels which intersect this panel vertically
    if ((other.borderEdge.left < panel.borderEdge.left && other.borderEdge.right < panel.borderEdge.left) ||
        (other.borderEdge.left > panel.borderEdge.right && other.borderEdge.right > panel.borderEdge.right)) {
      continue;
    }
    // Only try to snap borders which are not connected yet.
    if (!panel.classes.contains('connected-border--bottom') &&
        !other.classes.contains('connected-border--top') &&
        (other.borderEdge.top - panel.borderEdge.bottom).abs() < snapMaxDistanceInPx) {
      other.style.borderTop = borderStyle;
      panel.style.borderBottom = borderStyle;
      break;
    } else if (!panel.classes.contains('connected-border--top') &&
        !other.classes.contains('connected-border--bottom') &&
        (other.borderEdge.bottom - panel.borderEdge.top).abs() < snapMaxDistanceInPx) {
      other.style.borderBottom = borderStyle;
      panel.style.borderTop = borderStyle;
      break;
    }
  }
}

handleSnapToOtherPanels(DivElement panel, {bool useHeightInsteadOfTop: false}) {
  Neighbours panelNeighbours = connections[panel];
  for (DivElement other in connections.keys) {
    other.style.border = '';
    panel.style.border = '';
    Neighbours otherNeighbours = connections[other];
    // Only try to snap to panels which intersect this panel vertically
    if ((other.borderEdge.left < panel.borderEdge.left && other.borderEdge.right < panel.borderEdge.left) ||
        (other.borderEdge.left > panel.borderEdge.right && other.borderEdge.right > panel.borderEdge.right)) {
      continue;
    }
    // Only try to snap borders which are not connected yet.
    if (!panel.classes.contains('connected-border--bottom') &&
        !other.classes.contains('connected-border--top') &&
        (other.borderEdge.top - panel.borderEdge.bottom).abs() < snapMaxDistanceInPx) {
      other.classes.add('connected-border--top');
      panel.classes.add('connected-border--bottom');
      if (useHeightInsteadOfTop) {
        int newHeight = panel.contentEdge.height + // the previous height plus the change, which is
            // the difference between the new border edge and the previous one.
            (other.offset.top - panel.offset.top) - panel.borderEdge.height;
        panel.style.height = '${newHeight}px';
      } else {
        int newTopOffset = other.offset.top - panel.borderEdge.height;
        moveChildrenConnections(panel, 0, newTopOffset - panel.offset.top);
        panel.style.top = '${newTopOffset}px';
      }
      // Set the relationship here and not above because otherwise it interferes
      // with moveChildrenConnections.
      otherNeighbours.top = panel;
      panelNeighbours.bottom = other;
      break;
    } else if (!panel.classes.contains('connected-border--top') &&
        !other.classes.contains('connected-border--bottom') &&
        (other.borderEdge.bottom - panel.borderEdge.top).abs() < snapMaxDistanceInPx) {
      other.classes.add('connected-border--bottom');
      panel.classes.add('connected-border--top');
      otherNeighbours.bottom = panel;
      panelNeighbours.top = other;
      int newTopOffset = other.offset.top + other.borderEdge.height;
      moveChildrenConnections(panel, 0, newTopOffset - panel.offset.top);
      panel.style.top = '${newTopOffset}px';
    }
  }
}

void layoutPanels(
      DivElement mapperInput,
      DivElement mapperOutputReducerInput,
      DivElement reducerOutput,
      DivElement reducerChart,
      DivElement errorsOutput,
      DivElement nodesStatus,
      DivElement tasksStatus) {
  pageWidth = querySelector('main').client.width;
  pageHeight = querySelector('main').client.height;
  distanceBetweenPanels = 24;
  panelPadding = 16;
  widthUnit = (pageWidth - 4 * distanceBetweenPanels) ~/ 7;
  heightUnit = (pageHeight - 2 * distanceBetweenPanels) ~/ 3;

  mapperInput.style
    ..top = '${distanceBetweenPanels}px'
    ..left = '${distanceBetweenPanels}px'
    ..width = '${widthUnit * 2 - panelPadding * 2}px'
    ..height = '${heightUnit - panelPadding * 2}px';

  mapperOutputReducerInput.style
    ..top = '${distanceBetweenPanels + heightUnit}px'
    ..left = '${distanceBetweenPanels}px'
    ..width = '${widthUnit * 2 - panelPadding * 2}px'
    ..height = '${heightUnit - panelPadding * 2}px';
  reducerOutput.style
    ..top = '${distanceBetweenPanels + 2 * heightUnit}px'
    ..left = '${distanceBetweenPanels}px'
    ..width = '${widthUnit * 2 - panelPadding * 2}px'
    ..height = '${heightUnit - panelPadding * 2}px';

  nodesStatus.style
    ..top = '${distanceBetweenPanels}px'
    ..right = '${distanceBetweenPanels}px'
    ..width = '${widthUnit * 2 - panelPadding * 2}px'
    ..height = '${heightUnit ~/ 2 - panelPadding * 2}px';

  tasksStatus.style
    ..top = '${distanceBetweenPanels + heightUnit ~/ 2}px'
    ..right = '${distanceBetweenPanels}px'
    ..width = '${widthUnit * 2 - panelPadding * 2}px'
    ..height = '${heightUnit ~/ 2 - panelPadding * 2}px';

  errorsOutput.style
    ..top = '${distanceBetweenPanels + heightUnit}px'
    ..right = '${distanceBetweenPanels}px'
    ..width = '${widthUnit * 2 - panelPadding * 2}px'
    ..height = '${heightUnit - panelPadding * 2}px';

  reducerChart.style
    ..top = '${distanceBetweenPanels + 2 * heightUnit}px'
    ..right = '${distanceBetweenPanels}px'
    ..width = '${widthUnit * 2 - panelPadding * 2}px'
    ..height = '${heightUnit - panelPadding * 2}px';
}
