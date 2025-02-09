// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library editing.keys;

import 'dart:async';
import 'dart:html';

final _isMac = window.navigator.appVersion.toLowerCase().contains('macintosh');

/**
 * Map key events into commands.
 */
class Keys {
  Map<String, Action> _bindings = {};
  StreamSubscription _sub;
  bool _loggedException = false;

  Keys() {
    _sub = document.onKeyDown.listen(_handleKeyEvent);
  }

  /**
   * Bind a list of keys to an action. The key is a string, with a specific
   * format. Some examples of this format:
   *     `ctrl-space`, `f1`, `macctrl-a`, `shift-left`, `alt-.`
   */
  void bind(List<String> keys, Function onInvoke, String description,
            {bool hidden: false}) {
    keys.forEach((key) =>
    _bindings[key] = new Action(onInvoke, description, hidden: hidden));
  }

  void dispose() {
    _sub.cancel();
  }

  void _handleKeyEvent(KeyboardEvent event) {
    try {
      KeyboardEvent k = event;

      if (!k.altKey &&
      !k.ctrlKey &&
      !k.metaKey &&
      !(event.keyCode >= KeyCode.F1 && event.keyCode <= KeyCode.F12)) {
        return;
      }

      if (_handleKey(printKeyEvent(k))) {
        k.preventDefault();
        k.stopPropagation();
      }
    } catch (e) {
      if (!_loggedException) {
        _loggedException = true;

        // The polymer polyfills make any event handling code unhappy.
        print('${e}');
      }
    }
  }

  bool _handleKey(String key) {
    Action action = _bindings[key];
    if (action != null) {
      Timer.run(action);
      return true;
    }

    return false;
  }

  Map<Action, Set<String>> get inverseBindings {
    return new Map.fromIterable(_bindings.values.toSet(),
    value: (v) => _bindings.keys.where((k) => _bindings[k] == v).toSet());
  }
}

class Action {
  final Function function;
  final String description;
  final bool hidden;

  Action(this.function, this.description, {this.hidden: false});

  call() => function();

  String toString() => description;

  bool operator ==(other) =>
  other is Action && description == other.description;

  int get hashCode => description.hashCode;
}

/**
 * Convert [event] into a string (e.g., `ctrl-s`).
 */
String printKeyEvent(KeyboardEvent event) {
  StringBuffer buf = new StringBuffer();

  // shift ctrl alt
  if (event.shiftKey) buf.write('shift-');
  if (event.ctrlKey) buf.write(isMac() ? 'macctrl-' : 'ctrl-');
  if (event.metaKey) buf.write(isMac() ? 'ctrl-' : 'meta-');
  if (event.altKey) buf.write('alt-');

  if (_codeMap.containsKey(event.keyCode)) {
    buf.write(_codeMap[event.keyCode]);
  } else {
    buf.write(event.keyCode.toString());
  }

  return buf.toString();
}

String makeKeyPresentable(String key) {
  List keyAsList = key.split("-");
  if (isMac()) {
    if (keyAsList.any((s) => s == "meta")) {
      return null;
    }
    keyAsList = keyAsList.map((s) {
      if (_unicodeMac.containsKey(s)) {
        return _unicodeMac[s];
      } else {
        return capitalize(s);
      }
    }).toList();
    return keyAsList.join("&thinsp;");
  } else {
    if (keyAsList.any((s) => s == "macctrl")) {
      return null;
    }
    keyAsList = keyAsList.map((String s) => capitalize(s)).toList();
    return keyAsList.join("+");
  }
}

