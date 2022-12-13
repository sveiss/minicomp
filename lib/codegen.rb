# frozen_string_literal: true

require "delegate"

require "./lib/visitors"

module Codgen
  class GenerateStackOpsVisitor
    attr_reader :ops, :vars, :fns

    def initialize(fns: nil)
      @ops = StackOps::List.new([])
      @vars = {}
      @fns = fns || {}
    end

    def visit_statement_list(node)
      node.statements.each do |statement|
        statement.accept(self)
      end
    end

    def visit_expr_statement(node)
      node.expr.accept(self)

      @ops << StackOps::PopAsReturnValue.new
    end

    def visit_expr(node)
      node.left.accept(self)
      node.right.accept(self)

      @ops << StackOps::Arithmetic.new(op: node.op)
    end

    def visit_i_val(node)
      @ops << StackOps::PushImmediate.new(val: node.val)
    end

    def visit_var_definition(node)
      stack_slot = @vars.size + 1
      @vars[node.variable] = stack_slot
    end

    def visit_var_assignment(node)
      node.value.accept(self)
      @ops << StackOps::PopAsLocalAssignment.new(stack_slot: @vars[node.variable])
    end

    def visit_var_reference(node)
      @ops << StackOps::PushLocal.new(stack_slot: @vars[node.variable])
    end

    def visit_fn_definition(node)
      visitor = GenerateStackOpsVisitor.new
      node.body.accept(visitor)
      @fns[node.name] = visitor
    end

    def visit_fn_call(node)
      @ops << StackOps::FnCall.new(name: node.name)
    end
  end

  class GenerateAsmOpsVisitor
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
        "; arithmetic",
        "ldr x9,  [sp], #0x10",    # arg 2
        "ldr x10, [sp], #0x10",    # arg 1
        "#{EVAL_OPCODES[node.op]} x9, x10, x9",
        "str x9, [sp, #-0x10]!",
      ]
    end

    def visit_push_immediate(node)
      @ops += [
        "; push_immediate",
        "mov x9, ##{node.val}",  # load immediate
        "str x9, [sp, #-0x10]!", # push to stack
      ]
    end

    def visit_pop_as_return_value(node)
      @ops += [
        "; pop_as_return_value",
        "ldr x0, [sp], #0x10",
      ]
    end

    def visit_pop_as_local_assignment(node)
      # pop stack, write to frame offset
      frame_offset = "#-0x" + (node.stack_slot * 16).to_s(16)
      @ops += [
        "; pop_as_local_assignment",
        "ldr x9, [sp], #0x10",
        "str x9, [fp, #{frame_offset}]",
      ]
    end

    def visit_push_local(node)
      # read frame offset, push to stack
      frame_offset = "#-0x" + (node.stack_slot * 16).to_s(16)
      @ops += [
        "; push_local",
        "ldr x9, [fp, #{frame_offset}]",
        "str x9, [sp, #-0x10]!",
      ]
    end

    def visit_fn_call(node)
      @ops += [
        "; fn_call",
        "bl _#{node.name}",
        "str x0, [sp, #-0x10]!",
      ]
    end
  end

  module StackOps
    class List < SimpleDelegator
      def accept(visitor)
        each { _1.accept(visitor) }
      end
    end

    class Base
      include AcceptsVisitorMixin
    end

    class PushImmediate < Base
      attr_reader :val

      def initialize(val:)
        super()
        @val = val
      end
    end

    class PushLocal < Base
      attr_reader :stack_slot

      def initialize(stack_slot:)
        super()
        @stack_slot = stack_slot
      end
    end

    class PopAsReturnValue < Base; end

    class PopAsLocalAssignment < Base
      attr_reader :stack_slot

      def initialize(stack_slot:)
        super()
        @stack_slot = stack_slot
      end
    end

    class Arithmetic < Base
      attr_reader :op

      def initialize(op:)
        super()
        @op = op
      end
    end

    class FnCall < Base
      attr_reader :name

      def initialize(name:)
        super()
        @name = name
      end
    end
  end
end
