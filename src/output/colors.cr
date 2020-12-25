class Tput
  module Output
    module Colors
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Reset colors
      def reset_colors(param)
        put(s._Cr?(param)) || _twrite "\x1b]112\x07"
        # Disabled originally:
        #_twrite "\x1b]112;#{param}\x07"
      end

      # OSC Ps ; Pt ST
      # OSC Ps ; Pt BEL
      #   Change dynamic colors
      def dynamic_colors(param)
        put(s._Cs?(param)) || _twrite "\x1b]12;#{param}\x07"
      end

    end
  end
end