# frozen_string_literal: true

require "./lib/visitors"

module Codgen
  class ExprToStackOpsVisitor
    attr_reader :ops

    def initialize
      @ops = []
    end

    def visit_expr(node)
      node.left.accept(self)
      node.right.accept(self)

      @ops << StackOps::Arithmetic.new(op: node.op)
    end

    def visit_i_val(node)
      @ops << StackOps::Push.new(val: node.val)
    end
  end

  class StackOpsToAsmVisitor
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

    def visit_arithmetic(node)
      @ops += [
        "ldr x9, [sp]",    # arg 2
        "add sp, sp, #16",
        "ldr x10, [sp]",   # arg 1
        "add sp, sp, #16",
        "#{EVAL_OPCODES[node.op]} x9, x10, x9",
        "sub sp, sp, #16",
        "str x9, [sp]",
      ].map { "#{_1}\n" }
    end

    def visit_push(node)
      @ops += [
        "sub sp, sp, #16",      # increment sp
        "mov x9, ##{node.val}", # load immediate
        "str x9, [sp]",         # write to stack
      ].map { "#{_1}\n" }
    end
  end

  module StackOps
    class Base
      include AcceptsVisitorMixin
    end

    class Push < Base
      attr_reader :val

      def initialize(val:)
        super()
        @val = val
      end
    end

    class Arithmetic < Base
      attr_reader :op

      def initialize(op:)
        super()
        @op = op
      end
    end
  end
end
