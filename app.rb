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

    statement_list = parser.parse
    stack_ops = generate_stack_ops(statement_list)
    asm_ops = generate_asm_ops(stack_ops)

    generate_asm(asm_ops)
  end

  def generate_stack_ops(statement_list)
    stack_ops = []

    statement_list.each do |statement|
      visitor = Codgen::StatementToStackOpsVisitor.new
      statement.accept(visitor)
      stack_ops += visitor.ops
    end

    stack_ops
  end

  def generate_asm_ops(stack_ops)
    visitor = Codgen::StackOpsToAsmVisitor.new
    stack_ops.each { _1.accept(visitor) }

    visitor.ops
  end

  def generate_asm(stack_ops)
    template = ERB.new(<<~EOF, trim_mode: "%-")
      /* GENERATED AT <%= Time.now %> */

      .text
      .p2align 2
      .global _<%= @fn %>

      _<%= @fn %>:
      <% stack_ops.each do |op| -%>
        <%= op %>
      <% end -%>
        ret
    EOF

    template.result(binding)
  end
end
