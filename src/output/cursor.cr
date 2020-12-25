class Tput
  module Output
    module Cursor
      include Crystallabs::Helpers::Alias_Methods
      include Crystallabs::Helpers::Boolean
      include Macros

      # Positioning

      # CSI Ps E
      # Cursor Next Line Ps Times (default = 1) (CNL).
      # same as CSI Ps B ?
      def cursor_next_line(param=1)
        @position.y += param
        _ncoords
        _write "\x1b[#{param}E"
      end
      alias_previous cnl

      # CSI Ps F
      # Cursor Preceding Line Ps Times (default = 1) (CNL).
      # reuse CSI Ps A ?
      def cursor_preceding_line(param=1)
        @position.y -= param
        _ncoords
        _write "\x1b[#{param}F"
      end
      alias_previous cpl, cursor_previous_line

      # CSI Ps G
      # Cursor Character Absolute  [column] (default = [row,1]) (CHA).
      def cursor_char_absolute(param=nil)
        if !@position.zero_based?
          param = (param||1) - 1
        else
          param ||= 0
        end

        @position.x = param
        _ncoords

        put(s.hpa?(param)) || _write "\x1b[#{param+1}G"
      end
      alias_previous cha, setx

      # CSI Pm d
      # Line Position Absolute  [row] (default = [1,column]) (VPA).
      # NOTE: Can't find in terminfo, no idea why it has multiple params.
      def cursor_line_pos_absolute(param=1)
        @position.y = param
        _ncoords
        put(s.vpa?(param)) || _write "\x1b[#{param}d"
      end
      alias_previous vpa, sety, line_pos_absolute, cursor_line_absolute

      # CSI Ps ; Ps H
      # Cursor Position [row;column] (default = [1,1]) (CUP).
      def cursor_pos(row=nil, col=nil)
        if !@position.zero_based?
          row = (row || 1) - 1
          col = (col || 1) - 1
        else
          row||= 0
          col||= 0
        end

        @position.x = col
        @position.y = row
        _ncoords()

        put(s.cup?(row, col)) || _write "\x1b[#{row+1};#{col+1}H"
      end
      alias_previous cup, pos

      def move(point : Point)
        cursor_pos point.y, point.x
      end
      def move(x=nil, y=nil)
        cursor_pos y, x
      end
      alias_previous cursor_move, cursor_move_to

      # NOTE fix cud and cuu calls
      def omove(x=nil, y=nil)
        if !@position.zero_based?
          x = (x||1) - 1
          y = (y||1) - 1
        else
          x ||= 0
          y ||= 0
        end

        return if @position.x==x && @position.y==y

        if y == @position.y
          if x > @position.x
            cuf x-@position.x
          elsif x < @position.x
            cub @position.x-x
          end
        elsif x == @position.x
          if y > @position.y
            cud y-@position.y
          elsif y < @position.y
            cuu @position.y-y
          end
        else
          unless @position.zero_based?
            x+=1
            y+=1
          end
          cup y, x
        end
      end
      def omove(point : Point)
        omove point.x, point.y
      end

      def rsetx(x)
        # Disabled originally
        #return h_position_relative(x)
        x > 0 ? forward(x) : back(-x)
      end

      def rsety(y)
        # Disabled originally
        #return v_position_relative(y)
        y > 0 ? up(y) : down(-y)
      end

      def rmove(point : Point)
        rsetx point.x
        rsety point.y
      end

      def rmove(x, y)
        rsetx x
        rsety y
      end

      # Only XTerm and iTerm2. If you know of any others, post them.
      def cursor_shape(shape, blink=false)
        blink = to_i blink
        if emulator.iterm2?
          case shape
            # XXX add enum choices
            when "block", :block
              _twrite "\x1b]50;CursorShape=0;BlinkingCursorEnabled=#{blink}\x07"
            when "underline", :underline
              # Disabled originally
              #_twrite "\x1b]50;CursorShape=n;BlinkingCursorEnabled=#{blink}\x07"
            when "line", :line
              _twrite "\x1b]50;CursorShape=1;BlinkingCursorEnabled=#{blink}\x07"
          end
          return true

        elsif name? "xterm", "screen"
          case shape
            when "block", :block
              _twrite "\x1b[#{blink} q"
            when "underline", :underline
              _twrite "\x1b[#{blink+2} q"
            when "line", :line
              _twrite "\x1b[#{blink+4} q"
          end
          return true
        end

        false
      end

      def cursor_color(color : String)
        if name? "xterm", "rxvt", "screen"
          _twrite "\x1b]12#{color}\x07"
          return true
        end
        false
      end

      def reset_cursor
        if name? "xterm", "rxvt", "screen"
          # XXX Disabled originally
          # return reset_colors
          _twrite "\x1b[0 q"
          _twrite "\x1b]112\x07"
          # urxvt doesn't support OSC 112
          _twrite "\x1b]12;white\x07"
          return true
        end
        false
      end
      alias_previous cursor_reset

      # ESC 7 Save Cursor (DECSC).
      def save_cursor(key)
        return lsave_cursor(key) if key
        @saved_x = @position.x || 0
        @saved_y = @position.y || 0
        put(s.sc?) || _write "\x1b7"
      end
      alias_previous sc

      # ESC 8 Restore Cursor (DECRC).
      def restore_cursor(key, hide)
        return lrestore_cursor(key, hide) if (key)
        @position.x = @saved_x || 0
        @position.y = @saved_y || 0
        put(s.rc?) || _write "\x1b8"
      end
      alias_previous rc

      # Enable when aux class/struct is in
      ## Save Cursor Locally
      #def lsave_cursor(key=nil)
      #  key||= "local"
      #  @_saved[key] = CursorState.new x, y, @cursor_hidden
      #end
      ## Restore Cursor Locally
      #def lrestore_cursor(key, hide)
      #  key||= "local"
      #  @_saved[key]?.try do |pos|
      #    #delete @_saved[key]
      #    cup pos.y, pos.x
      #    if hide && (pos.hidden != @cursor_hidden)
      #      pos.hidden ?  hide_cursor : show_cursor
      #    end
      #  end
      #end

      # CSI Ps A
      # Cursor Up Ps Times (default = 1) (CUU).
      def cursor_up(param=nil)
        @position.y -= param || 1
        _ncoords()
        put(s.cuu?(0)) ||
          # XXX enable when solved: undefined method '*' for Slice(UInt8)
          #put(s.cuu1?.try { |v| repeat(v, param) }) ||
            _write "\x1b[#{param}A"
      end
      alias_method cuu, up

