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

    visitor1 = Codgen::ExprToStackOpsVisitor.new
    expr.accept(visitor1)
    stack_ops = visitor1.ops

    visitor2 = Codgen::StackOpsToAsmVisitor.new
    stack_ops.each { _1.accept(visitor2) }

    asm_ops = visitor2.ops
    generate_asm(asm_ops)
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
