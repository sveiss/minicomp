# frozen_string_literal: true

module Codgen
  class StackOpsVisitor
    EVAL_OPCODES = {
      "+" => "add",
      "-" => "sub",
      "*" => "mul",
      "/" => "sdiv",
    }

    attr_reader :ops

    def initialize
      @ops = []
    end

    def visit_expr(node)
      @ops += ["; EVAL: #{node}\n"]

      node.left.accept(self)
      node.right.accept(self)

      @ops += [
        "; left arg",
        "ldr x9, [sp]",
        "add sp, sp, #16",
        "; right arg",
        "ldr x10, [sp]",
        "add sp, sp, #16",
        "; do operation",
        "#{EVAL_OPCODES[node.op]} x9, x10, x9",
        "; write to stack",
        "sub sp, sp, #16",
        "str x9, [sp]",
      ].map { "#{_1}\n" }
    end

    def visit_ival(node)
      @ops += ["; EVAL: #{node}\n"]
      @ops += [
        "sub sp, sp, #16",      # increment sp
        "mov x9, ##{node.val}", # load immediate
        "str x9, [sp]",         # write to stack
      ].map { "#{_1}\n" }
    end
  end
end
