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

    stack_ops_visitor = Codgen::GenerateStackOpsVisitor.new
    statement_list.accept(stack_ops_visitor)
    stack_ops = stack_ops_visitor.ops
    vars = stack_ops_visitor.vars

    asm_ops_visitor = Codgen::GenerateAsmOpsVisitor.new
    stack_ops.accept(asm_ops_visitor)
    asm_ops = asm_ops_visitor.ops

    template = ERB.new(<<~EOF, trim_mode: "%-")
      /* GENERATED AT <%= Time.now %> */

      .text
      .p2align 2
      .global _<%= @fn %>
      <% stack_ops_visitor.fns.each_key do |fn| -%>
      .global _<%= fn %>
      <% end %>

    EOF
    out = template.result(binding)

    out += generate_fn_asm(@fn, asm_ops, vars.count)

    stack_ops_visitor.fns.each_pair do |fn, visitor|
      asm_ops_visitor = Codgen::GenerateAsmOpsVisitor.new
      visitor.ops.accept(asm_ops_visitor)
      asm_ops = asm_ops_visitor.ops

      out += generate_fn_asm(fn, asm_ops_visitor.ops, visitor.vars.count)
    end

    out
  rescue Parser::ScannerError => pe
    puts pe.message
    puts source
    puts (" " * (pe.pos - 1)) + "^"
    exit(1) unless ENV["VERBOSE"]
    raise
  end

  def generate_fn_asm(fn, stack_ops, slot_count = 0)
    neg_slot_bytes = "#-0x" + (slot_count * 16).to_s(16)
    slot_bytes = "#0x" + (slot_count * 16).to_s(16)

    template = ERB.new(<<~EOF, trim_mode: "%-")
      _<%= fn %>:
        stp fp, lr, [sp, #-0x10]!
        mov fp, sp
        add sp, sp, #{neg_slot_bytes}
      <% stack_ops.each do |op| -%>
        <%= op %>
      <% end -%>
        add sp, sp, #{slot_bytes}
        ldp fp, lr, [sp], #0x10
        ret

    EOF

    template.result(binding)
  end
end