String capitalize(String s) {
  if (s == null) {
    return null;
  } else if (s.length <= 1) {
    return s.toUpperCase();
  } else {
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
}

bool isMac() => _isMac;

final Map _codeMap = {
  KeyCode.ZERO: '0',
  KeyCode.ONE: '1',
  KeyCode.TWO: '2',
  KeyCode.THREE: '3',
  KeyCode.FOUR: '4',
  KeyCode.FIVE: '5',
  KeyCode.SIX: '6',
  KeyCode.SEVEN: '7',
  KeyCode.EIGHT: '8',
  KeyCode.NINE: '9',

  KeyCode.A: 'a', //
  KeyCode.B: 'b', //
  KeyCode.C: 'c', //
  KeyCode.D: 'd', //
  KeyCode.E: 'e', //
  KeyCode.F: 'f', //
  KeyCode.G: 'g', //
  KeyCode.H: 'h', //
  KeyCode.I: 'i', //
  KeyCode.J: 'j', //
  KeyCode.K: 'k', //
  KeyCode.L: 'l', //
  KeyCode.M: 'm', //
  KeyCode.N: 'n', //
  KeyCode.O: 'o', //
  KeyCode.P: 'p', //
  KeyCode.Q: 'q', //
  KeyCode.R: 'r', //
  KeyCode.S: 's', //
  KeyCode.T: 't', //
  KeyCode.U: 'u', //
  KeyCode.V: 'v', //
  KeyCode.W: 'w', //
  KeyCode.X: 'x', //
  KeyCode.Y: 'y', //
  KeyCode.Z: 'z', //

  KeyCode.F1: 'f1', //
  KeyCode.F2: 'f2', //
  KeyCode.F3: 'f3', //
  KeyCode.F4: 'f4', //
  KeyCode.F5: 'f5', //
  KeyCode.F6: 'f6', //
  KeyCode.F7: 'f7', //
  KeyCode.F8: 'f8', //
  KeyCode.F9: 'f9', //
  KeyCode.F10: 'f10', //
  KeyCode.F11: 'f11', //
  KeyCode.F12: 'f12', //

  KeyCode.PERIOD: '.', //
  KeyCode.COMMA: ',', //
  KeyCode.SLASH: '/', //
  KeyCode.BACKSLASH: '\\', //
  KeyCode.SEMICOLON: ";", //
  KeyCode.DASH: "-", //
  KeyCode.EQUALS: "=", //
  KeyCode.APOSTROPHE: "`", //
  KeyCode.SINGLE_QUOTE: "'", //
  KeyCode.ENTER: 'enter', //
  KeyCode.SPACE: 'space', //
  KeyCode.TAB: "tab", //

  KeyCode.OPEN_SQUARE_BRACKET: '[', //
  KeyCode.CLOSE_SQUARE_BRACKET: ']', //

  KeyCode.LEFT: 'left', //
  KeyCode.RIGHT: 'right', //
  KeyCode.UP: "up", //
  KeyCode.DOWN: "down", //

  KeyCode.BACKSPACE: "backsapce", //
  KeyCode.CAPS_LOCK: "caps_lock", //
  KeyCode.DELETE: "delete", //
  KeyCode.END: "end", //
  KeyCode.ESC: "esc", //
  KeyCode.HOME: "home", //
  KeyCode.INSERT: "insert", //
  KeyCode.NUMLOCK: "numlock", //
  KeyCode.PAGE_DOWN: "page_down", //
  KeyCode.PAGE_UP: "page_up", //
  KeyCode.PAUSE: "pause", //
  KeyCode.PRINT_SCREEN: "print_screen", //

  // Already handled above.
  // If you press ctrl and nothing more, then `printKeyEvent` will print ctrl-.
  KeyCode.CTRL: "", //
  KeyCode.META: "", //
  KeyCode.SHIFT: "", //
};

final Map _unicodeMac = {
  "macctrl": "\u2303",
  "alt": "\u2325",
  "shift": "\u21E7",
  "ctrl": "\u2318",
  "esc": "\u238B",
  "left": "\u2190",
  "enter": "\u21A9",
  "right": "\u2192",
  "caps_lock": "\u21EA",
  "tab": "\u21E5",
  "up": "\u2191",
  "space": "Space"
};