# TODO Enable these after cursor_up is fixed to work.
# Requires param, but seems to be going 1 line too much.
#      # CSI Ps B
#      # Cursor Down Ps Times (default = 1) (CUD).
#      def cursor_down(param=1)
#        @position.y += param
#        _ncoords()
#        @tput.try do |tput|
#          unless tput.terminfo.has("parm_down_cursor")
#            return _write(repeat(tput.terminfo.get("cud1"), param))
#          end
#          return put("cud", param)
#        end
#        _write("\x1b[" + (param) + "B")
#      end
#      alias_previous cud, down
#
#      # CSI Ps C
#      # Cursor Forward Ps Times (default = 1) (CUF).
#      def cursor_forward(param=1)
#        @position.x += param
#        _ncoords()
#        @tput.try do |tput|
#          unless tput.terminfo.has("parm_right_cursor")
#            return _write(repeat(tput.terminfo.get("cuf1"), param))
#          end
#          return put("cuf", param)
#        end
#        _write("\x1b[" + (param) + "C")
#      end
#      alias_previous cuf, right, forward
#
#      # CSI Ps D
#      # Cursor Backward Ps Times (default = 1) (CUB).
#      def cursor_backward(param=1)
#        @position.x -= param
#        _ncoords()
#        @tput.try do |tput|
#          unless tput.terminfo.has("parm_left_cursor")
#            return _write(repeat(tput.terminfo.get("cub1"), param))
#          end
#          return put("cub", param)
#        end
#        _write("\x1b[" + (param) + "D")
#      end
#      alias_previous cub, left, back

      def hide_cursor
        @cursor_hidden = true
        put(s.civis?) || reset_mode "?25"
      end
      alias_previous dectcemh, cursor_invisible, vi, civis, cursor_invisible

      def show_cursor
        @cursor_hidden = false
        # Disabled originally:
        # NOTE: In xterm terminfo:
        # cnorm stops blinking cursor
        # cvvis starts blinking cursor
        # return _write("\x1b[?12l\x1b[?25h"); // cursor_normal
        # return _write("\x1b[?12;25h"); // cursor_visible
        put(s.cnorm?) || set_mode "?25"
      end
      alias_previous dectcem, cnorm, cvvis, cursor_visible

      # CSI Ps SP q
      #   Set cursor style (DECSCUSR, VT520).
      #     Ps = 0  -> blinking block.
      #     Ps = 1  -> blinking block (default).
      #     Ps = 2  -> steady block.
      #     Ps = 3  -> blinking underline.
      #     Ps = 4  -> steady underline.
      def set_cursor_style(param)
        case param
          when "blinking block"
            param = 1
          when "block", "steady block"
            param = 2
          when "blinking underline"
            param = 3
          when "underline", "steady underline"
            param = 4
          when "blinking bar"
            param = 5
          when "bar", "steady bar"
            param = 6
        end

        (put(s._Se?) && return) if param == 2
        put(s._Ss?) || _write "\x1b[#{param} q"
      end
      alias_previous decscusr

      # CSI s
      #   Save cursor (ANSI.SYS).
      def save_cursor_a
        @saved_x = @position.x
        @saved_y = @position.y
        put(s.sc?) || _write "\x1b[s"
      end
      alias_previous sc_a

      # CSI u
      #   Restore cursor (ANSI.SYS).
      def restore_cursor_a
        @position.x = @saved_x || 0
        @position.y = @saved_y || 0
        put(s.rc?) || _write "\x1b[u"
      end
      alias_previous rc_a

      # CSI Ps I
      #   Cursor Forward Tabulation Ps tab stops (default = 1) (CHT).
      def cursor_forward_tab(param=1)
        @position.x += 8
        _ncoords
        put(s.tab?(param)) || _write "\x1b[#{param}I"
      end
      alias_previous cht

      # CSI Ps Z  Cursor Backward Tabulation Ps tab stops (default = 1) (CBT).
      def cursor_backward_tab(param=1)
        @position.x -= 8
        _ncoords
        put(s.cbt?(param)) || _write "\x1b[#{param}Z"
      end
      alias_previous cbt

      def restore_reported_cursor
        @_rx.try do |rx|
          @_ry.try do |ry|
            put(s.cup? ry, rx)
            # Disabled originally:
            # put "nel"
          end
        end
      end

      # 141 61 a * HPR -
      # Horizontal Position Relative
      # reuse CSI Ps C ?
      def h_position_relative(param=1)
        put(s.cuf?(param)) && return

        @position.x += param
        _ncoords
        # Disabled originally
        # Does not exist:
        # if (@terminfo) return put "hpr", param
        _write "\x1b[#{param}a"
      end
      alias_previous hpr

      # 145 65 e * VPR - Vertical Position Relative
      # reuse CSI Ps B ?
      def v_position_relative(param=1)
        put(s.cud?(param)) && return

        @position.y += param
        _ncoords

        # Disabled originally
        # Does not exist:
        # if (@terminfo) return put "vpr", param
        _write "\x1b[#{param}e"
      end
      alias_previous vpr

      # CSI Ps ; Ps f
      #   Horizontal and Vertical Position [row;column] (default =
      #   [1,1]) (HVP).
      def hv_position(row=nil, col=nil)
        unless @position.zero_based?
          row = (row || 1) - 1
          col = (col || 1) - 1
        else
          row = row || 0
          col = col || 0
        end
        @position.y = row
        @position.x = col
        _ncoords
        # Disabled originally
        # Does not exist (?):
        # put(s.hvp", row, col);
        put(s.cup?(row, col)) || _write "\x1b[#{row+1};#{col+1}f"
      end
      alias_previous hvp

    end
  end
end