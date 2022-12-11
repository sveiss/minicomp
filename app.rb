# frozen_string_literal: true

class Minicomp
  def initialize(fn)
    @fn = fn
  end

  # expr -> asm source
  def compile(expr)
    template = ERB.new(<<~EOF, trim_mode: "%>")
      /* GENERATED AT <%= Time.now %> */

      .text
      .p2align 2
      .global _<%= @fn %>

      _<%= @fn %>:
        mov x0, #42
        mov x1, #22
        add x0, x0, x1
        ret
    EOF

    template.result(binding)
  end
end
