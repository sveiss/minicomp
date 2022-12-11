# frozen_string_literal: true

require "./lib/ast"
require "./lib/codegen"
require "./lib/parse"

class Minicomp
  def initialize(fn)
    @fn = fn
  end

  # expr -> asm source
  def compile(source)
    parser = Parser.new(source)
    expr = parser.parse

    visitor = Codgen::StackOpsVisitor.new
    expr.accept(visitor)

    generate_asm(visitor.ops)
  end

  def generate_asm(stack_ops)
    template = ERB.new(<<~EOF, trim_mode: "%>")
      /* GENERATED AT <%= Time.now %> */

      .text
      .p2align 2
      .global _<%= @fn %>

      _<%= @fn %>:
      <% stack_ops.each do |op| %>
        <%= op %>
      <% end %>
        ldr x0, [sp]
        add sp, sp, #16
        ret
    EOF

    template.result(binding)
  end
end
