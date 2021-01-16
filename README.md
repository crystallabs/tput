# Tput.cr

Tput (akin to `tput(1)`) is a complete term/console output library for Crystal.

Is it any good? Yes, there are many, many functions supported. Check the API
docs for a list.

In general, when writing console apps, 4 layers can be identified:

1. Low-level (terminal emulator & terminfo)
1. Mid-level (console interface, memory state, cursor position, etc.)
1. High-level (a framework or toolkit)
1. End-user apps

Tput implements levels (1) and (2).

It is a Crystal-native implementation (except for binding to a C Terminfo library
called `unibilium`). Not even ncurses bindings are used; Tput is a standalone
library that implements all the needed functions itself and provides a much nicer
API.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  tput:
    github: crystallabs/tput.cr
```

2. Run `shards install`

## Overview

If/when initialized with term name, terminfo data will be looked up. If no terminfo
data is found (or one wishes not to use terminfo), Tput's built-in replacements will
be used.

As part of initialization, Tput will also detect terminal features and the
terminal emulator program in use.

There is zero configuration or considerations to have in mind when using
this library. Everything is set up automatically.

For example:

```cr
require "unibilium"
require "tput"

terminfo = Unibilium::Terminfo.from_env
tput = Tput.new terminfo

# Print detected features and environment
p tput.features.to_json
p tput.emulator.to_json

# Set terminal emulator's title, if possible
tput.set_title "Test 123"

# Set cursor to red block:
tput.cursor_shape Tput::CursorShape::Block, blink: false
tput.cursor_color Tput::Color::Red

# Switch to "alternate buffer", print some text
tput.alternate
tput.cursor_pos 10, 20
tput.print "Text at position y=10, x=20"
tput.bell
tput.cr
tput.lf

tput.print "Now displaying ACS chars:"
tput.cr
tput.lf
tput.smacs
tput.print "``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~"
tput.rmacs

tput.cr
tput.lf
tput.print "Press any keys; q to exit."

# Listen for keypresses:
tput.listen do |char, key, sequence|
  # Char is a single typed character, or the first character
  # of a sequence which led to a particular key.

  # Key is a keyboard key, if any. Ordinary characters like
  # 'a' or '1' don't have a representation as Key. Special
  # keys like Enter, F1, Esc etc. do.

  # Sequence is the complete sequence of characters which
  # were consumed as part of identifying the key that was
  # pressed.
  if char == 'q'
    exit
  else
    tput.cr
    tput.lf
    tput.print "Char=#{char.inspect}, Key=#{key.inspect}, Sequence=#{sequence.inspect}"
  end
end

tput.clear
```

Why no ncurses? Ncurses is an implementation sort-of specific to C. When not working
in C, many of the ncurses methods make no sense; also in general ncurses API is arcane.

## API documentation

Run `crystal docs` as usual, then open file `docs/index.html`.

## Testing

Run `crystal spec` as usual.

## Thanks

* All the fine folks on FreeNode IRC channel #crystal-lang and on Crystal's Gitter channel https://gitter.im/crystal-lang/crystal

* Blacksmoke16, Asterite, HertzDevil, Raz, Oprypin, Straight-shoota, Watzon, Naqvis, and others!
