# frozen_string_literal: true

class Minicomp
  def initialize(fn)
    @fn = fn
  end

  # expr -> asm source
  def compile(expr)
    stack_ops = expr.eval_ops

    generate_asm(stack_ops)
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

module AST
  class Node; end

  class Expr < Node
    attr_reader :left, :op, :right

    def initialize(left:, op:, right:)
      super()
      @left = left
      @op = op
      @right = right
    end

    def eval_ops
      op = case @op
      when "+"
        "add"
      when "-"
        "sub"
      when "*"
        "mul"
      when "/"
        "sdiv"
      end

      ops = ["; EVAL: Expr\n"]
      ops += left.eval_ops
      ops += right.eval_ops
      ops += [
        "; left arg",
        "ldr x9, [sp]",
        "add sp, sp, #16",
        "; right arg",
        "ldr x10, [sp]",
        "add sp, sp, #16",
        "; do operation",
        "#{op} x9, x9, x10",
        "; write to stack",
        "str x9, [sp]",
      ].map { "#{_1}\n" }

      ops
    end
  end

  class IVal < Node
    attr_reader :val

    def initialize(val:)
      super()
      @val = val.to_i
    end

    def eval_ops
      [
        "; EVAL: Ival",
        "sub sp, sp, #16",    # increment sp
        "mov x9, ##{@val}",   # load immediate
        "str x9, [sp]",       # write to stack
      ].map { "#{_1}\n" }
    end
  end
end
